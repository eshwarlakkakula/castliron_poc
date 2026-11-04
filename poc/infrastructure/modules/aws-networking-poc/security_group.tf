resource "aws_security_group" "poc_ingress" {
  name        = "${var.name_prefix}-ingress"
  description = "Shared ingress security group for POC data services"
  vpc_id      = aws_vpc.poc.id
  tags        = merge(var.tags, { Name = "${var.name_prefix}-ingress" })
}

locals {
  ingress_rule_cidrs = merge([
    for rule in var.ingress_rules : {
      for cidr in rule.cidr_blocks : "${rule.from_port}-${rule.to_port}-${cidr}" => {
        description = rule.description
        from_port   = rule.from_port
        to_port     = rule.to_port
        cidr_block  = cidr
      }
    }
  ]...)
}

resource "aws_vpc_security_group_ingress_rule" "rules" {
  for_each = local.ingress_rule_cidrs

  security_group_id = aws_security_group.poc_ingress.id
  description       = each.value.description
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value.cidr_block
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.poc_ingress.id
  cidr_ipv4          = "0.0.0.0/0"
  ip_protocol        = "-1"
}
