module "networking" {
  source      = "../networking"
  aws_region  = var.aws_region
  tags        = var.tags
}

module "rds" {
  source               = "../rds"
  aws_region           = var.aws_region
  tags                 = var.tags
  vpc_id               = module.networking.vpc_id
  subnet_ids           = module.networking.private_subnet_ids
  lambda_sg_id         = module.lambda_to_rds.lambda_sg_id
  lambda_s3_sg_id      = module.lambda_to_s3.lambda_s3_sg_id
  
}

module "lambda_to_rds" {
  source               = "../lambda_to_rds"
  aws_region           = var.aws_region
  tags                 = var.tags  
  vpc_id               = module.networking.vpc_id
  subnet_ids           = module.networking.private_subnet_ids
  lambda_sg_id         = module.lambda_to_rds.lambda_sg_id
  db_address           = module.rds.db_address
  db_name              = "vwevents"
  secret_arn           = module.rds.db_secret_arn
}

module "api_gateway" {
  source              = "../api_gateway"
  aws_region          = var.aws_region
  tags                = var.tags    
  lambda_function_arn = module.lambda_to_rds.function_arn
  
}

module "s3" {
  source              = "../s3"
  aws_region          = var.aws_region
  tags                = var.tags
}

module "lambda_to_s3" {
  source               = "../lambda_to_s3"
  aws_region           = var.aws_region
  tags                 = var.tags  
  vpc_id               = module.networking.vpc_id
  subnet_ids           = module.networking.private_subnet_ids
  lambda_s3_sg_id      = module.lambda_to_s3.lambda_s3_sg_id
  db_address           = module.rds.db_address
  db_name              = "vwevents"
  secret_arn           = module.rds.db_secret_arn
}