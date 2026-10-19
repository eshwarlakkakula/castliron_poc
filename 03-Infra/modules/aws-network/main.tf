# L1 AWS foundation - network
# VPC, public/private subnets per AZ, NAT gateway(s), and the VPC endpoints
# the lakehouse workload needs so that S3, STS, Kinesis, and Secrets Manager
# traffic never has to leave the AWS network.

terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

data "aws_region" "current" {}

locals {
  az_count = length(var.availability_zones)
}

resource "aws_vpc" "lakehouse_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(var.tags, { Name = "${var.name_prefix}-vpc" })
}

resource "aws_internet_gateway" "lakehouse_internet_gateway" {
  vpc_id = aws_vpc.lakehouse_vpc.id
  tags   = merge(var.tags, { Name = "${var.name_prefix}-igw" })
}

resource "aws_subnet" "private_subnets" {
  count             = local.az_count
  vpc_id            = aws_vpc.lakehouse_vpc.id
  cidr_block        = var.private_subnet_cidr_blocks[count.index]
  availability_zone = var.availability_zones[count.index]
  tags              = merge(var.tags, { Name = "${var.name_prefix}-private-${var.availability_zones[count.index]}" })
}

resource "aws_subnet" "public_subnets" {
  count                   = local.az_count
  vpc_id                  = aws_vpc.lakehouse_vpc.id
  cidr_block              = var.public_subnet_cidr_blocks[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  tags                    = merge(var.tags, { Name = "${var.name_prefix}-public-${var.availability_zones[count.index]}" })
}

resource "aws_eip" "nat_gateway_eips" {
  count  = var.single_nat_gateway ? 1 : local.az_count
  domain = "vpc"
  tags   = merge(var.tags, { Name = "${var.name_prefix}-nat-eip-${count.index}" })
}

resource "aws_nat_gateway" "lakehouse_nat_gateways" {
  count         = var.single_nat_gateway ? 1 : local.az_count
  allocation_id = aws_eip.nat_gateway_eips[count.index].id
  subnet_id     = aws_subnet.public_subnets[count.index].id
  tags          = merge(var.tags, { Name = "${var.name_prefix}-nat-${count.index}" })
  depends_on    = [aws_internet_gateway.lakehouse_internet_gateway]
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.lakehouse_vpc.id
  tags   = merge(var.tags, { Name = "${var.name_prefix}-public-rt" })
}

resource "aws_route" "public_internet_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.lakehouse_internet_gateway.id
}

resource "aws_route_table_association" "public_subnet_associations" {
  count          = local.az_count
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table" "private_route_tables" {
  count  = local.az_count
  vpc_id = aws_vpc.lakehouse_vpc.id
  tags   = merge(var.tags, { Name = "${var.name_prefix}-private-rt-${count.index}" })
}

resource "aws_route" "private_nat_routes" {
  count                  = local.az_count
  route_table_id         = aws_route_table.private_route_tables[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.single_nat_gateway ? aws_nat_gateway.lakehouse_nat_gateways[0].id : aws_nat_gateway.lakehouse_nat_gateways[count.index].id
}

resource "aws_route_table_association" "private_subnet_associations" {
  count          = local.az_count
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_route_tables[count.index].id
}

# ---------------------------------------------------------------- VPC endpoints
resource "aws_security_group" "vpc_endpoints_security_group" {
  count       = var.enable_vpc_endpoints ? 1 : 0
  name        = "${var.name_prefix}-vpce-sg"
  description = "Allow HTTPS from the lakehouse VPC to interface VPC endpoints"
  vpc_id      = aws_vpc.lakehouse_vpc.id

  ingress {
    description = "HTTPS from inside the VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-vpce-sg" })
}

resource "aws_vpc_endpoint" "s3_gateway_endpoint" {
  count             = var.enable_vpc_endpoints ? 1 : 0
  vpc_id            = aws_vpc.lakehouse_vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = aws_route_table.private_route_tables[*].id
  tags              = merge(var.tags, { Name = "${var.name_prefix}-vpce-s3" })
}

resource "aws_vpc_endpoint" "sts_interface_endpoint" {
  count               = var.enable_vpc_endpoints ? 1 : 0
  vpc_id              = aws_vpc.lakehouse_vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.sts"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_subnets[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints_security_group[0].id]
  private_dns_enabled = true
  tags                = merge(var.tags, { Name = "${var.name_prefix}-vpce-sts" })
}

resource "aws_vpc_endpoint" "kinesis_streams_interface_endpoint" {
  count               = var.enable_vpc_endpoints ? 1 : 0
  vpc_id              = aws_vpc.lakehouse_vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.kinesis-streams"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_subnets[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints_security_group[0].id]
  private_dns_enabled = true
  tags                = merge(var.tags, { Name = "${var.name_prefix}-vpce-kinesis" })
}

resource "aws_vpc_endpoint" "secrets_manager_interface_endpoint" {
  count               = var.enable_vpc_endpoints ? 1 : 0
  vpc_id              = aws_vpc.lakehouse_vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_subnets[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints_security_group[0].id]
  private_dns_enabled = true
  tags                = merge(var.tags, { Name = "${var.name_prefix}-vpce-secretsmanager" })
}
