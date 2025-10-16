# VPC Module - Main Configuration
# This module creates a VPC with associated networking components

# ------------------------
# VPC
# ------------------------
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.env_prefix}-vpc"
    Environment = var.env_prefix
  }
}

# ------------------------
# Internet Gateway
# ------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.env_prefix}-igw"
  }
}

# ------------------------
# Public Subnets
# ------------------------
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.env_prefix}-public-subnet-${count.index + 1}"
    Environment = var.env_prefix
  }
}

# ------------------------
# Private Subnets
# ------------------------
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = element(var.availability_zones, count.index)

  tags = {
    Name        = "${var.env_prefix}-private-subnet-${count.index + 1}"
    Environment = var.env_prefix
  }
}

# ------------------------
# Elastic IP for NAT Gateway
# ------------------------
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = {
    Name = "${var.env_prefix}-nat-eip"
  }
}

# ------------------------
# NAT Gateway
# ------------------------
resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.env_prefix}-natgw"
  }

  depends_on = [aws_internet_gateway.igw]
}

# ------------------------
# Route Tables
# ------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.env_prefix}-public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgw.id
  }

  tags = {
    Name = "${var.env_prefix}-private-rt"
  }
}

resource "aws_route_table_association" "private_assoc" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}