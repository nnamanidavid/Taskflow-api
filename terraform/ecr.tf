resource "aws_ecr_repository" "taskflow_repo" {
  name                 = "taskflow-api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}