terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.38.0"
    }
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "allow_access_history" {
  name   = "${var.environment_name}-${var.stage}-policy"
  policy = data.aws_iam_policy_document.allow_access_from_owner_read.json
}

resource "aws_iot_policy" "mqtt_policy" {
  name = "${var.environment_name}-${var.stage}-mqtt-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "iot:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_s3_bucket" "history" {
  bucket = "${var.environment_name}-${var.stage}-data-bucket"

  tags = {
    Name        = "${var.environment_name}-${var.stage}-history"
    Environment = var.stage
  }
}

resource "aws_s3_bucket" "iot" {
  bucket = "${var.environment_name}-${var.stage}-iot-bucket"

  tags = {
    Name        = "${var.environment_name}-${var.stage}-iot"
    Environment = var.stage
  }
}

resource "aws_dynamodb_table" "babyfoot_matches_table" {
  name           = "${var.environment_name}-${var.stage}-matches-table"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "statut"
    type = "S"
  }

  global_secondary_index {
    name            = "StatutIndex"
    hash_key        = "statut"
    write_capacity  = 5
    read_capacity   = 5
    projection_type = "ALL"
  }
}

resource "aws_lambda_function" "on_stack_deploy" {
  filename      = "onStackDeploy.zip"
  function_name = "on-stack-deploy"
  handler       = "on-stack-deploy.handler"
  runtime       = "nodejs14.x"
  role          = aws_iam_role.iam_for_lambda.arn
  environment {
    variables = {
      MQTT_POLICY = aws_iot_policy.mqtt_policy.id
      BUCKET_NAME = aws_s3_bucket.iot.id
    }
  }
  depends_on = [
    aws_iot_policy.mqtt_policy,
    aws_s3_bucket.iot
  ]
}

resource "aws_lambda_function" "on_stack_delete" {
  filename      = "onStackDelete.zip"
  function_name = "on-stack-delete"
  handler       = "on-stack-delete.handler"
  runtime       = "nodejs14.x"
  role          = aws_iam_role.iam_for_lambda.arn
  environment {
    variables = {
      MQTT_POLICY = aws_iot_policy.mqtt_policy.id
      BUCKET_NAME = aws_s3_bucket.iot.id
    }
  }
  depends_on = [
    aws_iot_policy.mqtt_policy,
    aws_s3_bucket.iot
  ]
}