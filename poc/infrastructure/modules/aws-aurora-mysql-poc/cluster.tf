resource "aws_rds_cluster" "poc" {
  cluster_identifier     = "${var.name_prefix}-aurora-mysql"
  engine                 = "aurora-mysql"
  engine_mode            = "provisioned"
  engine_version         = var.engine_version
  database_name          = var.database_name
  master_username        = var.master_username
  manage_master_user_password = true
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = var.vpc_security_group_ids
  storage_encrypted      = true
  skip_final_snapshot    = var.skip_final_snapshot
  apply_immediately      = true

  serverlessv2_scaling_configuration {
    min_capacity = var.min_capacity
    max_capacity = var.max_capacity
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-aurora-mysql" })
}

resource "aws_rds_cluster_instance" "poc" {
  cluster_identifier   = aws_rds_cluster.poc.id
  instance_class       = "db.serverless"
  engine               = aws_rds_cluster.poc.engine
  engine_version       = aws_rds_cluster.poc.engine_version
  publicly_accessible  = var.publicly_accessible
  tags                 = merge(var.tags, { Name = "${var.name_prefix}-aurora-mysql-0" })
}
