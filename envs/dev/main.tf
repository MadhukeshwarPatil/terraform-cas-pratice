# Development Environment Configuration


module "vpc" {
  source = "../../modules/vpc"

  env_prefix           = "dev"
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
  availability_zones   = ["us-east-1a", "us-east-1b"]
}

# Step 1: Cognito User Pool (created first WITHOUT triggers)
module "cognito" {
  source = "../../modules/cognito"

  env_prefix                         = "dev"
  user_pool_name                     = "dev-strapi-user-pool"
  app_client_name                    = "dev-strapi-cms-userpool"
  
  # Initially created without triggers
  enable_lambda_triggers             = false
  create_auth_challenge_lambda_arn   = null
  define_auth_challenge_lambda_arn   = null
  verify_auth_challenge_lambda_arn   = null
}

# Step 2: Lambda Functions (created after Cognito exists)
module "lambda_cognito_trigger" {
  source = "../../modules/lambda_cognito_trigger"

  environment            = "dev"
  cognito_user_pool_arn  = module.cognito.user_pool_arn
  cognito_user_pool_id   = module.cognito.user_pool_id
  
  # OTP Secret (should be a long random hex string - store in terraform.tfvars)
  otp_secret = var.otp_secret
  
  # Optional: Social login configuration (uncomment and configure if needed)
  # google_audience      = var.google_audience
  # facebook_app_id      = var.facebook_app_id
  # facebook_app_secret  = var.facebook_app_secret
  # apple_audience       = var.apple_audience
  
  # Enable jose layer for social login support
  enable_jose_layer = true
  
  depends_on = [module.cognito]
}

# Step 3: Attach Lambda triggers to Cognito (after Lambda functions exist)
resource "null_resource" "attach_lambda_triggers" {
  # This resource attaches Lambda triggers to Cognito User Pool
  # Triggers when Lambda ARNs change
  triggers = {
    cognito_user_pool_id             = module.cognito.user_pool_id
    create_auth_challenge_arn        = module.lambda_cognito_trigger.create_auth_challenge_function_arn
    define_auth_challenge_arn        = module.lambda_cognito_trigger.define_auth_challenge_function_arn
    verify_auth_challenge_arn        = module.lambda_cognito_trigger.verify_auth_challenge_function_arn
  }

  # Attach triggers after Lambda functions are created
  provisioner "local-exec" {
    command = <<-EOT
      aws cognito-idp update-user-pool \
        --user-pool-id ${module.cognito.user_pool_id} \
        --lambda-config \
          CreateAuthChallenge=${module.lambda_cognito_trigger.create_auth_challenge_function_arn},\
DefineAuthChallenge=${module.lambda_cognito_trigger.define_auth_challenge_function_arn},\
VerifyAuthChallengeResponse=${module.lambda_cognito_trigger.verify_auth_challenge_function_arn}
    EOT
  }

  # Detach triggers before destroying Lambda functions
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      aws cognito-idp update-user-pool \
        --user-pool-id ${self.triggers.cognito_user_pool_id} \
        --lambda-config '{}'
    EOT
  }

  depends_on = [
    module.cognito,
    module.lambda_cognito_trigger
  ]
}

# Lambda Permissions for Cognito to invoke the functions
resource "aws_lambda_permission" "allow_cognito_create_auth_challenge" {
  statement_id  = "AllowCognitoInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_cognito_trigger.create_auth_challenge_function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = module.cognito.user_pool_arn
}

resource "aws_lambda_permission" "allow_cognito_define_auth_challenge" {
  statement_id  = "AllowCognitoInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_cognito_trigger.define_auth_challenge_function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = module.cognito.user_pool_arn
}

resource "aws_lambda_permission" "allow_cognito_verify_auth_challenge" {
  statement_id  = "AllowCognitoInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_cognito_trigger.verify_auth_challenge_function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = module.cognito.user_pool_arn
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
  database_name   = "auth_cms"
  
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

# Lambda Outputs
output "lambda_create_auth_challenge_arn" {
  description = "ARN of the Create Auth Challenge Lambda function"
  value       = module.lambda_cognito_trigger.create_auth_challenge_function_arn
}

output "lambda_define_auth_challenge_arn" {
  description = "ARN of the Define Auth Challenge Lambda function"
  value       = module.lambda_cognito_trigger.define_auth_challenge_function_arn
}

output "lambda_verify_auth_challenge_arn" {
  description = "ARN of the Verify Auth Challenge Lambda function"
  value       = module.lambda_cognito_trigger.verify_auth_challenge_function_arn
}
