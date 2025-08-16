resource "aws_security_group" "lambda_s3_sg" {
  name        = "lambda-s3-sg"
  description = "Security group for Lambda"
  vpc_id      = var.vpc_id

  # Allow all outbound (for Secrets Manager / RDS)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "lambda_s3" {
  name = "lambda_s3_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Effect = "Allow",
      Sid    = ""
    }]
  })
}

resource "aws_iam_role_policy" "lambda_vpc_access" {
  name = "LambdaVPCAccess"
  role = aws_iam_role.lambda_s3.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        Resource = "arn:aws:s3:::vwchallengebucket/*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:ListBucket"
        ],
        Resource = "arn:aws:s3:::vwchallengebucket"
      }
    ]
  })
}

resource "null_resource" "pip_install" {
  provisioner "local-exec" {
    command = <<EOT
      rm -rf ${path.module}/lambda_build
      mkdir -p ${path.module}/lambda_build
      pip install -r ${path.module}/requirements.txt -t ${path.module}/lambda_build/
      cp ${path.module}/*.py  ${path.module}/lambda_build/
    EOT
  }

  triggers = {
    always_run = timestamp()
  }
}#

data "archive_file" "lambda_package" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_build"
  output_path = "${path.module}/lambda.zip"

  depends_on = [
    null_resource.pip_install
  ]
}

resource "aws_lambda_function" "lambda_s3" {
  function_name = "lambda_s3"
  role          = aws_iam_role.lambda_s3.arn
  handler       = "handler.handler"
  runtime       = "python3.11"
  filename      = data.archive_file.lambda_package.output_path
  timeout = 10

  environment {
    variables = {
      DB_HOST     = var.db_address
      DB_NAME     = var.db_name
      DB_PORT     = "5432"
      SECRET_ARN  = var.secret_arn
    }
  }

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [var.lambda_s3_sg_id]
  }

  tags = merge(
    var.tags
  )
}

resource "aws_cloudwatch_event_rule" "every_sunday" {
  name                = "run-lambda-every-sunday"
  schedule_expression = "cron(0 12 ? * 1 *)"  # every Sunday at 12:00 UTC
  description         = "Triggers Lambda every Sunday at noon UTC"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.every_sunday.name
  target_id = "lambda-s3-sunday-task"
  arn       = aws_lambda_function.lambda_s3.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_s3.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_sunday.arn
}