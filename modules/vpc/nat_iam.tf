# IAM Role for NAT Instance with SSM
resource "aws_iam_role" "nat_instance_role" {
  for_each = var.create_nat_instance ? { "main" = true } : {}

  name = "${var.name}-nat-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

# Attach AmazonSSMManagedInstanceCore policy
resource "aws_iam_role_policy_attachment" "ssm" {
  for_each = var.create_nat_instance ? { "main" = true } : {}

  role       = aws_iam_role.nat_instance_role["main"].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile to attach to EC2 NAT instance
resource "aws_iam_instance_profile" "nat_instance_profile" {
  for_each = var.create_nat_instance ? { "main" = true } : {}

  name = "${var.name}-nat-instance-profile"
  role = aws_iam_role.nat_instance_role["main"].name
}