resource "aws_sqs_queue" "this" {
  count = var.create ? 1 : 0

  name        = var.name
  name_prefix = var.name_prefix

  visibility_timeout_seconds  = var.visibility_timeout_seconds
  message_retention_seconds   = var.message_retention_seconds
  max_message_size            = var.max_message_size
  delay_seconds               = var.delay_seconds
  receive_wait_time_seconds   = var.receive_wait_time_seconds
  policy                      = local.policy_doc_is_valid ? data.aws_iam_policy_document.this.json : var.policy
  redrive_policy              = var.redrive_policy
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
  # both readers and writers are allowed to read metadata
  dynamic "statement" {
    for_each = length(var.allow_read_arns) > 0 || length(var.allow_write_arns) < 0 ? [true] : []
    content {
      sid = "Metadata"
      actions = [
        "sqs:GetQueueAttributes",
        "sqs:GetQueueUrl",
        "sqs:ListDeadLetterSourceQueues",
      ]
      principals {
        type        = "AWS"
        identifiers = setunion(var.allow_read_arns, var.allow_write_arns)
      }
      # in a queue policy a "*" means "this queue"
      resources = ["*"]
    }
  }

  # allow readers to ReceiveMessage
  dynamic "statement" {
    for_each = length(var.allow_read_arns) > 0 ? [true] : []
    content {
      sid     = "Read"
      actions = ["sqs:ReceiveMessage"]
      principals {
        type        = "AWS"
        identifiers = var.allow_read_arns
      }
      resources = ["*"]
    }
  }

  # allow writers to SendMessage and manage messages in the queue
  dynamic "statement" {
    for_each = var.allow_read_arns != [] ? [true] : []
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
        identifiers = var.allow_write_arns
      }
    }
  }
}

locals {
  # an iam policy doc with an empty `statement` means var.allow_*_arns were empty
  policy_doc_is_valid = length(data.aws_iam_policy_document.this.statement) > 0
}
