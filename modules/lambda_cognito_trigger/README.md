# Lambda Cognito Trigger Module

This module creates AWS Lambda functions that serve as Cognito triggers for custom authentication flow using OTP (One-Time Password).

## Architecture

The module creates three Lambda functions that work together to implement a custom OTP-based authentication flow:

1. **Define Auth Challenge** - Determines which challenge to present to the user
2. **Create Auth Challenge** - Generates a 6-digit OTP and sends it to the user
3. **Verify Auth Challenge** - Validates the OTP provided by the user

## Features

- 🔐 **6-Digit OTP Generation**: Cryptographically secure random OTP generation
- ⏱️ **OTP Expiration**: 5-minute expiration window for security
- 🔒 **Hash Storage**: OTPs are hashed before storage for additional security
- 🚫 **Rate Limiting**: Maximum 3 attempts before authentication fails
- 📝 **CloudWatch Logging**: All Lambda functions log to CloudWatch for debugging
- 🎯 **Timing-Safe Comparison**: Prevents timing attacks during OTP verification

## Lambda Functions

### 1. Create Auth Challenge (`createAuthChallenge`)
**Purpose**: Generates and sends the OTP to the user

**Process**:
- Generates a random 6-digit OTP (100000-999999)
- Creates SHA-256 hash of the OTP
- Sets 5-minute expiration time
- Returns OTP in private challenge parameters
- Logs OTP to CloudWatch (for development - remove in production)

**TODO**: Integrate with SNS for SMS or SES for email delivery

### 2. Define Auth Challenge (`defineAuthChallenge`)
**Purpose**: Controls the authentication flow logic

**Process**:
- First attempt: Issues CUSTOM_CHALLENGE (OTP)
- On success: Issues authentication tokens
- On failure: Re-issues challenge (up to 3 attempts)
- After 3 failures: Fails authentication

### 3. Verify Auth Challenge (`verifyAuthChallenge`)
**Purpose**: Validates the user's OTP input

**Process**:
- Validates OTP format (6 digits)
- Checks OTP expiration
- Performs timing-safe comparison with expected OTP
- Returns success/failure result

## Usage

### Basic Usage

```hcl
module "lambda_cognito_trigger" {
  source = "../../modules/lambda_cognito_trigger"

  environment            = "dev"
  cognito_user_pool_arn  = module.cognito.user_pool_arn
  cognito_user_pool_id   = module.cognito.user_pool_id
  
  tags = {
    Environment = "dev"
    Project     = "MyProject"
  }
}
```

### Complete Integration with Cognito

Due to circular dependency limitations, the Lambda triggers must be attached to Cognito in a two-step process:

#### Step 1: Initial Deployment
```bash
# Deploy Cognito without Lambda triggers
cd envs/dev
terraform init
terraform apply
```

#### Step 2: Attach Lambda Triggers

After initial deployment, update the Cognito module to enable Lambda triggers:

```hcl
module "cognito" {
  source = "../../modules/cognito"

  env_prefix                         = "dev"
  enable_lambda_triggers             = true
  create_auth_challenge_lambda_arn   = module.lambda_cognito_trigger.create_auth_challenge_function_arn
  define_auth_challenge_lambda_arn   = module.lambda_cognito_trigger.define_auth_challenge_function_arn
  verify_auth_challenge_lambda_arn   = module.lambda_cognito_trigger.verify_auth_challenge_function_arn
}
```

Then run:
```bash
terraform apply
```

### Manual Attachment (Alternative)

You can also attach the Lambda triggers manually via AWS Console or CLI:

