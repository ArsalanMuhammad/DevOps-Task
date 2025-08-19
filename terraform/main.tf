terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.55"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.5"
    }
  }
}

provider "aws" {
  region = var.region
}

########################
# ===== OUTPUTS =======
########################
output "alb_dns_name" {
  value       = aws_lb.app.dns_name
  description = "Public ALB URL for the Frontend"
}

output "api_endpoint" {
  value       = aws_apigatewayv2_api.http_api.api_endpoint
  description = "HTTP API endpoint invoking the Lambda backend"
}

output "rds_endpoint" {
  value       = aws_db_instance.mysql.address
  description = "RDS MySQL endpoint (private)"
}

output "ecr_repo_url" {
  value       = aws_ecr_repository.frontend.repository_url
  description = "Push your frontend image here"
}
