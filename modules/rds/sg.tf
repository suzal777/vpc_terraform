# Security Group
resource "aws_security_group" "rds_sg" {
  name_prefix = "${var.name_prefix}-sg-"
  description = "Allow inbound traffic to RDS from within VPC"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.port
    to_port         = var.port
    protocol        = "tcp"
    cidr_blocks     = [data.aws_vpc.selected.cidr_block]
    description     = "Allow VPC traffic to RDS port"
  }

#     ingress {
#     from_port       = var.port
#     to_port         = var.port
#     protocol        = "tcp"
#     security_groups = [var.allowed_sg]
#     description     = "Allow VPC traffic to RDS port"
#   }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-sg"
  })
}