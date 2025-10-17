output "create_auth_challenge_function_arn" {
  description = "ARN of the Create Auth Challenge Lambda function"
  value       = aws_lambda_function.create_auth_challenge.arn
}

output "create_auth_challenge_function_name" {
  description = "Name of the Create Auth Challenge Lambda function"
  value       = aws_lambda_function.create_auth_challenge.function_name
}

output "define_auth_challenge_function_arn" {
  description = "ARN of the Define Auth Challenge Lambda function"
  value       = aws_lambda_function.define_auth_challenge.arn
}

output "define_auth_challenge_function_name" {
  description = "Name of the Define Auth Challenge Lambda function"
  value       = aws_lambda_function.define_auth_challenge.function_name
}

output "verify_auth_challenge_function_arn" {
  description = "ARN of the Verify Auth Challenge Lambda function"
  value       = aws_lambda_function.verify_auth_challenge.arn
}

output "verify_auth_challenge_function_name" {
  description = "Name of the Verify Auth Challenge Lambda function"
  value       = aws_lambda_function.verify_auth_challenge.function_name
}

output "lambda_role_arn" {
  description = "ARN of the IAM role used by Lambda functions"
  value       = aws_iam_role.lambda_execution.arn
}
