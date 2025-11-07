# ECS Cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = coalesce(var.cluster_name, "${var.name}-ecs-cluster")

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

# Cloudwatch log group

resource "aws_cloudwatch_log_group" "ecs_logs" {
  for_each          = { for s in var.services : s.name => s }
  name              = "/${var.name}-ecs/${each.key}"
  retention_in_days = 7
  tags              = var.tags
}

# ECS Task Definitions
resource "aws_ecs_task_definition" "task_definition" {
  for_each                 = { for s in var.services : s.name => s }
  family                   = "${var.name}-${each.key}-task"
  network_mode             = var.launch_type == "FARGATE" ? "awsvpc" : "bridge"
  requires_compatibilities = var.launch_type == "FARGATE" ? ["FARGATE"] : ["EC2"]
  cpu                      = each.value.task_cpu
  memory                   = each.value.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_exec.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = each.key
      image     = "${var.repository_urls[each.key]}:latest"
      cpu       = each.value.task_cpu
      memory    = each.value.task_memory
      essential = true
      portMappings = [
        {
          containerPort = each.value.container_port
          hostPort      = var.launch_type == "FARGATE" ? each.value.container_port : each.value.host_port
          name          = "http"
        }
      ]

       logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_logs[each.key].name
          awslogs-region        = var.region
          awslogs-stream-prefix = each.key
        }
      }

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

# ECS-optimized AMI
data "aws_ami" "ecs" {
  count       = var.launch_type == "EC2" ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

resource "aws_launch_template" "ecs" {
  count = var.launch_type == "EC2" ? 1 : 0

  name_prefix   = "ecs-"
  image_id      = data.aws_ami.ecs[0].id
  instance_type = var.instance_type
  key_name      = "Sujals-key"

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ecs_sg.id]
  }

  user_data = base64encode(<<EOF
#!/bin/bash
echo "ECS_CLUSTER=${aws_ecs_cluster.ecs_cluster.name}" >> /etc/ecs/ecs.config
echo 'ECS_AVAILABLE_LOGGING_DRIVERS=["awslogs","json-file"]' >> /etc/ecs/ecs.config
EOF
  )
}

resource "aws_autoscaling_group" "ecs" {
  name = "${var.name}-ecs-asg"
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

  name = "${var.name}-ecs-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs[0].arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 80
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 2
    }
  }
  tags = var.tags
}

# ECS Cluster Capacity Providers
resource "aws_ecs_cluster_capacity_providers" "capacity_providers" {

  cluster_name = aws_ecs_cluster.ecs_cluster.name

  # Choose capacity providers dynamically based on launch type and variable
  capacity_providers = var.launch_type == "EC2" ? [aws_ecs_capacity_provider.asg[0].name] : (var.enable_fargate_spot ? ["FARGATE", "FARGATE_SPOT"] : ["FARGATE"])

  depends_on = [aws_ecs_capacity_provider.asg]
}


# ECS Services (EC2 or Fargate) with Service Connect
resource "aws_ecs_service" "ecs_service" {
  for_each        = { for s in var.services : s.name => s }
  name            = "${var.name}-${each.key}-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.task_definition[each.key].arn
  desired_count   = each.value.desired_count
  launch_type     = var.launch_type == "FARGATE" ? "FARGATE" : null
  enable_execute_command = true

  dynamic "network_configuration" {
    for_each = var.launch_type == "FARGATE" ? [1] : []
    content {
      subnets         = var.private_subnet_ids
      security_groups = [aws_security_group.ecs_sg.id]
      assign_public_ip = false
    }
  }

  dynamic "load_balancer" {
  for_each = each.value.enable_load_balancer ? [1] : []
  content {
    target_group_arn = aws_lb_target_group.tg[each.key].arn
    container_name   = each.key
    container_port   = each.value.container_port
  }
}

  dynamic "service_connect_configuration" {
  for_each = each.value.enable_service_connect ? [1] : []
  content {
    enabled   = true
    namespace = aws_service_discovery_private_dns_namespace.service_connect_namespace[0].arn

    dynamic "service" {
      for_each = can(regex("backend", each.value.name)) ? [1] : []           # Hardcoded alert, checks if the service needs client and server
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
    aws_lb.main,
    aws_ecs_service.ecs_service["backend"]           # Hardcoded alert, checks if the service needs client and server
  ]

  tags       = var.tags
}

# Working till now