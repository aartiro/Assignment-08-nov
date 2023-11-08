The Assignment:
Using Terraform latest version, build a module meant to deploy a web application that supports the following design:

1. It must include a VPC which enables future growth / scale - 
2. It must include both a public and private subnet – where the private subnet is used for compute and the public is used for the load balancers
3. Assuming that the end-users only contact the load balancers and the underlying instance are accessed for management purposes, design a security group scheme which supports the minimal set of ports required for communication.
4. The AWS generated load balancer hostname with be used for request to the public facing web application.
5. An autoscaling group should be created which utilizes the latest AWS AMI
6. The instance in the ASG Must contain both a root volume to store the application / services and must contain a secondary volume meant to store any log data bound from / var/log
Must include a web server of your choice.
7. Configure web application using Ansible, all requirements in this task of configuring the operating system should be defined in the launch configuration and/or the user data script
Your completed module should include a README which explains the module inputs and any important design decisions you made which may assist in evaluation.

Your module should not be tightly coupled to your AWS account – it should be designed to that it can be deployed to any arbitrary AWS account

8. Create self signed certificate for test.example.com and used this hostname with Load balancer, this dns should be resolve internally within VPC network with route 53 private hosted zone.



Additional Areas to Focus On (Extra Credit):


You must ensure that all data is encrypted at rest
Ideally, you should design these web servers so they can be managed without logging in with the root key
We should have some sort of cloudwatch alarm mechanism that indicates when the application is experiencing any issues.
Configure the autoscaling group to automatically add and remove nodes based on load


Solutions:

1. Created VPC with 10.20.0.0/16 CIDR
2. Created this architecture with high availability in region us-west-2
3. Load Balancer will get created into Public subnets
4. EC2 instances will get created into private subnets 
5. Created Nginx application in EC2 instance using user data
6. Created test.example.com record in Route53 under example.com hosted zone
7. To use this configuration only need to manage terraform.tfvars file as per your requirement 

