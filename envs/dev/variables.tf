# Development Environment Variables

variable "db_username" {
  description = "Database master username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "otp_secret" {
  description = "Secret key for OTP HMAC generation (long random hex string, 128+ characters)"
  type        = string
  sensitive   = true
}

# Optional social login variables (uncomment if needed)
# variable "google_audience" {
#   description = "Google OAuth client ID"
#   type        = string
#   default     = ""
# }
# 
# variable "facebook_app_id" {
#   description = "Facebook App ID"
#   type        = string
#   default     = ""
# }
# 
# variable "facebook_app_secret" {
#   description = "Facebook App Secret"
#   type        = string
#   sensitive   = true
#   default     = ""
# }
# 
# variable "apple_audience" {
#   description = "Apple OAuth client ID"
#   type        = string
#   default     = ""
# }

