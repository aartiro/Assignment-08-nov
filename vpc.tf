# VPC
resource "aws_vpc" "web-app-vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "web-app-vpc"
  }
}
# Public subnets

resource "aws_subnet" "public_subnets" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.web-app-vpc.id
  cidr_block        = element(var.public_subnet_cidrs, count.index)
  availability_zone = element(var.availability_zones, count.index)

  tags = {
    Name = "Public Subnet ${count.index + 1}"
  }
}

# Private Subnets 
resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.web-app-vpc.id
  cidr_block        = element(var.private_subnet_cidrs, count.index)
  availability_zone = element(var.availability_zones, count.index)

  tags = {
    Name = "Private Subnet ${count.index + 1}"
  }
}

# Internet Gateway for the public subnet
resource "aws_internet_gateway" "web-app-igw" {
  tags = {
    Name = "web-app-igw"
  }
  vpc_id = aws_vpc.web-app-vpc.id
}

# NAT Gateway for the public subnet
resource "aws_eip" "nat_gateway" {
  vpc                       = true
  associate_with_private_ip = "10.0.0.5"
  depends_on                = [aws_internet_gateway.web-app-igw]
}

resource "aws_nat_gateway" "web-app-ngw" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id     = aws_subnet.public_subnets[0].id

  tags = {
    Name = "web-app-ngw"
  }
  depends_on = [aws_eip.nat_gateway]
}

# Route tables for the subnets
resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.web-app-vpc.id
  tags = {
    Name = "public-web-app-route-table"
  }
}
resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.web-app-vpc.id
  tags = {
    Name = "private-web-app-route-table"
  }
}

# Route the public subnet traffic through the Internet Gateway
resource "aws_route" "public-internet-igw-route" {
  route_table_id         = aws_route_table.public-route-table.id
  gateway_id             = aws_internet_gateway.web-app-igw.id
  destination_cidr_block = "0.0.0.0/0"
}

# Route NAT Gateway
resource "aws_route" "nat-ngw-route" {
  route_table_id         = aws_route_table.private-route-table.id
  nat_gateway_id         = aws_nat_gateway.web-app-ngw.id
  destination_cidr_block = "0.0.0.0/0"
}

# Associate the newly created route tables to the subnets

resource "aws_route_table_association" "public_subnet_asso" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
  route_table_id = aws_route_table.public-route-table.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = element(aws_subnet.private_subnets[*].id, count.index)
  route_table_id = aws_route_table.private-route-table.id
}