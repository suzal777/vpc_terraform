variable "ami_id" {
  type        = string
  description = "AMI ID for the instance"
}

variable "instance_type" {
  type        = string
  description = "Instance type"
  default     = "t3.micro"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID to launch the instance into"
}

variable "associate_public_ip_address" {
  type        = bool
  description = "Whether to assign a public IP"
  default     = false
}

variable "key_name" {
  type        = string
  description = "Name of the SSH keypair"
  default     = null
}

variable "iam_instance_profile" {
  type        = string
  description = "IAM instance profile name or ARN to associate"
  default     = null
}

variable "security_group_ids" {
  type        = list(string)
  description = "List of security group IDs"
  default     = []
}

variable "user_data" {
  type        = string
  description = "User data script"
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply"
  default     = {}
}

variable "name" {
  type        = string
  description = "Name tag for the instance"
}

variable "source_dest_check" {
  type        = bool
  description = "Controls whether source/destination checking is enabled on the instance"
  default     = true
}

variable "vpc_id" {
  type = string
}

variable "sg_ingress" {
  description = "List of ingress rules for the security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    { from_port = 1194, to_port = 1194, protocol = "udp", cidr_blocks = ["0.0.0.0/0"] },
    { from_port = 22, to_port = 22, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"]}

  ]
}