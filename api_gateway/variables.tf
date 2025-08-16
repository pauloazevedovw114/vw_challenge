variable "aws_region" {
  type = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}


variable "lambda_function_arn" {
  type = string
}

variable "domain_name" {
  default = "api.vwchallenge.com"
}

variable "hosted_zone_name" {
  default = "vwchallenge.com."
}