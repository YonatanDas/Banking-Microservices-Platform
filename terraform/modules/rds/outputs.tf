output "db_endpoint" {
  value = aws_db_instance.this.address
}

output "db_identifier" {
  value = aws_db_instance.this.identifier
}
