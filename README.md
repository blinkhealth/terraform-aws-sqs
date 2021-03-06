# AWS SQS Terraform module

Terraform module which creates SQS resources on AWS.

These types of resources are supported:

* [SQS queue](https://www.terraform.io/docs/providers/aws/r/sqs_queue.html) with optional [server-side encryption using KMS](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-server-side-encryption.html)

## Terraform versions

Terraform 0.12. Pin module version to `~> v2.0`. Submit pull-requests to `master` branch.

Terraform 0.11. Pin module version to `~> v1.0`. Submit pull-requests to `terraform011` branch.

## Usage

```hcl
module "user_queue" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "~> 2.0"

  name = "user"

  tags = {
    Service     = "user"
    Environment = "dev"
  }
}
```

## Examples

* [SQS queues with server-side encryption (SSE) using KMS and without SSE](https://github.com/terraform-aws-modules/terraform-aws-sqs/tree/master/examples/complete-sqs)

## Conditional creation

Sometimes you need to have a way to create SQS queue conditionally but Terraform does not allow to use `count` inside `module` block, so the solution is to specify argument `create`.

```hcl
# This SQS queue will not be created
module "user_queue" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "~> 2.0"

  create = false
  # ... omitted
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| aws | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| allow\_read\_iam\_arns | Allow these IAM users/roles to read messages in the queue.  Not used when `policy` is specified. | `list(string)` | `[]` | no |
| allow\_write\_cloudwatch\_events\_rules | Allow these CloudWatch Events rule ARNs to create messages in the queue.  Not used when `policy` is specified. | `list(string)` | `[]` | no |
| allow\_write\_iam\_arns | Allow these IAM users/roles to create and manage messages in the queue.  Not used when `policy` is specified. | `list(string)` | `[]` | no |
| content\_based\_deduplication | Enables content-based deduplication for FIFO queues | `bool` | `false` | no |
| create | Whether to create SQS queue | `bool` | `true` | no |
| delay\_seconds | The time in seconds that the delivery of all messages in the queue will be delayed. An integer from 0 to 900 (15 minutes) | `number` | `0` | no |
| fifo\_queue | Boolean designating a FIFO queue | `bool` | `false` | no |
| kms\_data\_key\_reuse\_period\_seconds | The length of time, in seconds, for which Amazon SQS can reuse a data key to encrypt or decrypt messages before calling AWS KMS again. An integer representing seconds, between 60 seconds (1 minute) and 86,400 seconds (24 hours) | `number` | `300` | no |
| kms\_master\_key\_id | The ID of an AWS-managed customer master key (CMK) for Amazon SQS or a custom CMK | `string` | `null` | no |
| max\_message\_size | The limit of how many bytes a message can contain before Amazon SQS rejects it. An integer from 1024 bytes (1 KiB) up to 262144 bytes (256 KiB) | `number` | `262144` | no |
| message\_retention\_seconds | The number of seconds Amazon SQS retains a message. Integer representing seconds, from 60 (1 minute) to 1209600 (14 days) | `number` | `345600` | no |
| name | This is the human-readable name of the queue. If omitted, Terraform will assign a random name. | `string` | `null` | no |
| name\_prefix | A unique name beginning with the specified prefix. | `string` | `null` | no |
| policy | The JSON policy for the SQS queue | `string` | `null` | no |
| receive\_wait\_time\_seconds | The time for which a ReceiveMessage call will wait for a message to arrive (long polling) before returning. An integer from 0 to 20 (seconds) | `number` | `0` | no |
| redrive\_dlq\_target\_arn | The redrive policy's deadLetterTargetArn.  Setting this will create a redrive policy.  Not used when `redrive_policy` is specified. | `string` | `null` | no |
| redrive\_max\_receive\_count | The redrive policy's maxReceiveCount.  Requires variable `redrive_dlq_target_arn` to be set.  Not used when `redrive_policy` is specified. | `number` | `5` | no |
| redrive\_policy | The JSON policy to set up the Dead Letter Queue, see AWS docs. Note: when specifying maxReceiveCount, you must specify it as an integer (5), and not a string ("5") | `string` | `""` | no |
| sns\_topic\_subscription\_arn | Subscribe the queue to this SNS topic | `string` | `""` | no |
| tags | A mapping of tags to assign to all resources | `map(string)` | `{}` | no |
| visibility\_timeout\_seconds | The visibility timeout for the queue. An integer from 0 to 43200 (12 hours) | `number` | `30` | no |

## Outputs

| Name | Description |
|------|-------------|
| this\_sqs\_queue\_arn | The ARN of the SQS queue |
| this\_sqs\_queue\_id | The URL for the created Amazon SQS queue |
| this\_sqs\_queue\_name | The name of the SQS queue |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Authors

Module managed by [Anton Babenko](https://github.com/antonbabenko).

## License

Apache 2 Licensed. See LICENSE for full details.
