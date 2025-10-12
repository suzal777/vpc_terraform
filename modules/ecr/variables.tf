variable "name" {
  description = "Base name for ECR repositories"
  type        = string
}

variable "region" {
  description = "AWS region for ECR"
  type        = string
}

variable "tags" {
  description = "Tags to apply to ECR resources"
  type        = map(string)
}

variable "services" {
  description = "List of services with image details"
  type = list(object({
    name       = string
    task_image = string
  }))
}
