output "db_address" {
  value = aws_db_instance.vw-challenge-events.address
}

output "db_secret_arn" {
  value = aws_secretsmanager_secret.rds_password_secret.arn
}