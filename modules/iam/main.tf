variable "name" {
  description = "Base name for IAM resources"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "create_nat_instance" {
  description = "Whether to create IAM resources for NAT instance"
  type        = bool
  default     = false
}

# IAM Role for NAT Instance with SSM
resource "aws_iam_role" "nat_instance_role" {
  count = var.create_nat_instance ? 1 : 0

  name = "${var.name}nat-instance-role"

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
  count = var.create_nat_instance ? 1 : 0

  role       = aws_iam_role.nat_instance_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile to attach to EC2 NAT instance
resource "aws_iam_instance_profile" "nat_instance_profile" {
  count = var.create_nat_instance ? 1 : 0

  name = "${var.name}-nat-instance-profile"
  role = aws_iam_role.nat_instance_role[0].name
}

# Outputs (return null if not created)
output "role_name" {
  value       = try(aws_iam_role.nat_instance_role[0].name, null)
  description = "IAM role name for NAT instance"
}

output "instance_profile" {
  value       = try(aws_iam_instance_profile.nat_instance_profile[0].name, null)
  description = "IAM instance profile name for NAT instance"
}
