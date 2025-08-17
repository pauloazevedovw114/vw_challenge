resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Allow DB access from Lambda SG"
  vpc_id      = var.vpc_id

  ingress {
    from_port                = 5432
    to_port                  = 5432
    protocol                 = "tcp"
    security_groups          = [var.lambda_to_rds_sg_id, var.lambda_s3_sg_id]  # allow from Lambdas SG
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name               = "rds-subnet-group"
  subnet_ids         = var.private_subnet_ids
}

resource "random_password" "rds_password" {
  length  = 16
  special = true
}

resource "random_password" "api_token" {
  length  = 16
  special = true
}

resource "aws_db_instance" "vw-challenge-events" {
  identifier        = "vwdb"
  engine            = "postgres"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  username          = "vwadmin"
  password          = random_password.rds_password.result
  db_name           = "vwevents"
  skip_final_snapshot = true
  publicly_accessible = false
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  
  tags = merge(
    var.tags
  )
}

#resource "null_resource" "init_db" {
#  depends_on = [aws_db_instance.vw-challenge-events]
#
#  provisioner "local-exec" {
#    environment = {
#      PGPASSWORD = random_password.rds_password.result
#    }
#    command = <<EOT
#    psql -h ${aws_db_instance.vw-challenge-events.address} -U vwadmin -d vwevents -c '
#    CREATE TABLE IF NOT EXISTS events (
#      id SERIAL PRIMARY KEY,
#      event_type VARCHAR(50) NOT NULL,
#      timestamp TIMESTAMP NOT NULL
#    );
#    '
#    EOT
#      }
#}

resource "aws_secretsmanager_secret" "rds_apigw_secret" {
  name = "vw-challenge/secrets"
  description = "Password for the RDS instance and API GW Token"
}

resource "aws_secretsmanager_secret_version" "rds_apigw_secret_version" {
  secret_id     = aws_secretsmanager_secret.rds_apigw_secret.id
  secret_string = jsonencode({
    username = "vwadmin"
    password = random_password.rds_password.result
    token = random_password.api_token.result
  })
}

#resource "aws_vpc_endpoint" "secretsmanager" {
#  vpc_id            = var.vpc_id
#  service_name      = "com.amazonaws.${var.aws_region}.secretsmanager"
#  vpc_endpoint_type = "Interface"
#  subnet_ids        = var.subnet_ids
#
#  security_group_ids = [var.lambda_sg_id]
#
#  private_dns_enabled = true
#}
#
#resource "aws_security_group" "vpce_sg" {
#  name        = "vpce_sg"
#  description = "Allow Lambda to connect to Secrets Manager VPC endpoint"
#  vpc_id      = var.vpc_id
#
#  ingress {
#    protocol    = "tcp"
#    from_port   = 443
#    to_port     = 443
#  }
#
#  egress {
#    from_port   = 0
#    to_port     = 0
#    protocol    = "-1"
#    cidr_blocks = ["0.0.0.0/0"]
#  }
#}
#
#
#resource "aws_security_group_rule" "allow_lambda_to_vpce" {
#  type                      = "ingress"
#  from_port                 = 443
#  to_port                   = 443
#  protocol                  = "tcp"
#  security_group_id         = aws_security_group.vpce_sg.id        # endpoint SG
#  source_security_group_id  = var.lambda_sg_id                    # Lambda SG
#  description               = "Allow Lambda to access SecretsManager endpoint"
#}
#