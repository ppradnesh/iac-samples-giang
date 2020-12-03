resource "aws_lb_target_group" "aws_lb_target_group" {
  name_prefix          = substr(var.project_name, 0, 6)
  port                 = var.container_port
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.isg_vpn.id
  target_type          = "ip"
  deregistration_delay = 20
  tags                 = local.default_tags
  depends_on           = [aws_lb.aws_lb]

  health_check {
    timeout  = 5
    interval = 10
    path     = var.health_endpoint
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.aws_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.aws_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.deere_external.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.aws_lb_target_group.arn
  }
}

resource "aws_lb" "aws_lb" {
  name               = var.project_name
  internal           = false
  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.public_subnets.ids
  tags               = local.default_tags

  security_groups = [
    data.aws_security_group.deere_open_http.id,
    data.aws_security_group.deere_open_https.id,
  ]
}
