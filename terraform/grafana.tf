resource "aws_cloudwatch_log_group" "grafana" {
  name              = "/ecs/taskflow-grafana"
  retention_in_days = 7
}

resource "aws_service_discovery_service" "grafana" {
  name = "grafana"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.taskflow.id
    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
}

resource "aws_ecs_task_definition" "grafana" {
  family                   = "taskflow-grafana"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "grafana"
      image     = "grafana/grafana:latest"   # public image, no custom build needed
      essential = true
      portMappings = [{ containerPort = 3000, hostPort = 3000 }]
      environment = [
        { name = "GF_SECURITY_ADMIN_PASSWORD", value = "changeme123" } # swap for Secrets Manager later
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/taskflow-grafana"
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
      environment = [
  { name = "GF_SECURITY_ADMIN_PASSWORD", value = "changeme123" },
  { name = "GF_SERVER_ROOT_URL", value = "http://taskflow-alb-48536355.us-east-1.elb.amazonaws.com/grafana" },
  { name = "GF_SERVER_SERVE_FROM_SUB_PATH", value = "true" }
   ]
    }
  ])
  

  depends_on = [aws_cloudwatch_log_group.grafana]
}

resource "aws_lb_target_group" "grafana_tg" {
  name        = "taskflow-grafana-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.taskflow_vpc.id
  target_type = "ip"

  health_check {
    path                = "/api/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener_rule" "grafana_path" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana_tg.arn
  }

  condition {
    path_pattern {
      values = ["/grafana*"]
    }
  }
}

resource "aws_ecs_service" "grafana" {
  name            = "grafana"
  cluster         = aws_ecs_cluster.taskflow_cluster.id
  task_definition = aws_ecs_task_definition.grafana.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets         = aws_subnet.priv_subnet[*].id
    security_groups = [aws_security_group.grafana_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.grafana_tg.arn
    container_name   = "grafana"
    container_port   = 3000
  }

  service_registries {
    registry_arn = aws_service_discovery_service.grafana.arn
  }
}