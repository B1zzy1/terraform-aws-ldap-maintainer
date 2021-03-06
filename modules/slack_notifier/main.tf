
resource "random_string" "this" {
  length  = 8
  special = false
  upper   = false
}

data "aws_s3_bucket" "artifacts" {
  bucket = var.artifacts_bucket_name
}

data "aws_iam_policy_document" "lambda" {
  statement {
    sid = "AllowWriteArtifactsBucket"
    actions = [
      "s3:Get*",
      "s3:List*",
      "s3:PutObject"
    ]
    resources = [data.aws_s3_bucket.artifacts.arn]
  }
}

module "lambda" {
  source = "github.com/claranet/terraform-aws-lambda"

  function_name = "${var.project_name}-slack-notifier-${random_string.this.result}"
  description   = "Sends alerts to slack and performs ldap maintenance tasks"
  handler       = "lambda.handler"
  runtime       = "python3.7"
  timeout       = 30

  source_path = "${path.module}/lambda"

  environment = {
    variables = {
      ARTIFACTS_BUCKET      = var.artifacts_bucket_name
      INVOKE_BASE_URL       = var.invoke_base_url
      LOG_LEVEL             = var.log_level
      SLACK_API_TOKEN       = var.slack_api_token
      SLACK_CHANNEL_ID      = var.slack_channel_id
      SFN_ACTIVITY_ARN      = var.sfn_activity_arn
      TIMEZONE              = var.timezone
      DAYS_SINCE_PWDLASTSET = var.days_since_pwdlastset
    }
  }

  policy = data.aws_iam_policy_document.lambda
}
