# AWS VPC and Networking for Grahvani
# Production-grade VPC with public/private subnets, NAT gateways, and VPC endpoints.

# Main VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name        = "grahvani-vpc"
    Environment = "production"
    Project     = "Grahvani"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "grahvani-igw"
  }
}

# Public Subnets (for NAT Gateways, ALB if needed)
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, 0)
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "grahvani-public-a"
    Type = "public"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, 1)
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "grahvani-public-b"
    Type = "public"
  }
}

resource "aws_subnet" "public_c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, 2)
  availability_zone       = "${var.aws_region}c"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "grahvani-public-c"
    Type = "public"
  }
}

# Private Subnets (for App Runner, RDS, ElastiCache)
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, 8)
  availability_zone = "${var.aws_region}a"
  
  tags = {
    Name = "grahvani-private-a"
    Type = "private"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, 9)
  availability_zone = "${var.aws_region}b"
  
  tags = {
    Name = "grahvani-private-b"
    Type = "private"
  }
}

resource "aws_subnet" "private_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, 10)
  availability_zone = "${var.aws_region}c"
  
  tags = {
    Name = "grahvani-private-c"
    Type = "private"
  }
}

# NAT Gateways (one per AZ for high availability)
resource "aws_eip" "nat_a" {
  domain = "vpc"
  tags = { Name = "grahvani-nat-eip-a" }
}

resource "aws_eip" "nat_b" {
  domain = "vpc"
  tags = { Name = "grahvani-nat-eip-b" }
}

resource "aws_eip" "nat_c" {
  domain = "vpc"
  tags = { Name = "grahvani-nat-eip-c" }
}

resource "aws_nat_gateway" "nat_a" {
  allocation_id = aws_eip.nat_a.id
  subnet_id     = aws_subnet.public_a.id
  
  tags = { Name = "grahvani-nat-a" }
}

resource "aws_nat_gateway" "nat_b" {
  allocation_id = aws_eip.nat_b.id
  subnet_id     = aws_subnet.public_b.id
  
  tags = { Name = "grahvani-nat-b" }
}

resource "aws_nat_gateway" "nat_c" {
  allocation_id = aws_eip.nat_c.id
  subnet_id     = aws_subnet.public_c.id
  
  tags = { Name = "grahvani-nat-c" }
}

# Route Tables
# Public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = { Name = "grahvani-public-rt" }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_c" {
  subnet_id      = aws_subnet.public_c.id
  route_table_id = aws_route_table.public.id
}

# Private route tables (one per AZ with corresponding NAT)
resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_a.id
  }
  
  tags = { Name = "grahvani-private-rt-a" }
}

resource "aws_route_table" "private_b" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_b.id
  }
  
  tags = { Name = "grahvani-private-rt-b" }
}

resource "aws_route_table" "private_c" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_c.id
  }
  
  tags = { Name = "grahvani-private-rt-c" }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_a.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_b.id
}

resource "aws_route_table_association" "private_c" {
  subnet_id      = aws_subnet.private_c.id
  route_table_id = aws_route_table.private_c.id
}

# VPC Endpoints (for private access to AWS services)
# S3 Gateway Endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type   = "Gateway"
  route_table_ids     = [aws_route_table.private_a.id, aws_route_table.private_b.id, aws_route_table.private_c.id]
  
  tags = { Name = "grahvani-s3-endpoint" }
}

# DynamoDB Gateway Endpoint (if needed for future)
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.dynamodb"
  vpc_endpoint_type   = "Gateway"
  route_table_ids     = [aws_route_table.private_a.id, aws_route_table.private_b.id, aws_route_table.private_c.id]
  
  tags = { Name = "grahvani-dynamodb-endpoint" }
}

# Interface Endpoints for private AWS service access
# Secrets Manager
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_b.id, aws_subnet.private_c.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
  
  tags = { Name = "grahvani-secretsmanager-endpoint" }
}

# KMS
resource "aws_vpc_endpoint" "kms" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.kms"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_b.id, aws_subnet.private_c.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
  
  tags = { Name = "grahvani-kms-endpoint" }
}

# CloudWatch Logs
resource "aws_vpc_endpoint" "cloudwatch_logs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_b.id, aws_subnet.private_c.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
  
  tags = { Name = "grahvani-cloudwatch-logs-endpoint" }
}

# CloudWatch Monitoring
resource "aws_vpc_endpoint" "cloudwatch_monitoring" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.monitoring"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_b.id, aws_subnet.private_c.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
  
  tags = { Name = "grahvani-cloudwatch-monitoring-endpoint" }
}

# STS (for IAM roles)
resource "aws_vpc_endpoint" "sts" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.sts"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_b.id, aws_subnet.private_c.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
  
  tags = { Name = "grahvani-sts-endpoint" }
}

# ECR (for container images)
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_b.id, aws_subnet.private_c.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
  
  tags = { Name = "grahvani-ecr-api-endpoint" }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_b.id, aws_subnet.private_c.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
  
  tags = { Name = "grahvani-ecr-dkr-endpoint" }
}

# Security Group for VPC Endpoints
resource "aws_security_group" "vpc_endpoints" {
  name        = "grahvani-vpc-endpoints-sg"
  description = "Security group for VPC interface endpoints"
  vpc_id      = aws_vpc.main.id
  
  # Allow HTTPS from private subnets
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = { Name = "grahvani-vpc-endpoints-sg" }
}

# Security Group for App Runner
resource "aws_security_group" "apprunner" {
  name        = "grahvani-apprunner-sg"
  description = "Security group for Grahvani App Runner service"
  vpc_id      = aws_vpc.main.id
  
  # Allow outbound to private subnets (RDS, ElastiCache, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }
  
  tags = { Name = "grahvani-apprunner-sg" }
}

# Security Group for Bastion Host
resource "aws_security_group" "bastion" {
  name        = "grahvani-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = aws_vpc.main.id
  
  # Allow SSH from trusted IPs only
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.bastion_allowed_cidrs
  }
  
  # Allow outbound to private subnets
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }
  
  tags = { Name = "grahvani-bastion-sg" }
}

# Flow Logs for VPC traffic monitoring
resource "aws_flow_log" "vpc" {
  iam_role_arn      = aws_iam_role.flow_logs.arn
  log_destination   = aws_cloudwatch_log_group.vpc_flow_logs.arn
  traffic_type      = "ALL"
  vpc_id            = aws_vpc.main.id
  
  tags = { Name = "grahvani-vpc-flow-logs" }
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/grahvani-flow-logs"
  retention_in_days = 30
  
  tags = { Name = "grahvani-vpc-flow-logs" }
}

resource "aws_iam_role" "flow_logs" {
  name = "grahvani-vpc-flow-logs-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "flow_logs" {
  role       = aws_iam_role.flow_logs.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}