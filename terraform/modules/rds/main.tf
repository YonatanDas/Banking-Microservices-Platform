resource "aws_db_subnet_group" "this" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.environment}-db-subnet-group"
  }
}

resource "aws_db_instance" "this" {
  identifier              = "${var.environment}-db"
  engine                  = var.db_engine         
  engine_version = var.engine_version
  instance_class          = var.db_instance_class
  allocated_storage       = var.allocated_storage
  username                = var.db_username
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [var.db_sg_id]
  publicly_accessible     = var.publicly_accessible # Set to true if you want the DB to be publicly accessible
  backup_retention_period = var.backup_retention_period
  deletion_protection     = var.deletion_protection # Set to true to prevent accidental deletion
  db_name = var.db_name
  tags = {
    Name = "${var.environment}-rds"
  }

  depends_on = [aws_db_subnet_group.this]
}

