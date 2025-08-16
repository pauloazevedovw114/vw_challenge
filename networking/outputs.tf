output "vpc_id" {
  value = aws_vpc.main.id
}

output "private_subnet_ids" {
  value = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
}

#output "lambda_sg_id" {
#  value = aws_security_group.lambda_to_rds.id
#}
