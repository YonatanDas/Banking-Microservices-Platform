##########################################
# IAM Root Module - orchestrates submodules
##########################################

module "cluster_role" {
  source      = "./cluster_role"
  name_prefix = "${var.environment}-${var.cluster_name}"
}

module "node_role" {
  source      = "./node_role"
  name_prefix = "${var.environment}-${var.cluster_name}"
}

