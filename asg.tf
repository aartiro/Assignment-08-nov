resource "aws_autoscaling_group" "ec2-cluster" {
  count                = length(var.private_subnet_cidrs)
  name                 = "${var.ec2_instance_name}_auto_scaling_group"
  min_size             = var.autoscale_min
  max_size             = var.autoscale_max
  desired_capacity     = var.autoscale_desired
  health_check_type    = "EC2"
  launch_configuration = aws_launch_configuration.ec2.name
  target_group_arns    = [aws_alb_target_group.default-target-group.arn]
  vpc_zone_identifier  = element(aws_subnet.private_subnets[*].id, count.index)
}