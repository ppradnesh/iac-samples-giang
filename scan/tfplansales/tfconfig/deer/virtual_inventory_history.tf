resource "aws_dynamodb_table" "isg-sales-vi-history-bypass" {
  name = "isg-sales-vi-history-bypass"
  hash_key = "transactionId"
  tags = local.default_tags
  billing_mode = "PAY_PER_REQUEST"

  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = "transactionId"
    type = "S"
  }
  attribute {
    name = "dealerAccountKey"
    type = "S"
  }
  attribute {
    name = "modifiedByTime"
    type = "S"
  }

  global_secondary_index {
    hash_key = "dealerAccountKey"
    range_key = "modifiedByTime"
    name = "dealerAccountNumber_modifiedByTime"
    projection_type = "ALL"
  }
}

locals {
  visibility-timeout = 300
  max-message-retention-seconds = 1209600
  retry-buffer = 2
  redrive-policy = {
    deadLetterTargetArn = aws_sqs_queue.bin-update-dlq.arn
    maxReceiveCount = 12
  }
  bin-update-topic-arn = "arn:aws:sns:us-east-1:${data.aws_caller_identity.current.account_id}:isg-sales-activation-service-bin-update"
}

data aws_iam_policy_document "bin-update-dlq-policy" {
  statement {
    sid = "AllowConsume"
    actions = [
      "sqs:*"
    ]
    resources = [
      "*"
    ]

    principals {
      type = "AWS"
      identifiers = [
        data.aws_iam_role.iam_role.arn
      ]
    }
  }
}

resource "aws_sqs_queue" "bin-update-dlq" {
  name = "isg-sales-report-service-activation-bin-update-dlq"
  policy = data.aws_iam_policy_document.bin-update-dlq-policy.json
  visibility_timeout_seconds = local.visibility-timeout

  message_retention_seconds = local.max-message-retention-seconds
}

data aws_iam_policy_document "bin-update-queue-iam-policy" {
  statement {
    sid = "AllowPublish"
    actions = [
      "sqs:SendMessage"
    ]
    resources = [
      "*"
    ]
    principals {
      identifiers = ["*"]
      type = "AWS"
    }
    condition {
      test = "ArnEquals"
      variable = "aws:SourceArn"

      values = [
        local.bin-update-topic-arn
      ]
    }
  }

  statement {
    sid = "AllowConsume"
    actions = [
      "sqs:*"
    ]
    resources = [
      "*"
    ]

    principals {
      type = "AWS"
      identifiers = [
        data.aws_iam_role.iam_role.arn
      ]
    }
  }
}



resource "aws_sqs_queue" "bin-update-queue" {
  name = "isg-sales-report-service-activation-bin-update"
  visibility_timeout_seconds = local.visibility-timeout
  message_retention_seconds = local.max-message-retention-seconds / 2
  redrive_policy = jsonencode(local.redrive-policy)
  policy = data.aws_iam_policy_document.bin-update-queue-iam-policy.json
}


resource "aws_sns_topic_subscription" "bin-update-queue-subscription" {
  topic_arn = local.bin-update-topic-arn
  protocol = "sqs"
  endpoint = aws_sqs_queue.bin-update-queue.arn
  raw_message_delivery = true
}
