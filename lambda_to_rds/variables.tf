variable "aws_region" {
  type = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

variable "vpc_id" {
  description = "The ID of the VPC where RDS will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of private subnet IDs for RDS"
  type        = list(string)
}

variable "lambda_sg_id" {
  description = "Security Group ID that allows Lambda to connect to RDS"
  type        = string
}

variable "db_address" {
  description = "Address for the RDS instance"
  type        = string
}

variable "db_name" {
  description = "Database name for the RDS instance"
  type        = string
}

variable "secret_arn" {
  description = "ARN of the RDS password secret in Secrets Manager"
  type        = string
}
