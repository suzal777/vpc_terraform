output "ecs_sg_id" {
  description = "Security group ID for ECS tasks"
  value       = aws_security_group.ecs_sg.id
}

output "alb_sg_id" {
  description = "Security group ID for Application Load Balancer"
  value       = aws_security_group.alb_sg.id
}
