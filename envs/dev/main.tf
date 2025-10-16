# Development Environment Configuration


module "vpc" {
  source = "../../modules/vpc"

  env_prefix           = "dev"
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
  availability_zones   = ["us-east-1a", "us-east-1b"]
}

module "cognito" {
  source = "../../modules/cognito"

  env_prefix         = "dev"
  user_pool_name     = "dev-strapi-user-pool"
  app_client_name    = "dev-strapi-cms-userpool"
  enable_lambda_triggers = false
}

module "rds" {
  source = "../../modules/rds"

  env_prefix         = "dev"
  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = module.vpc.vpc_cidr
  private_subnet_ids = module.vpc.private_subnet_ids

  # Credentials should be provided via terraform.tfvars or environment variables
  # db_username and db_password will be read from:
  # 1. terraform.tfvars (not committed to git)
  # 2. Environment variables: TF_VAR_db_username and TF_VAR_db_password
  # 3. Command line: -var="db_username=xxx" -var="db_password=xxx"
  db_username     = var.db_username
  db_password     = var.db_password
  database_name   = "cas_cms"
  
  # Aurora Serverless v2 configuration
  min_capacity    = 0.5
  max_capacity    = 1.0
  
  # Development settings
  skip_final_snapshot  = true
  deletion_protection  = false
  publicly_accessible  = false
  
  # Optional: Create reader instance
  create_reader_instance = false
}

# Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "cognito_user_pool_id" {
  description = "The ID of the Cognito User Pool"
  value       = module.cognito.user_pool_id
}

output "cognito_app_client_id" {
  description = "The ID of the Cognito App Client"
  value       = module.cognito.app_client_id
}

output "cognito_user_pool_arn" {
  description = "The ARN of the Cognito User Pool"
  value       = module.cognito.user_pool_arn
}

# RDS Outputs
output "rds_cluster_endpoint" {
  description = "The RDS cluster endpoint (writer)"
  value       = module.rds.cluster_endpoint
}

output "rds_reader_endpoint" {
  description = "The RDS cluster reader endpoint"
  value       = module.rds.cluster_reader_endpoint
}

output "rds_database_name" {
  description = "The name of the database"
  value       = module.rds.database_name
}

output "rds_port" {
  description = "The port the database is listening on"
  value       = module.rds.cluster_port
}

output "rds_secrets_manager_arn" {
  description = "The ARN of the Secrets Manager secret containing DB credentials"
  value       = module.rds.secrets_manager_secret_arn
}

output "rds_secrets_manager_name" {
  description = "The name of the Secrets Manager secret"
  value       = module.rds.secrets_manager_secret_name
}
