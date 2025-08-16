resource "aws_security_group" "lambda_sg" {
  name        = "lambda-sg"
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

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

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
  role = aws_iam_role.lambda_exec.id

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
      }
    ]
  })
}

#resource "aws_iam_policy" "terraform_lambda_layer_access" {
#  name        = "TerraformLambdaLayerAccess"
#  description = "Allow terraform-user to get lambda layer version for psycopg2 layer"
#  
#  policy = jsonencode({
#    Version = "2012-10-17",
#    Statement = [{
#      Effect = "Allow",
#      Action = "lambda:GetLayerVersion",
#      Resource = "arn:aws:lambda:eu-central-1:934744453463:layer:psycopg2-py311:1"
#    }]
#  })
#}
#
#resource "aws_iam_user_policy_attachment" "attach_layer_access" {
#  user       = "terraform-user"  # your exact terraform user name
#  policy_arn = aws_iam_policy.terraform_lambda_layer_access.arn
#}

resource "null_resource" "pip_install" {
  provisioner "local-exec" {
    command = <<EOT
      rm -rf ${path.module}/lambda_build
      mkdir -p ${path.module}/lambda_build
      pip install -r ${path.module}/requirements.txt -t ${path.module}/lambda_build/
      cp ${path.module}/*.py  ${path.module}/lambda_build/
    EOT
  }

  #triggers = {
  #  always_run = timestamp()
  #}
}#

data "archive_file" "lambda_package" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_build"
  output_path = "${path.module}/lambda.zip"

  depends_on = [
    null_resource.pip_install
  ]
}

resource "aws_lambda_function" "event_lambda" {

  #layers = [
  #  "arn:aws:lambda:eu-central-1:934744453463:layer:psycopg2-py311:1"
  #]  
  function_name = "event_lambda"
  role          = aws_iam_role.lambda_exec.arn
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
    security_group_ids = [var.lambda_sg_id]
  }

  tags = merge(
    var.tags
  )
}


