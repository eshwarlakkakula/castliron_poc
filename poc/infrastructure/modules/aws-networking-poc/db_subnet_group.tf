resource "aws_db_subnet_group" "poc" {
  name       = "${var.name_prefix}-poc"
  subnet_ids = [for subnet in aws_subnet.public : subnet.id]
  tags       = merge(var.tags, { Name = "${var.name_prefix}-poc" })
}