```bash
aws cognito-idp update-user-pool \
  --user-pool-id <USER_POOL_ID> \
  --lambda-config \
    CreateAuthChallenge=<CREATE_AUTH_CHALLENGE_ARN>,\
    DefineAuthChallenge=<DEFINE_AUTH_CHALLENGE_ARN>,\
    VerifyAuthChallengeResponse=<VERIFY_AUTH_CHALLENGE_ARN>
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment name (dev, qa, uat, prod) | `string` | n/a | yes |
| cognito_user_pool_arn | ARN of the Cognito User Pool | `string` | n/a | yes |
| cognito_user_pool_id | ID of the Cognito User Pool | `string` | n/a | yes |
| lambda_runtime | Lambda runtime version | `string` | `"nodejs20.x"` | no |
| lambda_timeout | Lambda function timeout in seconds | `number` | `30` | no |
| lambda_memory_size | Lambda function memory size in MB | `number` | `256` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| create_auth_challenge_function_arn | ARN of the Create Auth Challenge Lambda function |
| create_auth_challenge_function_name | Name of the Create Auth Challenge Lambda function |
| define_auth_challenge_function_arn | ARN of the Define Auth Challenge Lambda function |
| define_auth_challenge_function_name | Name of the Define Auth Challenge Lambda function |
| verify_auth_challenge_function_arn | ARN of the Verify Auth Challenge Lambda function |
| verify_auth_challenge_function_name | Name of the Verify Auth Challenge Lambda function |
| lambda_role_arn | ARN of the IAM role used by Lambda functions |

## Authentication Flow

```
1. User initiates sign-in (CUSTOM_AUTH flow)
   ↓
2. Define Auth Challenge: Issues CUSTOM_CHALLENGE
   ↓
3. Create Auth Challenge: Generates 6-digit OTP
   ↓
4. OTP sent to user (via SMS/Email - requires integration)
   ↓
5. User enters OTP
   ↓
6. Verify Auth Challenge: Validates OTP
   ↓
7. If valid: Define Auth Challenge issues tokens
   If invalid: Retry (up to 3 attempts)
```

## Testing the Authentication Flow

### Using AWS CLI

```bash
# Step 1: Initiate Auth
aws cognito-idp initiate-auth \
  --auth-flow CUSTOM_AUTH \
  --client-id <APP_CLIENT_ID> \
  --auth-parameters USERNAME=<username>

# Step 2: Respond to Auth Challenge (with OTP)
aws cognito-idp respond-to-auth-challenge \
  --client-id <APP_CLIENT_ID> \
  --challenge-name CUSTOM_CHALLENGE \
  --session <SESSION_FROM_STEP_1> \
  --challenge-responses USERNAME=<username>,ANSWER=<6-digit-otp>
```

### Using SDK (JavaScript/Node.js)

```javascript
const { CognitoIdentityProviderClient, InitiateAuthCommand, RespondToAuthChallengeCommand } = require("@aws-sdk/client-cognito-identity-provider");

const client = new CognitoIdentityProviderClient({ region: "us-east-1" });

// Step 1: Initiate auth
const initiateAuthResponse = await client.send(new InitiateAuthCommand({
  AuthFlow: "CUSTOM_AUTH",
  ClientId: "<APP_CLIENT_ID>",
  AuthParameters: {
    USERNAME: "<username>"
  }
}));

// Step 2: Submit OTP
const respondResponse = await client.send(new RespondToAuthChallengeCommand({
  ClientId: "<APP_CLIENT_ID>",
  ChallengeName: "CUSTOM_CHALLENGE",
  Session: initiateAuthResponse.Session,
  ChallengeResponses: {
    USERNAME: "<username>",
    ANSWER: "<6-digit-otp>"
  }
}));

console.log("Access Token:", respondResponse.AuthenticationResult.AccessToken);
```

## Production Considerations

### 1. OTP Delivery Integration

The current implementation logs OTP to CloudWatch. For production, integrate with:

**SMS via Amazon SNS**:
```javascript
const AWS = require('aws-sdk');
const sns = new AWS.SNS();

await sns.publish({
  Message: `Your verification code is: ${otp}`,
  PhoneNumber: phoneNumber
}).promise();
```

**Email via Amazon SES**:
```javascript
const AWS = require('aws-sdk');
const ses = new AWS.SES();

