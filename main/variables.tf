variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-central-1"
}

variable "tags" {
  type        = map(string)
  description = "Default tags to apply to all resources"
  default = {
    Environment = "dev"
    Project     = "vw-challenge"
  }
}

