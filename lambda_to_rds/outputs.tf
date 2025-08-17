output "lambda_to_rds_sg_id" {
  value = aws_security_group.lambda_to_rds_sg.id
}

output "function_arn" {
  value = aws_lambda_function.lambda_to_rds.arn
}

