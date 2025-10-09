# ECR Repos + Push
resource "aws_ecr_repository" "service_repo" {
  for_each     = { for s in var.services : s.name => s }
  name         = "${each.key}-repo"
  force_delete = true
  tags         = var.tags
}

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