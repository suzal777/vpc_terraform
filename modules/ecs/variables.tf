variable "name" {
  type        = string
  description = "Base name for ECS resources"
}

variable "region" {
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  type = string
}

variable "cluster_name" {
  type        = string
  default     = null
}

variable "launch_type" {
  type        = string
  description = "ECS launch type: FARGATE or EC2"
  default     = "FARGATE"
}

variable "services" {
  type = list(object({
    name                   = string
    task_image             = string
    task_cpu               = number
    task_memory            = number
    desired_count          = number
    enable_service_connect = bool
    enable_load_balancer   = bool
    container_port         = number
    host_port              = number
    environment            = optional(map(string))
    path_pattern           = optional(string)
    health_check_path      = string
  }))
  description = "List of ECS services to deploy"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnets for ECS tasks"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private Subnets for ECS tasks"
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "asg_min_size" {
  type    = number
  default = 1
}

variable "asg_max_size" {
  type    = number
  default = 1
}

variable "asg_desired_capacity" {
  type    = number
  default = 1
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "vpc_id" {
  type = string
  description = "VPC ID for ECS cluster and Service Connect"
}

variable "service_connect_namespace_name" {
  type    = string
  default = "service-connect.local"
}

variable "enable_fargate_spot" {
  type   = string
  default = "false"
}

variable "repository_urls" {
  description = "Map of ECR repository URLs for each service"
  type        = map(string)
}