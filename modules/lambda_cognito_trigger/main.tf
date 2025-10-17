# IAM Role for Lambda Execution
resource "aws_iam_role" "lambda_execution" {
  name = "${var.environment}-cognito-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-cognito-lambda-execution-role"
      Environment = var.environment
    }
  )
}

# IAM Policy for Lambda to write logs and access Cognito
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.environment}-cognito-lambda-policy"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "cognito-idp:AdminGetUser",
          "cognito-idp:AdminUpdateUserAttributes",
          "cognito-idp:AdminCreateUser"
        ]
        Resource = var.cognito_user_pool_arn
      },
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

# Create zip files for Lambda functions
data "archive_file" "create_auth_challenge" {
  type        = "zip"
  source_dir  = "${path.module}/src/createAuthChallenge"
  output_path = "${path.module}/build/createAuthChallenge.zip"
}

data "archive_file" "define_auth_challenge" {
  type        = "zip"
  source_dir  = "${path.module}/src/defineAuthChallenge"
  output_path = "${path.module}/build/defineAuthChallenge.zip"
}

data "archive_file" "verify_auth_challenge" {
  type        = "zip"
  source_dir  = "${path.module}/src/verifyAuthChallenge"
  output_path = "${path.module}/build/verifyAuthChallenge.zip"
}

# CloudWatch Log Groups for Lambda functions (create before Lambda)
resource "aws_cloudwatch_log_group" "create_auth_challenge" {
  name              = "/aws/lambda/createAuthChallenge"
  retention_in_days = 7

  tags = merge(
    var.tags,
    {
      Name        = "createAuthChallenge-logs"
      Environment = var.environment
    }
  )
}

resource "aws_cloudwatch_log_group" "define_auth_challenge" {
  name              = "/aws/lambda/defineAuthChallenge"
  retention_in_days = 7

  tags = merge(
    var.tags,
    {
      Name        = "defineAuthChallenge-logs"
      Environment = var.environment
    }
  )
}

resource "aws_cloudwatch_log_group" "verify_auth_challenge" {
  name              = "/aws/lambda/verifyAuthChallenge"
  retention_in_days = 7

  tags = merge(
    var.tags,
    {
      Name        = "verifyAuthChallenge-logs"
      Environment = var.environment
    }
  )
}

# Lambda Function: Create Auth Challenge
resource "aws_lambda_function" "create_auth_challenge" {
  filename         = data.archive_file.create_auth_challenge.output_path
  function_name    = "createAuthChallenge"
  role             = aws_iam_role.lambda_execution.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.create_auth_challenge.output_base64sha256
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size

  environment {
    variables = {
      USER_POOL_ID = var.cognito_user_pool_id
      ENVIRONMENT  = var.environment
    }
  }

  tracing_config {
    mode = "Active"
  }

  tags = merge(
    var.tags,
    {
      Name        = "createAuthChallenge"
      Environment = var.environment
      Type        = "CognitoTrigger"
    }
  )

  depends_on = [
    aws_cloudwatch_log_group.create_auth_challenge,
    aws_iam_role_policy.lambda_policy
  ]
}

# Lambda Function: Define Auth Challenge
resource "aws_lambda_function" "define_auth_challenge" {
  filename         = data.archive_file.define_auth_challenge.output_path
  function_name    = "defineAuthChallenge"
  role             = aws_iam_role.lambda_execution.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.define_auth_challenge.output_base64sha256
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size

  environment {
    variables = {
      USER_POOL_ID = var.cognito_user_pool_id
      ENVIRONMENT  = var.environment
    }
  }

  tracing_config {
    mode = "Active"
  }

  tags = merge(
    var.tags,
    {
      Name        = "defineAuthChallenge"
      Environment = var.environment
      Type        = "CognitoTrigger"
    }
  )

  depends_on = [
    aws_cloudwatch_log_group.define_auth_challenge,
    aws_iam_role_policy.lambda_policy
  ]
}

# Lambda Function: Verify Auth Challenge
resource "aws_lambda_function" "verify_auth_challenge" {
  filename         = data.archive_file.verify_auth_challenge.output_path
  function_name    = "verifyAuthChallenge"
  role             = aws_iam_role.lambda_execution.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.verify_auth_challenge.output_base64sha256
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size

  layers = var.enable_jose_layer && length(aws_lambda_layer_version.jose_layer) > 0 ? [aws_lambda_layer_version.jose_layer[0].arn] : []

  environment {
    variables = {
      USER_POOL_ID        = var.cognito_user_pool_id
      ENVIRONMENT         = var.environment
      OTP_SECRET          = var.otp_secret
      GOOGLE_AUDIENCE     = var.google_audience
      FACEBOOK_APP_ID     = var.facebook_app_id
      FACEBOOK_APP_SECRET = var.facebook_app_secret
      APPLE_AUDIENCE      = var.apple_audience
    }
  }

  tracing_config {
    mode = "Active"
  }

  tags = merge(
    var.tags,
    {
      Name        = "verifyAuthChallenge"
      Environment = var.environment
      Type        = "CognitoTrigger"
    }
  )

  depends_on = [
    aws_cloudwatch_log_group.verify_auth_challenge,
    aws_iam_role_policy.lambda_policy
  ]
}

# NOTE: Lambda Permissions are now managed in the Cognito module
# to avoid circular dependencies. Cognito creates the permissions
# when it attaches the Lambda triggers.

# Lambda Layer for jose library (JWT verification for social login)
resource "aws_lambda_layer_version" "jose_layer" {
  count               = var.enable_jose_layer ? 1 : 0
  layer_name          = "jose-layer"
  compatible_runtimes = ["nodejs22.x", "nodejs20.x"]

  filename         = "${path.module}/jose-layer.zip"
  source_code_hash = fileexists("${path.module}/jose-layer.zip") ? filebase64sha256("${path.module}/jose-layer.zip") : null

  description = "Jose library for JWT verification (social login)"
}
