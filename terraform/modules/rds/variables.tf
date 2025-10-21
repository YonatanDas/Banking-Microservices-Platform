variable "environment" {}
variable "subnet_ids" {
  type = list(string)
}
variable "db_username" {}
variable "db_password" {}
variable "db_sg_id" {}
variable "db_instance_class" {}