await ses.sendEmail({
  Source: 'noreply@yourdomain.com',
  Destination: { ToAddresses: [email] },
  Message: {
    Subject: { Data: 'Your Verification Code' },
    Body: { Text: { Data: `Your code is: ${otp}` } }
  }
}).promise();
```

### 2. Required IAM Permissions

Add to Lambda execution role:

**For SNS (SMS)**:
```json
{
  "Effect": "Allow",
  "Action": ["sns:Publish"],
  "Resource": "*"
}
```

**For SES (Email)**:
```json
{
  "Effect": "Allow",
  "Action": ["ses:SendEmail", "ses:SendRawEmail"],
  "Resource": "*"
}
```

### 3. Security Best Practices

- ✅ Remove OTP logging from CloudWatch in production
- ✅ Implement rate limiting per user (track in DynamoDB)
- ✅ Use environment variables for sensitive configuration
- ✅ Enable AWS WAF for API protection
- ✅ Monitor Lambda invocations for anomalies
- ✅ Set up CloudWatch alarms for failed authentications
- ✅ Implement IP-based throttling if needed

### 4. Monitoring and Alerts

```hcl
resource "aws_cloudwatch_metric_alarm" "auth_failures" {
  alarm_name          = "${var.environment}-high-auth-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors authentication failures"
  
  dimensions = {
    FunctionName = aws_lambda_function.verify_auth_challenge.function_name
  }
}
```

## File Structure

```
modules/lambda_cognito_trigger/
├── main.tf                           # Lambda functions and IAM resources
├── variables.tf                      # Input variables
├── outputs.tf                        # Output values
├── README.md                         # This file
├── build/                            # Generated zip files (gitignored)
│   ├── createAuthChallenge.zip
│   ├── defineAuthChallenge.zip
│   └── verifyAuthChallenge.zip
└── src/                              # Lambda source code
    ├── createAuthChallenge/
    │   └── index.js                  # OTP generation logic
    ├── defineAuthChallenge/
    │   └── index.js                  # Flow control logic
    └── verifyAuthChallenge/
        └── index.js                  # OTP validation logic
```

## Troubleshooting

### Issue: OTP not received
**Solution**: Check CloudWatch logs for the Create Auth Challenge function. OTP is logged there during development.

### Issue: "Invalid session" error
**Solution**: Ensure the session token from InitiateAuth is passed to RespondToAuthChallenge.

### Issue: Lambda permission denied
**Solution**: Verify Lambda permissions allow Cognito to invoke the functions:
```bash
aws lambda get-policy --function-name <FUNCTION_NAME>
```

### Issue: OTP always fails verification
**Solution**: 
- Check CloudWatch logs for both Create and Verify functions
- Verify OTP expiration hasn't passed (5 minutes)
- Ensure OTP is exactly 6 digits

### Debug Mode

Enable verbose logging by checking CloudWatch logs:

```bash
# View Create Auth Challenge logs
aws logs tail /aws/lambda/dev-createAuthChallenge --follow

# View Verify Auth Challenge logs
aws logs tail /aws/lambda/dev-verifyAuthChallenge --follow
```

## Cost Estimation

Based on AWS pricing (us-east-1):

- **Lambda Invocations**: $0.20 per 1M requests
- **Lambda Duration**: $0.0000166667 per GB-second
- **CloudWatch Logs**: $0.50 per GB ingested

**Example**: 10,000 authentications/month
- Lambda invocations: ~30,000 invocations (3 per auth) = $0.006
- Lambda duration: ~30,000 × 100ms × 256MB = $0.01
- CloudWatch logs: ~1MB = $0.50
- **Total**: ~$0.52/month

## Resources

- [AWS Cognito Custom Authentication Flow](https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-lambda-challenge.html)
- [Lambda Triggers for Cognito](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-identity-pools-working-with-aws-lambda-triggers.html)
- [AWS Lambda Node.js Runtime](https://docs.aws.amazon.com/lambda/latest/dg/lambda-nodejs.html)

## License

This module is part of the terraform-cas-practice project.
