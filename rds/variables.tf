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

variable "private_subnet_ids" {
  description = "List of private subnet IDs for RDS"
  type        = list(string)
}

variable "lambda_to_rds_sg_id" {
  description = "Security group ID for Lambda to RDS access"
  type        = string
}

variable "lambda_s3_sg_id" {
  description = "Security group ID for Lambda to S3 access"
  type        = string
}