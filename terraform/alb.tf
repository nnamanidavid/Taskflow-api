resource "aws_lb" "app_alb" {
  name               = "taskflow-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets = aws_subnet.pub_subnet[*].id

  tags = {
    Name = "taskflow-alb"
  }
}

resource "aws_lb_target_group" "app_tg" {
  name        = "taskflow-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.taskflow_vpc.id
  target_type = "ip"

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

resource "aws_security_group_rule" "alb_egress_to_grafana" {
  type                     = "egress"
  description              = "To Grafana"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.grafana_sg.id
  security_group_id        = aws_security_group.alb_sg.id
}