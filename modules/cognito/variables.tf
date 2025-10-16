# Cognito Module - Input Variables

variable "env_prefix" {
  description = "Environment prefix (e.g., dev, qa, uat, prod)"
  type        = string
}

variable "ses_email_identity_arn" {
  description = "ARN of the SES email identity for sending emails"
  type        = string
  default     = null
}

variable "enable_lambda_triggers" {
  description = "Enable Lambda triggers for custom authentication"
  type        = bool
  default     = false
}

variable "create_auth_challenge_lambda_arn" {
  description = "ARN of the Lambda function for creating auth challenge"
  type        = string
  default     = null
}

variable "define_auth_challenge_lambda_arn" {
  description = "ARN of the Lambda function for defining auth challenge"
  type        = string
  default     = null
}

variable "verify_auth_challenge_lambda_arn" {
  description = "ARN of the Lambda function for verifying auth challenge response"
  type        = string
  default     = null
}

variable "user_pool_name" {
  description = "Custom name for the user pool (optional)"
  type        = string
  default     = null
}

variable "app_client_name" {
  description = "Custom name for the app client (optional)"
  type        = string
  default     = null
}
