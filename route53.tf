resource "aws_route53_zone" "private" {
  name = "example.com"
  vpc {
    vpc_id = aws_vpc.web-app-vpc.id
  }
}

resource "aws_route53_record" "test" {
  zone_id = aws_route53_zone.private.id
  name    = "test.example.com"
  type    = "A"
  alias {
    name                   = aws_lb.web-app.dns_name
    zone_id                = aws_lb.web-app.zone_id
    evaluate_target_health = true
  }
}
