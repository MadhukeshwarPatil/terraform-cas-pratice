# Cognito Module - Main Configuration
# This module creates AWS Cognito User Pool with custom attributes

# Cognito User Pool
resource "aws_cognito_user_pool" "main" {
  name = "${var.env_prefix}-user-pool"

  # Username attributes - allow sign in with preferred_username, phone_number, email
  alias_attributes = ["preferred_username", "phone_number", "email"]

  # Lambda triggers configuration
  # Only attach triggers if all Lambda ARNs are provided
  dynamic "lambda_config" {
    for_each = var.create_auth_challenge_lambda_arn != null && var.define_auth_challenge_lambda_arn != null && var.verify_auth_challenge_lambda_arn != null ? [1] : []
    content {
      create_auth_challenge          = var.create_auth_challenge_lambda_arn
      define_auth_challenge          = var.define_auth_challenge_lambda_arn
      verify_auth_challenge_response = var.verify_auth_challenge_lambda_arn
    }
  }

  # Auto-verified attributes
  auto_verified_attributes = []

  # Password policy
  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }

  # Required standard attributes
  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
  }

  schema {
    name                = "phone_number"
    attribute_data_type = "String"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
  }

  schema {
    name                = "preferred_username"
    attribute_data_type = "String"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
  }

  # Custom attributes
  schema {
    name                = "custom:dob"
    attribute_data_type = "String"
    mutable             = true

    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
  }

  schema {
    name                = "custom:locale"
    attribute_data_type = "String"
    mutable             = true

    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
  }

  schema {
    name                = "custom:otp"
    attribute_data_type = "Number"
    mutable             = true

    number_attribute_constraints {
      min_value = 0
      max_value = 2147483647
    }
  }

  schema {
    name                = "custom:otp_attempts"
    attribute_data_type = "Number"
    mutable             = true

    number_attribute_constraints {
      min_value = 0
      max_value = 2147483647
    }
  }

  schema {
    name                = "custom:otp_exp"
    attribute_data_type = "Number"
    mutable             = true

    number_attribute_constraints {
      min_value = 0
      max_value = 2147483647
    }
  }

  schema {
    name                = "custom:otp_hash"
    attribute_data_type = "String"
    mutable             = true

    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
  }

  schema {
    name                = "custom:otp_sid"
    attribute_data_type = "String"
    mutable             = true

    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
  }

  # Email configuration
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  # Account recovery setting
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
    recovery_mechanism {
      name     = "verified_phone_number"
      priority = 2
    }
  }

  # User pool add-ons
  user_pool_add_ons {
    advanced_security_mode = "OFF"
  }

  # MFA configuration
  mfa_configuration = "OFF"

  # Device configuration
  device_configuration {
    challenge_required_on_new_device      = false
    device_only_remembered_on_user_prompt = false
  }

  tags = {
    Name        = "${var.env_prefix}-user-pool"
    Environment = var.env_prefix
  }
}

# User Pool Client (App Client)
resource "aws_cognito_user_pool_client" "main" {
  name         = "${var.env_prefix}-cms-userpool"
  user_pool_id = aws_cognito_user_pool.main.id

  # Token validity
  refresh_token_validity = 3600 # 3600 days
  access_token_validity  = 1    # 1 day
  id_token_validity      = 1    # 1 day

  token_validity_units {
    refresh_token = "days"
    access_token  = "days"
    id_token      = "days"
  }

  # Auth flows
  explicit_auth_flows = [
    "ALLOW_CUSTOM_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]

  # Prevent user existence errors
  prevent_user_existence_errors = "ENABLED"

  # Enable token revocation
  enable_token_revocation = true

  # Auth session validity
  auth_session_validity = 15 # 15 minutes
}
