resource "aws_vpc" "poc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(var.tags, { Name = "${var.name_prefix}-vpc" })
}

resource "aws_internet_gateway" "poc" {
  vpc_id = aws_vpc.poc.id
  tags   = merge(var.tags, { Name = "${var.name_prefix}-igw" })
}
