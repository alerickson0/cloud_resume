locals {
  account_id     = data.aws_caller_identity.current.account_id
  current_region = data.aws_region.current.name
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "create_log_group_policy" {
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup"]
    resources = ["arn:aws:logs:${local.current_region}:${local.account_id}:*"]
  }
}

data "aws_iam_policy_document" "log_actions_policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${local.current_region}:${local.account_id}:log-group:/aws/lambda/updateVisitorCounter_lambda:*"
    ]
  }
}

# "old" policy_two policies
data "aws_iam_policy_document" "log_dynamodb_actions_policy" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:*",
      "dax:*",
      "application-autoscaling:DeleteScalingPolicy",
      "application-autoscaling:DeregisterScalableTarget",
      "application-autoscaling:DescribeScalableTargets",
      "application-autoscaling:DescribeScalingActivities",
      "application-autoscaling:DescribeScalingPolicies",
      "application-autoscaling:PutScalingPolicy",
      "application-autoscaling:RegisterScalableTarget",
      "cloudwatch:DeleteAlarms",
      "cloudwatch:DescribeAlarmHistory",
      "cloudwatch:DescribeAlarms",
      "cloudwatch:DescribeAlarmsForMetric",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics",
      "cloudwatch:PutMetricAlarm",
      "cloudwatch:GetMetricData",
      "datapipeline:ActivatePipeline",
      "datapipeline:CreatePipeline",
      "datapipeline:DeletePipeline",
      "datapipeline:DescribeObjects",
      "datapipeline:DescribePipelines",
      "datapipeline:GetPipelineDefinition",
      "datapipeline:ListPipelines",
      "datapipeline:PutPipelineDefinition",
      "datapipeline:QueryObjects",
      "ec2:DescribeVpcs",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "iam:GetRole",
      "iam:ListRoles",
      "kms:DescribeKey",
      "kms:ListAliases",
      "sns:CreateTopic",
      "sns:DeleteTopic",
      "sns:ListSubscriptions",
      "sns:ListSubscriptionsByTopic",
      "sns:ListTopics",
      "sns:Subscribe",
      "sns:Unsubscribe",
      "sns:SetTopicAttributes",
      "lambda:CreateFunction",
      "lambda:ListFunctions",
      "lambda:ListEventSourceMappings",
      "lambda:CreateEventSourceMapping",
      "lambda:DeleteEventSourceMapping",
      "lambda:GetFunctionConfiguration",
      "lambda:DeleteFunction",
      "resource-groups:ListGroups",
      "resource-groups:ListGroupResources",
      "resource-groups:GetGroup",
      "resource-groups:GetGroupQuery",
      "resource-groups:DeleteGroup",
      "resource-groups:CreateGroup",
      "tag:GetResources",
      "kinesis:ListStreams",
      "kinesis:DescribeStream",
      "kinesis:DescribeStreamSummary"
    ]
    resources = [
      "arn:aws:dynamodb:${local.current_region}:${local.account_id}:table/visitor_counter_count"
    ]
  }
}

data "aws_iam_policy_document" "get_insight_report_policy" {
  statement {
    effect    = "Allow"
    actions   = ["cloudwatch:GetInsightRuleReport"]
    resources = ["arn:aws:cloudwatch:*:*:insight-rule/DynamoDBContributorInsights*"]
  }
}

data "aws_iam_policy_document" "pass_role_policy" {
  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "iam:PassedToService"
      values = [
        "application-autoscaling.amazonaws.com",
        "application-autoscaling.amazonaws.com.cn",
        "dax.amazonaws.com"
      ]
    }
  }
}

data "aws_iam_policy_document" "create_service_linked_role_policy" {
  statement {
    effect = "Allow"
    actions = [
      "iam:CreateServiceLinkedRole"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values = [
        "replication.dynamodb.amazonaws.com",
        "dax.amazonaws.com",
        "dynamodb.application-autoscaling.amazonaws.com",
        "contributorinsights.dynamodb.amazonaws.com",
        "kinesisreplication.dynamodb.amazonaws.com"
      ]
    }
  }
}

