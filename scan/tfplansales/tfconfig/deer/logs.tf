resource "aws_cloudwatch_log_group" "log_group" {
  name              = var.project_name
  tags              = local.default_tags
  retention_in_days = "30"
}
