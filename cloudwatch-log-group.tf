#tfsec:ignore:aws-cloudwatch-log-group-customer-key -- Ignores the warning to use an encryption key for logs
resource "aws_cloudwatch_log_group" "this" {
  name              = var.log_group_path #NOTE - If you change this, update outputs also
  retention_in_days = var.log_retention_days
  tags              = merge(local.common_tags, {})
}