data "archive_file" "lambda_archive" {
  type        = "zip"
  source_file = "${path.module}/back-end/lambda/lambda_function.py"
  output_path = "${path.module}/back-end/lambda/updateVisitorCounter_lambda.zip"
}

# IAM role definition
resource "aws_iam_role" "updateVisitorCounter-role-h7zmdlm8" {
  name               = "update_dd_table_role"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json
}

resource "aws_iam_policy" "log_group_creation_policy" {
  name        = "policy-log-actions"
  description = "Custom policy to be able to create log groups"
  policy      = data.aws_iam_policy_document.create_log_group_policy.json
}

resource "aws_iam_policy" "create_put_logs_policy" {
  name        = "policy-create-put-logs"
  description = "Custom policy to create log streams and put log events"
  policy      = data.aws_iam_policy_document.log_actions_policy.json
}

resource "aws_iam_role_policy_attachment" "log_group_creation_policy_attach" {
  role       = aws_iam_role.updateVisitorCounter-role-h7zmdlm8.name
  policy_arn = aws_iam_policy.log_group_creation_policy.arn
}

resource "aws_iam_role_policy_attachment" "create_put_logs_policy_attach" {
  role       = aws_iam_role.updateVisitorCounter-role-h7zmdlm8.name
  policy_arn = aws_iam_policy.create_put_logs_policy.arn
}

resource "aws_iam_policy" "logging_dynamodb_actions_policy" {
  name        = "policy-logging-dynamodb-actions"
  description = "Custom policy to be able to log dynamodb and other actions"
  policy      = data.aws_iam_policy_document.log_dynamodb_actions_policy.json
}

resource "aws_iam_policy" "obtain_insight_report_policy" {
  name        = "policy-get-insight-report"
  description = "Custom policy to be able to obtain the insight report"
  policy      = data.aws_iam_policy_document.get_insight_report_policy.json
}

resource "aws_iam_policy" "passing_role_policy" {
  name        = "policy-pass-role"
  description = "Custom policy to be able to pass the role to a service"
  policy      = data.aws_iam_policy_document.pass_role_policy.json
}

resource "aws_iam_policy" "creating_service_role_linked_role_policy" {
  name        = "policy-create-service-linked-role"
  description = "Custom policy to create the service linked role"
  policy      = data.aws_iam_policy_document.create_service_linked_role_policy.json
}

resource "aws_iam_role_policy_attachment" "logging_dynamodb_actions_attach" {
  role       = aws_iam_role.updateVisitorCounter-role-h7zmdlm8.name
  policy_arn = aws_iam_policy.logging_dynamodb_actions_policy.arn
}

resource "aws_iam_role_policy_attachment" "obtain_insight_report_attach" {
  role       = aws_iam_role.updateVisitorCounter-role-h7zmdlm8.name
  policy_arn = aws_iam_policy.obtain_insight_report_policy.arn
}

resource "aws_iam_role_policy_attachment" "passing_role_attach" {
  role       = aws_iam_role.updateVisitorCounter-role-h7zmdlm8.name
  policy_arn = aws_iam_policy.passing_role_policy.arn
}

resource "aws_iam_role_policy_attachment" "creating_service_role_linked_role_attach" {
  role       = aws_iam_role.updateVisitorCounter-role-h7zmdlm8.name
  policy_arn = aws_iam_policy.creating_service_role_linked_role_policy.arn
}

# checkov:skip=CKV_AWS_272:Do not need code signing for this lambda function
resource "aws_lambda_function" "updateVisitorCounter_lambda" {
  filename      = data.archive_file.lambda_archive.output_path
  function_name = "updateVisitorCounter_lambda"
  role          = aws_iam_role.updateVisitorCounter-role-h7zmdlm8.arn

  source_code_hash = data.archive_file.lambda_archive.output_base64sha256

  runtime = "python3.12"
  handler = "lambda_function.lambda_handler"
}

resource "aws_cloudwatch_log_group" "updateVisitorCounter_lambda" {
  name = "/aws/lambda/${aws_lambda_function.updateVisitorCounter_lambda.function_name}"

  retention_in_days = 90
}
