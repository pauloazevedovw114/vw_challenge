output "db_address" {
  value = aws_db_instance.vw-challenge-events.address
}

output "secret_arn" {
  value = aws_secretsmanager_secret.rds_apigw_secret.arn
}