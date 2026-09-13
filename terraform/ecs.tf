resource "aws_ecs_cluster" "taskflow_cluster" {
  name = "taskflow-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "taskflow_app" {
  family                   = "taskflow-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "taskflow-api"
      image     = "${aws_ecr_repository.taskflow_repo.repository_url}:latest"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/taskflow-api"
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  volume {
    name      = "service-storage"
  
  }
  
  depends_on = [aws_cloudwatch_log_group.taskflow_api]

}

resource "aws_ecs_service" "taskflow_service" {
  name            = "taskflow"
  cluster         = aws_ecs_cluster.taskflow_cluster.id
  task_definition = aws_ecs_task_definition.taskflow_app.arn
  launch_type     = "FARGATE"
  desired_count   = 2
  depends_on      = [aws_iam_role_policy_attachment.ecs_exec_ssm]

  network_configuration {
    subnets         = aws_subnet.priv_subnet[*].id
    security_groups = [aws_security_group.app_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "taskflow-api"
    container_port   = 3000
  }
}

resource "aws_cloudwatch_log_group" "taskflow_api" {
  name              = "/ecs/taskflow-api"
  retention_in_days = 7
}

