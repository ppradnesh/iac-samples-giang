
locals {
  lambad_zip_location = "target/isg-sales-virtual-inventory-sync.zip"
  vi_lambda_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ofp/ofp-lambda-role"
}

data aws_iam_policy_document "vi-sync-dlq-policy" {
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

resource "aws_lambda_event_source_mapping" "isg_sales_event_queue_lambda_mapping" {
  event_source_arn = "${aws_sqs_queue.vi-sync-queue.arn}"
  function_name    = "${aws_lambda_function.isg-sales-virtual-inventory-sync.arn}"
  batch_size       = 10
}

resource "aws_dynamodb_table" "isg-sales-vi-history-sync" {
  name = "isg-sales-virtual-inventory-sync"
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
      name = "transferredToInventoryTime"
      type = "S"
    }

    global_secondary_index {
      hash_key = "dealerAccountKey"
      range_key = "transferredToInventoryTime"
      name = "BY_DEALER_ACCOUNT_KEY_SORTED_BY_INVENTORYINTIME"
      projection_type = "ALL"
    }
}

resource "aws_lambda_function" "isg-sales-virtual-inventory-sync" {
  s3_bucket = "deere-isg-sharedservices-prod-deploy"
  s3_key = "ISGSalesSystem/isg-sales-report-service/${var.git_commit}/isg-sales-vi-service.zip"
  environment {
     variables = {
       NODE_ENV = var.environment_name
     }
   }
  function_name = "isg-sales-virtual-inventory-sync"
  handler = "index.isgSalesVirtualInventoryRewire"
  role = "${local.vi_lambda_role_arn}"
  runtime = "nodejs12.x"
  description = "Lambda function for virtual inventory service sync."
  memory_size = 3000
  tracing_config {
    mode = "Active"
  }
}

data aws_iam_policy_document "vi-sync-queue-iam-policy" {
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


resource "aws_sqs_queue" "vi-sync-queue" {
  name = "isg-sales-virtual-inventory-sync"
  visibility_timeout_seconds = local.visibility-timeout
  message_retention_seconds = local.max-message-retention-seconds / 2
  policy = data.aws_iam_policy_document.vi-sync-queue-iam-policy.json
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.vi-sync-dlq.arn
    maxReceiveCount = 12
  })
}

resource "aws_sqs_queue" "vi-sync-dlq" {
  name = "isg-sales-virtual-inventory-sync-dlq"
  policy = data.aws_iam_policy_document.isg-sales-virtual-inventory-sync-dlq-policy.json
  visibility_timeout_seconds = local.visibility-timeout
  message_retention_seconds = local.max-message-retention-seconds
}


data aws_iam_policy_document "isg-sales-virtual-inventory-sync-dlq-policy" {
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
      identifiers = ["*"]
    }
  }
}
