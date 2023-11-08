# Load Balancer
resource "aws_lb" "web-app" {
  count              = length(var.public_subnet_cidrs)
  name               = "${var.ec2_instance_name}-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.load-balancer.id]
  subnets            = aws_subnet.public_subnets[0].id
}

# Target group
resource "aws_alb_target_group" "default-target-group" {
  name     = "${var.ec2_instance_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.web-app-vpc.id

  health_check {
    path                = var.health_check_path
    port                = "traffic-port"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 2
    interval            = 60
    matcher             = "200"
  }
}

resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  autoscaling_group_name = aws_autoscaling_group.ec2-cluster[*].id
  lb_target_group_arn    = aws_alb_target_group.default-target-group.arn
}

resource "aws_alb_listener" "ec2-alb-http-listener" {
  load_balancer_arn = aws_lb.web-app.id
  port              = "80"
  protocol          = "HTTP"
  depends_on        = [aws_alb_target_group.default-target-group]
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  //certificate_arn   = "your-certificate-arn" # ARN of your self-signed certificate

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.default-target-group.arn
  }
}

resource "aws_alb_listener_certificate" "ssl_certificate" {
  listener_arn    = aws_alb_listener.ec2-alb-http-listener.arn
  certificate_arn = data.aws_acm_certificate.certificate.arn
}