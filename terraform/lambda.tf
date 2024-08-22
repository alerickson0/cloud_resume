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

data "archive_file" "lambda_archive" {
  type        = "zip"
  source_file = "${path.module}/back-end/lambda/lambda_function.py"
  output_path = "${path.module}/back-end/lambda/updateVisitorCounter_lambda.zip"
}

resource "aws_iam_role" "updateVisitorCounter-role-h7zmdlm8" {
  name                = "update_dd_table_role"
  assume_role_policy  = data.aws_iam_policy_document.instance_assume_role_policy.json
  managed_policy_arns = [aws_iam_policy.policy_one.arn, aws_iam_policy.policy_two.arn]
}

resource "aws_iam_policy" "policy_one" {
  name = "policy-2546555"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "logs:CreateLogGroup",
        "Resource" : "arn:aws:logs:${local.current_region}:${local.account_id}:*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : [
          "arn:aws:logs:${local.current_region}:${local.account_id}:log-group:/aws/lambda/updateVisitorCounter_lambda:*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "policy_two" {
  name = "policy-4097236"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
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
        ],
        "Effect" : "Allow",
        "Resource" : "arn:aws:dynamodb:${local.current_region}:${local.account_id}:table/visitor_counter_count"
      },
      {
        "Action" : "cloudwatch:GetInsightRuleReport",
        "Effect" : "Allow",
        "Resource" : "arn:aws:cloudwatch:*:*:insight-rule/DynamoDBContributorInsights*"
      },
      {
        "Action" : [
          "iam:PassRole"
        ],
        "Effect" : "Allow",
        "Resource" : "*",
        "Condition" : {
          "StringLike" : {
            "iam:PassedToService" : [
              "application-autoscaling.amazonaws.com",
              "application-autoscaling.amazonaws.com.cn",
              "dax.amazonaws.com"
            ]
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "iam:CreateServiceLinkedRole"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : {
            "iam:AWSServiceName" : [
              "replication.dynamodb.amazonaws.com",
              "dax.amazonaws.com",
              "dynamodb.application-autoscaling.amazonaws.com",
              "contributorinsights.dynamodb.amazonaws.com",
              "kinesisreplication.dynamodb.amazonaws.com"
            ]
          }
        }
      }
    ]
  })
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
