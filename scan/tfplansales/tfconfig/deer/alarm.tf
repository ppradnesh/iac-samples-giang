locals {
  alarm_action_map = {
    qual = []
    cert = ["arn:aws:sns:us-east-1:801964547348:OpsIncidentServiceTopic-HIGH-DOWN"]
    prod = ["arn:aws:sns:us-east-1:801964547348:OpsIncidentServiceTopic-HIGH-DOWN"]
  }
  medium_alarm_action_map = {
    qual = []
    cert = ["arn:aws:sns:us-east-1:801964547348:OpsIncidentServiceTopic-MEDIUM-IMPAIRED"]
    prod = ["arn:aws:sns:us-east-1:801964547348:OpsIncidentServiceTopic-MEDIUM-IMPAIRED"]
  }
  api_description_map = {
    qual = "isg-sales-report-service API in qual does not create SNOW tickets"
    cert = "aws-isg-apps-cert-useast1-vpn.isg-sales.report-service-api"
    prod = "aws-isg-apps-prod-useast1-vpn.isg-sales.report-service-api"
  }
  cache_description_map = {
    qual = "isg-sales-report-service Cache in qual does not create SNOW tickets"
    cert = "aws-isg-apps-cert-useast1-vpn.isg-sales.vi-dead-letter-queue"
    prod = "aws-isg-apps-prod-useast1-vpn.isg-sales.vi-dead-letter-queue"
  }
  uuc_description_map = {
    qual = "isg-sales-report-service Cache in qual does not create SNOW tickets"
    cert = "aws-isg-apps-cert-useast1-vpn.isg-sales.virtual-inventory-uuc-queue"
    prod = "aws-isg-apps-prod-useast1-vpn.isg-sales.virtual-inventory-uuc-queue"
  }
}

resource "aws_cloudwatch_metric_alarm" "errors500CountAlarm" {
  alarm_name          = "${var.project_name} ${var.environment_name}: High 5XX error count."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "3600"
  statistic           = "Sum"
  treat_missing_data = "notBreaching"
  threshold           = "15"
  alarm_description   = local.api_description_map[var.environment_name]
  tags                = local.default_tags
  dimensions = {
    LoadBalancer = aws_lb.aws_lb.arn_suffix
  }
  alarm_actions       = local.alarm_action_map[var.environment_name]
  ok_actions          = local.alarm_action_map[var.environment_name]
}

resource "aws_cloudwatch_metric_alarm" "binDeadLetterQueueDepthAlarm" {
  alarm_name          = "${var.project_name} ${var.environment_name}: Bin DeadLetterQueue Depth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "0"
  alarm_description   = local.cache_description_map[var.environment_name]
  tags                = local.default_tags
  dimensions = {
    QueueName = aws_sqs_queue.bin-update-dlq.name
  }
  alarm_actions       = local.alarm_action_map[var.environment_name]
  ok_actions          = local.alarm_action_map[var.environment_name]
}

resource "aws_cloudwatch_metric_alarm" "binQueueAgeAlarm" {
  alarm_name          = "${var.project_name} ${var.environment_name}: Bin Queue Age"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateAgeOfOldestMessage"
  period              = "300"
  statistic           = "Maximum"
  # 3 hours
  threshold           = "10800"
  alarm_description   = local.cache_description_map[var.environment_name]
  tags                = local.default_tags
  dimensions = {
    QueueName = aws_sqs_queue.bin-update-queue.name
  }
  alarm_actions       = local.alarm_action_map[var.environment_name]
  ok_actions          = local.alarm_action_map[var.environment_name]
}

resource "aws_cloudwatch_metric_alarm" "viUUCQueueAgeAlarm" {
  alarm_name          = "${var.project_name} ${var.environment_name}: VI UUC Queue Age"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateAgeOfOldestMessage"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "3600"
  alarm_description   = local.uuc_description_map[var.environment_name]
  tags                = local.default_tags
  dimensions = {
    QueueName = "isg-sales-virtual-inventory-uuc-queue"
  }
  alarm_actions       = local.medium_alarm_action_map[var.environment_name]
  ok_actions          = local.medium_alarm_action_map[var.environment_name]
}