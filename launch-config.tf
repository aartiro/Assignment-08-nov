resource "aws_iam_policy" "session-manager" {
  description = "session-manager"
  name        = "session-manager"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "ec2:*",
        "Effect" : "Allow",
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : "elasticloadbalancing:*",
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : "cloudwatch:*",
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : "autoscaling:*",
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : "iam:CreateServiceLinkedRole",
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : {
            "iam:AWSServiceName" : [
              "autoscaling.amazonaws.com",
              "ec2scheduled.amazonaws.com",
              "elasticloadbalancing.amazonaws.com",
              "spot.amazonaws.com",
              "spotfleet.amazonaws.com",
              "transitgateway.amazonaws.com"
            ]
          }
        }
      }
    ]
  })
}

resource "aws_iam_role" "session-manager" {
  assume_role_policy = data.aws_iam_policy_document.ec2.json
  name               = "session-manager"
  tags = {
    Name = "session-manager"
  }
}

resource "aws_iam_instance_profile" "session-manager" {
  name = "session-manager"
  role = aws_iam_role.session-manager.name
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.web-app.key_name
  iam_instance_profile        = aws_iam_instance_profile.session-manager.id
  associate_public_ip_address = true
  security_groups             = [aws_security_group.ec2.id]
  subnet_id                   = aws_subnet.public_subnets[0].id
  tags = {
    Name = "Bastion"
  }
}

resource "aws_launch_configuration" "ec2" {
  name                        = "${var.ec2_instance_name}-instances-lc"
  image_id                    = data.aws_ami.amazon_linux_2.id
  instance_type               = var.instance_type
  security_groups             = [aws_security_group.ec2.id]
  key_name                    = aws_key_pair.web-app.key_name
  iam_instance_profile        = aws_iam_instance_profile.session-manager.id
  associate_public_ip_address = false
  user_data                   = <<-EOL
  #!/bin/bash -xe

  sudo yum update -y
  sudo yum -y install docker
  sudo service docker start
  sudo usermod -a -G docker ec2-user
  sudo chmod 666 /var/run/docker.sock
  docker pull nginx
  docker tag nginx my-nginx
  docker run --rm --name nginx-server -d -p 8081:8082 -t my-nginx
  EOL
  depends_on                  = [aws_nat_gateway.web-app-ngw]
  # root volume to store the application / service
  root_block_device {
    volume_type = "gp2"
    volume_size = 20
  }
# secondary volume meant to store any log data bound from / var/log
  ebs_block_device {
    device_name = "/dev/sdf" 
    volume_type = "gp2"
    volume_size = 50
  }

  lifecycle {
    create_before_destroy = true
  }
}