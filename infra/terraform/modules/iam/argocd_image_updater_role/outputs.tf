##########################################
# IAM Role Output for Argo CD Image Updater
##########################################
output "image_updater_role_arn" {
  description = "IAM Role ARN for Argo CD Image Updater"
  value       = aws_iam_role.image_updater_role.arn
}

output "image_updater_role_name" {
  description = "IAM Role name for Argo CD Image Updater"
  value       = aws_iam_role.image_updater_role.name
}