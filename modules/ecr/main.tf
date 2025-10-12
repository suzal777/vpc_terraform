# Create an ECR repository for each service
resource "aws_ecr_repository" "service_repo" {
  for_each     = { for s in var.services : s.name => s }
  name         = "${var.name}-${each.key}-repo"
  force_delete = true
  tags         = var.tags
}

# Optional: Build & push images to ECR (local-exec)
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

resource "aws_ecr_lifecycle_policy" "service_lifecycle" {
  for_each   = aws_ecr_repository.service_repo
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images older than 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep only last 10 tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["latest"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}