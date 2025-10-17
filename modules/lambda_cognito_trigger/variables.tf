variable "environment" {
  description = "Environment name (dev, qa, uat, prod)"
  type        = string
}

variable "cognito_user_pool_arn" {
  description = "ARN of the Cognito User Pool (optional - permissions can be managed separately)"
  type        = string
  default     = null
}

variable "cognito_user_pool_id" {
  description = "ID of the Cognito User Pool (can be empty during initial creation)"
  type        = string
  default     = ""
}

variable "lambda_runtime" {
  description = "Lambda runtime version"
  type        = string
  default     = "nodejs22.x"
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 3
}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 128
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "otp_secret" {
  description = "Secret key for OTP HMAC generation (should be a long random hex string)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "google_audience" {
  description = "Google OAuth client ID for social login"
  type        = string
  default     = ""
}

variable "facebook_app_id" {
  description = "Facebook App ID for social login"
  type        = string
  default     = ""
}

variable "facebook_app_secret" {
  description = "Facebook App Secret for social login"
  type        = string
  sensitive   = true
  default     = ""
}

variable "apple_audience" {
  description = "Apple OAuth client ID for social login"
  type        = string
  default     = ""
}

variable "enable_jose_layer" {
  description = "Enable Lambda Layer for jose library (required for social login)"
  type        = bool
  default     = true
}
