# 🚀 Infrastructure for VW Challenge

This project uses **Terraform** to provision AWS infrastructure for the VW Challenge application.

---

## 📁 Project Structure

```
├── main/ # Main TF entrypoint
├── networking/ # VPC, subnets, route tables
├── rds/ # PostgreSQL DB setup (RDS)
├── lambda_to_rds/ # Lambda to insert event in RDS
├── lambda_to_s3/ # Lambda to count events and store in S3
├── api_gateway/ # API Gateway for lambda 'lambda_to_rds'
├── s3/ # S3 bucket for storing event count from lambda 'lambda_to_s3'
├── .github/workflows/ # GitHub Actions for CI/CD
└── README.md
```
---


## 🚀 Deploying Infrastructure (Locally)

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.3.0
- [aws-cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- Create user with IAM credentials and access to: Lambda, RDS, S3, API Gateway, VPC, Secrets Manager
- Run ```aws configure``` and you'll be prompted for aws_access_key_id and your aws_secret_access_key.

---

## 🔐 Secrets Setup

Set the following **GitHub secrets** in your repo:

| Secret Name              | Purpose                     |
|--------------------------|-----------------------------|
| `AWS_ACCESS_KEY_ID`      | AWS access key              |
| `AWS_SECRET_ACCESS_KEY`  | AWS secret key              |

---

## 🚀 Deploying Infrastructure (Locally)

```bash
cd main/
terraform init
terraform plan
terraform apply

---
## 🚦 Manual Deploy via GitHub Actions

Go to GitHub → Actions → Manual Terraform Apply → Run Workflow → Pick your branch → ✅ Done.

This will:

Run terraform plan

Wait for manual approval (if you configured environments)

Apply infra in AWS
---
## Test API

curl -X POST \
  https://<your-api-id>.execute-api.eu-central-1.amazonaws.com/data \
  -H "Content-Type: application/json" \
  -H "x-api-key: YOUR_API_KEY" \
  -d '{"event_type":"login","timestamp":"2025-08-16T16:00:00Z"}'
