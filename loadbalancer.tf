data "aws_acm_certificate" "domain" {
  domain   = var.domain
  statuses = ["ISSUED"]
}

resource "aws_lb" "lb" {
  name               = "reshuffle-${var.system}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sglb.id]
  subnets            = aws_subnet.subnet.*.id
  tags               = local.defaultTags
}

resource "aws_lb_target_group" "lbTargetGroup" {
  name        = "reshuffle-${var.system}-lbtg"
  port        = var.containerPort
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  lifecycle {
    create_before_destroy = true
  }

  health_check {
    path                = "/--health"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    interval            = 5
    timeout             = 3
  }
}

resource "aws_lb_listener" "lbListener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = data.aws_acm_certificate.domain.arn

  default_action {
    target_group_arn = aws_lb_target_group.lbTargetGroup.arn
    type             = "forward"
  }
}

resource "aws_route53_record" "alias" {
  count = var.zoneid == "" ? 0 : 1

  zone_id = var.zoneid
  name    = "${var.system}.${var.domain}"
  type    = "A"

  alias {
    name                   = aws_lb.lb.dns_name
    zone_id                = aws_lb.lb.zone_id
    evaluate_target_health = true
  }
}
