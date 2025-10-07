# ECS Cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = coalesce(var.cluster_name, var.name)

  configuration {
      execute_command_configuration {
        logging = "DEFAULT"
      }
    }

  tags = var.tags
}

# Service Connect Namespace (shared, reuse if exists)
resource "aws_service_discovery_private_dns_namespace" "service_connect_namespace" {
  count       = anytrue([for s in var.services : s.enable_service_connect]) ? 1 : 0
  name        = var.service_connect_namespace_name
  description = "Service Connect namespace"
  vpc         = var.vpc_id
}

# ECR Repos + Push
resource "aws_ecr_repository" "service_repo" {
  for_each     = { for s in var.services : s.name => s }
  name         = "${each.key}-repo"
  force_delete = true
  tags         = var.tags
}

resource "null_resource" "push_service_images" {
  for_each = { for s in var.services : s.name => s }
  depends_on = [aws_ecr_repository.service_repo]

  provisioner "local-exec" {
    command = <<EOT
aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${aws_ecr_repository.service_repo[each.key].repository_url}
docker pull ${each.value.task_image}
docker tag ${each.value.task_image} ${aws_ecr_repository.service_repo[each.key].repository_url}:latest
docker push ${aws_ecr_repository.service_repo[each.key].repository_url}:latest
EOT
  }
}

# IAM Roles for Tasks (shared)
resource "aws_iam_role" "ecs_task_exec" {
  name               = "ecs-task-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_exec.json
}

data "aws_iam_policy_document" "ecs_task_exec" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_exec" {
  role       = aws_iam_role.ecs_task_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_task_exec_ssm_managed" {
  role       = aws_iam_role.ecs_task_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach additional ECS Exec permissions
resource "aws_iam_role_policy" "ecs_task_exec_ssm" {
  name = "ecs-task-exec-ssm"
  role = aws_iam_role.ecs_task_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "ecs_task" {
  name               = "ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task.json
}

data "aws_iam_policy_document" "ecs_task" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# ECS Task Definitions
resource "aws_ecs_task_definition" "task_definition" {
  for_each                 = { for s in var.services : s.name => s }
  family                   = "${each.key}-task"
  network_mode             = var.launch_type == "FARGATE" ? "awsvpc" : "bridge"
  requires_compatibilities = var.launch_type == "FARGATE" ? ["FARGATE"] : ["EC2"]
  cpu                      = each.value.task_cpu
  memory                   = each.value.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_exec.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = each.key
      image     = "${aws_ecr_repository.service_repo[each.key].repository_url}:latest"
      cpu       = each.value.task_cpu
      memory    = each.value.task_memory
      essential = true
      portMappings = [
        {
          containerPort = each.value.container_port
          hostPort      = each.value.host_port
          name          = "http"
        }
      ]

      # environment = [
      #   for key, value in lookup(each.value, "environment", {}) :
      #   {
      #     name  = key
      #     value = value
      #   }
      # ]

    }
  ])
  tags = var.tags
}

# EC2 Launch Template + ASG + Capacity Provider (shared)
resource "aws_launch_template" "ecs" {
  count = var.launch_type == "EC2" ? 1 : 0

  name_prefix   = "ecs-"
  image_id      = var.image_id
  instance_type = var.instance_type
  key_name      = "sujal-key"

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = var.sg_ids
  }

  user_data = base64encode(<<EOF
#!/bin/bash
echo "ECS_CLUSTER=${aws_ecs_cluster.ecs_cluster.name}" >> /etc/ecs/ecs.config
echo 'ECS_AVAILABLE_LOGGING_DRIVERS=["awslogs","json-file"]' >> /etc/ecs/ecs.config
EOF
  )
}

resource "aws_iam_role" "ecs_instance" {
  name               = "ecs-instance-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_instance.json
}

data "aws_iam_policy_document" "ecs_instance" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_instance" {
  role       = aws_iam_role.ecs_instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs" {
  name = "ecs-instance-profile"
  role = aws_iam_role.ecs_instance.name
}

resource "aws_autoscaling_group" "ecs" {
  name = "${var.name}-asg"
  count               = var.launch_type == "EC2" ? 1 : 0
  desired_capacity    = var.asg_desired_capacity
  max_size            = var.asg_max_size
  min_size            = var.asg_min_size
  vpc_zone_identifier = var.private_subnet_ids

  launch_template {
    id      = aws_launch_template.ecs[0].id
    version = "$Latest"
  }

  health_check_type = "EC2"
  force_delete      = true
}

resource "aws_ecs_capacity_provider" "asg" {
  count = var.launch_type == "EC2" ? 1 : 0

  name = "${var.name}-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs[0].arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 80
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 10
    }
  }
  tags = var.tags
}

resource "aws_ecs_cluster_capacity_providers" "capacity_providers" {
  count = var.launch_type == "EC2" ? 1 : 0

  cluster_name       = aws_ecs_cluster.ecs_cluster.name
  capacity_providers = [aws_ecs_capacity_provider.asg[0].name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.asg[0].name
    weight            = 1
  }

  depends_on = [aws_ecs_capacity_provider.asg]
}

# ECS Services (EC2 or Fargate) with Service Connect
resource "aws_ecs_service" "ecs_service" {
  for_each        = { for s in var.services : s.name => s }
  name            = "${each.key}-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.task_definition[each.key].arn
  desired_count   = each.value.desired_count
  launch_type     = var.launch_type == "FARGATE" ? "FARGATE" : null
  enable_execute_command = true

  dynamic "network_configuration" {
    for_each = var.launch_type == "FARGATE" ? [1] : []
    content {
      subnets         = var.private_subnet_ids
      security_groups = var.sg_ids
      assign_public_ip = true
    }
  }

  dynamic "load_balancer" {
  for_each = each.value.enable_load_balancer ? [1] : []
  content {
    target_group_arn = aws_lb_target_group.tg[each.key].arn
    container_name   = each.key
    container_port   = 80
  }
}

  dynamic "service_connect_configuration" {
  for_each = each.value.enable_service_connect ? [1] : []
  content {
    enabled   = true
    namespace = aws_service_discovery_private_dns_namespace.service_connect_namespace[0].arn

    dynamic "service" {
      for_each = can(regex("backend", each.value.name)) ? [1] : []
      content {
        discovery_name = "${each.key}-svc"
        port_name      = "http"
        client_alias {
          dns_name = "${each.key}-alias"
          port     = 8080
        }
      }
    }
  }
}

  depends_on = [
    null_resource.push_service_images,
    aws_lb.main,                               # Ensure ALB is ready
  ]

  tags       = var.tags
}

# Working till now