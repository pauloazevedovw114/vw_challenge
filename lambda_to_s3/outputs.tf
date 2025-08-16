output "lambda_s3_sg_id" {
  value = aws_security_group.lambda_s3_sg.id
}

output "function_arn" {
  value = aws_lambda_function.lambda_s3.arn
  description = "ARN of the Lambda function"
}

