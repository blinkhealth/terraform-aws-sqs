locals {
  redrive_policy = {
    deadLetterTargetArn = var.redrive_dlq_target_arn
    maxReceiveCount     = var.redrive_max_receive_count
  }

  redrive_policy_is_valid = local.redrive_policy.deadLetterTargetArn != null

  # use the local redrive policy if it's valid and var.redrive_policy is empty
  use_local_redrive_policy = local.redrive_policy_is_valid && length(var.redrive_policy) == 0
}

resource "aws_sqs_queue" "this" {
  count = var.create ? 1 : 0

  name        = var.name
  name_prefix = var.name_prefix

  visibility_timeout_seconds  = var.visibility_timeout_seconds
  message_retention_seconds   = var.message_retention_seconds
  max_message_size            = var.max_message_size
  delay_seconds               = var.delay_seconds
  receive_wait_time_seconds   = var.receive_wait_time_seconds
  policy                      = local.use_policy_doc ? data.aws_iam_policy_document.this[0].json : var.policy
  redrive_policy              = local.use_local_redrive_policy ? jsonencode(local.redrive_policy) : var.redrive_policy
  fifo_queue                  = var.fifo_queue
  content_based_deduplication = var.content_based_deduplication

  kms_master_key_id                 = var.kms_master_key_id
  kms_data_key_reuse_period_seconds = var.kms_data_key_reuse_period_seconds

  tags = var.tags
}

data "aws_arn" "this" {
  count = var.create ? 1 : 0

  arn = aws_sqs_queue.this[0].arn

}

data "aws_iam_policy_document" "this" {
  # dont create the document if we don't need to (simplify plan output)
  count = var.create ? 1 : 0

  # both readers and writers are allowed to read metadata
  dynamic "statement" {
    for_each = length(var.allow_read_iam_arns) > 0 || length(var.allow_write_iam_arns) > 0 ? [true] : []
    content {
      sid = "Metadata"
      actions = [
        "sqs:GetQueueAttributes",
        "sqs:GetQueueUrl",
        "sqs:ListDeadLetterSourceQueues",
      ]
      principals {
        type        = "AWS"
        identifiers = setunion(var.allow_read_iam_arns, var.allow_write_iam_arns)
      }
      # in a queue policy a "*" means "this queue"
      resources = ["*"]
    }
  }

  # allow readers to ReceiveMessage
  dynamic "statement" {
    for_each = length(var.allow_read_iam_arns) > 0 ? [true] : []
    content {
      sid     = "Read"
      actions = ["sqs:ReceiveMessage"]
      principals {
        type        = "AWS"
        identifiers = var.allow_read_iam_arns
      }
      resources = ["*"]
    }
  }

  # allow writers to SendMessage and manage messages in the queue
  dynamic "statement" {
    for_each = length(var.allow_write_iam_arns) > 0 ? [true] : []
    content {
      sid = "Write"
      actions = [
        "sqs:ChangeMessageVisibility",
        "sqs:DeleteMessage",
        "sqs:PurgeQueue",
        "sqs:SendMessage",
      ]
      principals {
        type        = "AWS"
        identifiers = var.allow_write_iam_arns
      }
      resources = ["*"]
    }
  }

  # allow SNS and EventBridge to SendMessage to the quee
  dynamic "statement" {
    for_each = length(var.sns_topic_subscription_arn) > 0 || length(var.allow_write_eventbridge_rules) > 0 ? [true] : []
    content {
      sid     = "services-write"
      actions = ["sqs:SendMessage"]
      principals {
        type        = "AWS"
        identifiers = ["*"]
      }
      resources = ["*"]
      condition {
        test     = "ArnLike"
        variable = "aws:SourceArn"
        values = compact(
          concat(
            [var.sns_topic_subscription_arn],
            var.allow_write_eventbridge_rules
          )
        )
      }
    }
  }
}

locals {
  # an iam policy doc with an empty `statement` means var.allow_*_arns were empty
  policy_doc_is_valid = data.aws_iam_policy_document.this[0].statement != null

  # we only want to use our policy doc if it's valid and var.policy is null
  use_policy_doc = local.policy_doc_is_valid && var.policy == null
}

resource aws_sns_topic_subscription this {
  count     = (var.create && length(var.sns_topic_subscription_arn) > 0) ? 1 : 0
  topic_arn = var.sns_topic_subscription_arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.this[0].arn
}
