# Shared Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.name}-alb"
  load_balancer_type = "application"
  subnets            = var.subnet_ids
  security_groups    = var.sg_ids.alb_sg
  tags               = var.tags
}

# Target groups for each service that needs a load balancer
resource "aws_lb_target_group" "tg" {
  for_each = { for s in var.services : s.name => s if s.enable_load_balancer }

  name     = "${each.key}-tg"
  port     = each.value.container_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = var.launch_type == "FARGATE" ? "ip" : "instance"

  health_check {
    path = each.value.health_check_path
  }

  tags = var.tags
}

# One shared HTTP listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404 Not Found"
      status_code  = "404"
    }
  }
}

# Path-based routing rules per service
resource "aws_lb_listener_rule" "path_based" {
  for_each = { for s in var.services : s.name => s if s.enable_load_balancer }

  listener_arn = aws_lb_listener.http.arn
  priority     = 100 - index(var.services[*].name, each.key)

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg[each.key].arn
  }

  condition {
    path_pattern {
      values = [each.value.path_pattern]
    }
  }
}

# Working till now