output "alb_dns" {
  value = aws_lb.web-app.dns_name
}
output "alb_zone" {
  value = aws_lb.web-app.zone_id
}