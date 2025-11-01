output "github_oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.github_oidc.arn
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}