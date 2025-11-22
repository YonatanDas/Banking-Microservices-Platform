variable "environment" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "db_engine" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type = string
}

variable "db_sg_id" {
  type = string
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_name" {
  type = string
}

variable "engine_version" {
  default = "13.15"
}

variable "allocated_storage" {
  default = 20
}

variable "backup_retention_period" {
  default = 0
}

variable "multi_az" {
  default = false
}

variable "publicly_accessible" {
  default = false
}

variable "deletion_protection" {
  default = false
}

 variable "skip_final_snapshot" {
   default = true
 }

