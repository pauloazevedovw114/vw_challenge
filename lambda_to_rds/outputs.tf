output "lambda_sg_id" {
  value = aws_security_group.lambda_sg.id
}

output "function_arn" {
  value = aws_lambda_function.event_lambda.arn
  description = "ARN of the Lambda function"
}

