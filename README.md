# Terraform AWS Infrastructure - CAS CMS

Production-ready, modular Terraform infrastructure for AWS with VPC networking, Cognito authentication, Lambda-based OTP system, and Aurora PostgreSQL Serverless v2 database.

## 📋 Table of Contents

- [Overview](#-overview)
- [Architecture](#-architecture)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Project Structure](#-project-structure)
- [Modules](#-modules)
- [Environment Configuration](#-environment-configuration)
- [Lifecycle Management](#️-lifecycle-management)
- [OTP Authentication](#-otp-authentication)
- [Database Access](#-database-access)
- [Security Best Practices](#-security-best-practices)
- [Troubleshooting](#-troubleshooting)
- [Outputs Reference](#-outputs-reference)
- [License](#-license)

## 🎯 Overview

This Terraform project provides a complete AWS infrastructure setup with:

- **Multi-Environment Support**: dev, qa, uat, prod with isolated configurations
- **Network Infrastructure**: VPC with public/private subnets, NAT Gateway, Internet Gateway
- **Authentication**: AWS Cognito with custom OTP-based authentication via Lambda
- **Database**: Aurora PostgreSQL Serverless v2 with automatic scaling
- **Security**: Secrets Manager integration, encrypted storage, VPC isolation
- **Lifecycle Management**: Proper resource ordering with automatic Lambda trigger attachment/detachment

## 🏗 Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Account                              │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │                    VPC (10.x.0.0/16)                    │    │
│  │                                                          │    │
│  │  ┌──────────────────┐      ┌──────────────────┐        │    │
│  │  │  Public Subnet   │      │  Public Subnet   │        │    │
│  │  │   us-east-1a     │      │   us-east-1b     │        │    │
│  │  │                  │      │                  │        │    │
│  │  │   NAT Gateway    │      │                  │        │    │
│  │  └────────┬─────────┘      └──────────────────┘        │    │
│  │           │                                             │    │
│  │  ┌────────▼─────────┐      ┌──────────────────┐        │    │
│  │  │  Private Subnet  │      │  Private Subnet  │        │    │
│  │  │   us-east-1a     │      │   us-east-1b     │        │    │
│  │  │                  │      │                  │        │    │
│  │  │  ┌────────────┐  │      │  ┌────────────┐  │        │    │
│  │  │  │ RDS Aurora │  │      │  │ RDS Aurora │  │        │    │
│  │  │  │ PostgreSQL │◄─┼──────┼─►│   Reader   │  │        │    │
│  │  │  │  (Writer)  │  │      │  │ (Optional) │  │        │    │
│  │  │  └────────────┘  │      │  └────────────┘  │        │    │
│  │  └──────────────────┘      └──────────────────┘        │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │              Cognito User Pool (CUSTOM_AUTH)            │    │
│  │                                                          │    │
│  │   Lambda Triggers:                                      │    │
│  │   • createAuthChallenge   (Generate 6-digit OTP)        │    │
│  │   • defineAuthChallenge   (Control flow, max 3 tries)   │    │
│  │   • verifyAuthChallenge   (Validate OTP with SHA-256)   │    │
│  │                                                          │    │
│  │   Runtime: Node.js 22.x | Memory: 128 MB | Timeout: 3s │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │               AWS Secrets Manager                       │    │
│  │   • Database credentials (username/password)            │    │
│  │   • Automatic encryption at rest (AES-256)              │    │
│  │   • 30-day recovery window                              │    │
│  └────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

## ✅ Prerequisites

### Required Software

- [Terraform](https://www.terraform.io/downloads.html) >= 1.3.0
- [AWS CLI](https://aws.amazon.com/cli/) v2
- Git
- `jq` (for parsing JSON outputs)

### AWS Account Setup

1. **AWS Account** with appropriate IAM permissions:
   - VPC, EC2 (subnets, NAT, IGW)
   - Cognito User Pools
   - Lambda (functions, layers, permissions)
   - RDS (Aurora Serverless v2)
   - Secrets Manager
   - CloudWatch Logs
   - IAM (roles, policies)

2. **Configure AWS CLI**:
   ```bash
   aws configure
   # AWS Access Key ID: YOUR_ACCESS_KEY
   # AWS Secret Access Key: YOUR_SECRET_KEY
   # Default region name: us-east-1
   # Default output format: json
   ```

3. **Verify credentials**:
   ```bash
   aws sts get-caller-identity
   ```

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/MadhukeshwarPatil/terraform-cas-pratice.git
cd terraform-cas-pratice
```

### 2. Configure Database Credentials

**IMPORTANT**: Never hardcode credentials in Terraform files!

Create `envs/dev/terraform.tfvars`:

```bash
cd envs/dev
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

Add your credentials:

```hcl
# Database credentials (no @, /, ", or spaces in password)
db_username = "cas_user"
db_password = "YourSecurePassword123!#$"
```

> **Note**: `terraform.tfvars` is in `.gitignore` and will never be committed.

### 3. Initialize Terraform

```bash
terraform init
```

This will download the required provider plugins (AWS and Null providers).

### 4. Review the Plan

```bash
terraform plan
```

This shows you what resources will be created (39 resources).

### 5. Deploy Infrastructure

```bash
terraform apply
```

Type `yes` when prompted. Deployment takes **~10-15 minutes**.

**What gets deployed:**
- ✅ VPC with 4 subnets, NAT Gateway, Internet Gateway
- ✅ Cognito User Pool WITHOUT triggers initially
- ✅ Lambda functions (createAuthChallenge, defineAuthChallenge, verifyAuthChallenge)
- ✅ **null_resource automatically attaches Lambda triggers** to Cognito
- ✅ RDS Aurora Serverless v2 cluster
- ✅ Secrets Manager with database credentials

### 6. View Outputs

After successful deployment:

```bash
terraform output
```

**Key Outputs:**
- VPC ID and subnet IDs
- Cognito User Pool ID and App Client ID
- Lambda function ARNs
- RDS cluster endpoint
- Secrets Manager secret name

### 7. Destroy Infrastructure

To clean up all resources:

```bash
terraform destroy
```

**Lifecycle Order (Automatic):**
- ✅ **null_resource detaches Lambda triggers** from Cognito
- ✅ Lambda permissions removed
- ✅ Lambda functions deleted
- ✅ Cognito deleted
- ✅ RDS cluster deleted
- ✅ VPC infrastructure deleted

## 📁 Project Structure

```
terraform-cas-pratice/
├── provider.tf                        # AWS + Null providers
├── .gitignore                         # Excludes .tfvars, .tfstate, etc.
├── README.md                          # This file
│
├── modules/                           # Reusable Terraform modules
│   ├── vpc/                           # VPC with subnets, NAT, IGW
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── cognito/                       # Cognito User Pool + Client
│   │   ├── main.tf                    # Dynamic lambda_config block
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── lambda_cognito_trigger/        # Lambda auth functions
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── README.md                  # Lambda documentation
│   │   ├── build/                     # Generated Lambda zips
│   │   └── src/
│   │       ├── createAuthChallenge/
│   │       │   └── index.mjs          # OTP generation
│   │       ├── defineAuthChallenge/
│   │       │   └── index.mjs          # Flow control
│   │       └── verifyAuthChallenge/
│   │           └── index.mjs          # OTP validation
│   │
│   └── rds/                           # Aurora PostgreSQL
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── envs/                              # Environment-specific configs
│   ├── dev/
│   │   ├── main.tf                    # Dev configuration
│   │   ├── variables.tf               # Dev variables
│   │   ├── terraform.tfvars.example   # Example credentials
│   │   └── terraform.tfvars           # Your credentials (gitignored)
│   ├── qa/
│   │   └── main.tf
│   ├── uat/
│   │   └── main.tf
│   └── prod/
│       └── main.tf
│
└── scripts/
    └── attach-lambda-triggers.sh      # Legacy script (not needed)
```

## 🧩 Modules

### VPC Module

Creates complete network infrastructure:

**Resources:**
- VPC (10.x.0.0/16) with DNS support
- 2 Public Subnets (us-east-1a, us-east-1b) with auto-assign public IP
- 2 Private Subnets (us-east-1a, us-east-1b)
- Internet Gateway for public subnets
- NAT Gateway with Elastic IP for private subnets
- Route tables and associations

**Key Features:**
- Multi-AZ deployment for high availability
- Isolated public/private networks
- Environment-specific CIDR blocks

### Cognito Module

User authentication service with Lambda trigger integration:

**Resources:**
- Cognito User Pool with custom attributes
- App Client with CUSTOM_AUTH flow
- Dynamic Lambda trigger configuration

**Custom Attributes:**
- `custom:otp` - 6-digit OTP code
- `custom:otp_attempts` - Failed attempt counter
- `custom:otp_exp` - Expiration timestamp
- `custom:otp_hash` - SHA-256 hash for validation
- `custom:otp_sid` - Session ID
- `custom:dob` - Date of birth
- `custom:locale` - User locale preference

**Authentication Flows:**
- ALLOW_CUSTOM_AUTH (OTP authentication)
- ALLOW_REFRESH_TOKEN_AUTH

### Lambda Cognito Trigger Module

Custom OTP-based authentication system:

**Lambda Functions:**

1. **createAuthChallenge**
   - Generates 6-digit OTP (100000-999999)
   - Creates SHA-256 hash for secure storage
   - Logs OTP to CloudWatch (dev) or sends via SMS/Email (prod)
   - Sets 5-minute expiration

2. **defineAuthChallenge**
   - Controls authentication flow
   - Enforces maximum 3 attempts per session
   - Issues tokens on successful validation

3. **verifyAuthChallenge**
   - Validates OTP using timing-safe HMAC-SHA256 comparison
   - Prevents timing attacks
   - Updates attempt counter

**Configuration:**
- Runtime: Node.js 22.x
- Memory: 128 MB
- Timeout: 3 seconds
- CloudWatch Logs: 7-day retention

### RDS Module

Aurora PostgreSQL Serverless v2 database:

**Resources:**
- Aurora Cluster (PostgreSQL 17.4)
- Writer Instance (db.serverless)
- Optional Reader Instance
- DB Subnet Group (private subnets)
- Security Group (VPC-only access)
- Parameter Groups (cluster & DB)
- Secrets Manager Secret for credentials
- IAM Role for Enhanced Monitoring

**Features:**
- **Serverless v2:** Auto-scales (0.5-1.0 ACU for dev)
- **Encryption:** At rest enabled by default
- **Backups:** 7-day retention, automated
- **Monitoring:** Enhanced monitoring + Performance Insights (7-day retention)
- **High Availability:** Multi-AZ deployment
- **Secure Storage:** Credentials in Secrets Manager (30-day recovery window)

## 🌍 Environment Configuration

Each environment has isolated CIDR blocks to prevent conflicts:

| Environment | VPC CIDR    | Public Subnets              | Private Subnets             | RDS Scaling |
|-------------|-------------|-----------------------------|-----------------------------|-------------|
| **dev**     | 10.0.0.0/16 | 10.0.1.0/24, 10.0.2.0/24   | 10.0.3.0/24, 10.0.4.0/24   | 0.5-1.0 ACU |
| **qa**      | 10.1.0.0/16 | 10.1.1.0/24, 10.1.2.0/24   | 10.1.3.0/24, 10.1.4.0/24   | 0.5-2.0 ACU |
| **uat**     | 10.2.0.0/16 | 10.2.1.0/24, 10.2.2.0/24   | 10.2.3.0/24, 10.2.4.0/24   | 1.0-4.0 ACU |
| **prod**    | 10.3.0.0/16 | 10.3.1.0/24, 10.3.2.0/24   | 10.3.3.0/24, 10.3.4.0/24   | 2.0-8.0 ACU |

**Availability Zones:** us-east-1a, us-east-1b (can be customized)

## ⚙️ Lifecycle Management

This project implements **proper resource ordering** to avoid circular dependencies and ensure clean teardown.

### Deployment Order

```
1. VPC Infrastructure → Created first
2. Cognito User Pool   → Created WITHOUT Lambda triggers
3. Lambda Functions    → Created with Cognito dependency
4. null_resource       → Attaches triggers via AWS CLI
5. RDS Aurora          → Created last (~10-15 min)
```

### Destruction Order

```
1. null_resource       → Detaches triggers (AWS CLI)
2. Lambda Permissions  → Removed
3. Lambda Functions    → Deleted
4. Cognito             → Deleted (no triggers attached)
5. RDS Aurora          → Cluster + Instance deleted
6. VPC Infrastructure  → Deleted last
```

### Implementation

The `null_resource` in `envs/dev/main.tf` handles trigger lifecycle:

**Create Provisioner (attaches triggers):**
```bash
aws cognito-idp update-user-pool \
  --user-pool-id ${POOL_ID} \
  --lambda-config \
    CreateAuthChallenge=${ARN},\
    DefineAuthChallenge=${ARN},\
    VerifyAuthChallengeResponse=${ARN}
```

**Destroy Provisioner (detaches triggers):**
```bash
aws cognito-idp update-user-pool \
  --user-pool-id ${POOL_ID} \
  --lambda-config '{}'
```

**Benefits:**
- ✅ No circular dependencies
- ✅ Automatic trigger attachment on create
- ✅ Automatic trigger detachment on destroy
- ✅ Clean state management
- ✅ Idempotent operations

## 🔐 OTP Authentication

### How It Works

1. **User initiates auth** with username (email/phone)
2. **Lambda generates OTP** (6-digit code: 100000-999999)
3. **OTP sent to user** (CloudWatch logs in dev, SMS/Email in prod)
4. **User submits OTP**
5. **Lambda validates OTP** (timing-safe SHA-256 comparison)
6. **Tokens issued** on success (ID, Access, Refresh tokens)

### Testing OTP Flow

#### Step 1: Create a Test User

```bash
USER_POOL_ID=$(cd envs/dev && terraform output -raw cognito_user_pool_id)

aws cognito-idp admin-create-user \
  --user-pool-id "$USER_POOL_ID" \
  --username "test@example.com" \
  --user-attributes \
    Name=email,Value=test@example.com \
    Name=email_verified,Value=true \
  --message-action SUPPRESS
```

#### Step 2: Initiate Authentication

```bash
CLIENT_ID=$(cd envs/dev && terraform output -raw cognito_app_client_id)

aws cognito-idp initiate-auth \
  --auth-flow CUSTOM_AUTH \
  --client-id "$CLIENT_ID" \
  --auth-parameters USERNAME=test@example.com
```

**Response:**
```json
{
  "ChallengeName": "CUSTOM_CHALLENGE",
  "Session": "...",
  "ChallengeParameters": {
    "USERNAME": "test@example.com"
  }
}
```

#### Step 3: Check CloudWatch for OTP

```bash
aws logs tail /aws/lambda/createAuthChallenge --follow
```

Look for: `Generated OTP: 123456`

#### Step 4: Submit OTP

```bash
aws cognito-idp respond-to-auth-challenge \
  --client-id "$CLIENT_ID" \
  --challenge-name CUSTOM_CHALLENGE \
  --session "<SESSION_FROM_STEP_2>" \
  --challenge-responses USERNAME=test@example.com,ANSWER=123456
```

**Success Response:**
```json
{
  "AuthenticationResult": {
    "AccessToken": "eyJra...",
    "ExpiresIn": 3600,
    "TokenType": "Bearer",
    "RefreshToken": "eyJjd...",
    "IdToken": "eyJra..."
  }
}
```

### Authentication Flow Diagram

```
User → InitiateAuth(CUSTOM_AUTH)
  ↓
Define Auth Challenge (1st attempt)
  ↓ (issue CUSTOM_CHALLENGE)
Create Auth Challenge (generate 6-digit OTP)
  ↓ (send OTP via CloudWatch/SMS/Email)
User receives OTP
  ↓
User → RespondToAuthChallenge(OTP)
  ↓
Verify Auth Challenge (validate OTP with SHA-256)
  ↓
If valid → Define Auth Challenge → Issue Tokens ✓
If invalid → Retry (max 3 attempts) → Fail Authentication ✗
```

### Security Features

- ✅ **6-digit OTP** (100000-999999)
- ✅ **5-minute expiration** window
- ✅ **SHA-256 hash storage** (not plaintext)
- ✅ **Timing-safe comparison** (prevents timing attacks)
- ✅ **Maximum 3 attempts** per session
- ✅ **CloudWatch logging** for audit trail
- ✅ **Session-based validation** (otp_sid)

## 💾 Database Access

### Get Database Credentials

```bash
# From Terraform outputs
cd envs/dev
DB_ENDPOINT=$(terraform output -raw rds_cluster_endpoint)
DB_NAME=$(terraform output -raw rds_database_name)
SECRET_NAME=$(terraform output -raw rds_secrets_manager_name)

# From Secrets Manager
aws secretsmanager get-secret-value \
  --secret-id "$SECRET_NAME" \
  --query SecretString \
  --output text | jq -r '.'
```

**Output:**
```json
{
  "username": "cas_user",
  "password": "YourSecurePassword123!#$"
}
```

### Connect to Database

#### Using psql

```bash
# Interactive connection
psql -h "$DB_ENDPOINT" -p 5432 -U cas_user -d cas_cms

# One-liner with password from Secrets Manager
PGPASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id "$SECRET_NAME" \
  --query SecretString \
  --output text | jq -r '.password') \
psql -h "$DB_ENDPOINT" -p 5432 -U cas_user -d cas_cms
```

#### Connection Strings

**PostgreSQL:**
```
postgresql://cas_user:YourSecurePassword@dev-aurora-cluster.cluster-xxxxx.us-east-1.rds.amazonaws.com:5432/cas_cms
```

**JDBC (Java):**
```
jdbc:postgresql://dev-aurora-cluster.cluster-xxxxx.us-east-1.rds.amazonaws.com:5432/cas_cms
```

**Node.js (pg library):**
```javascript
const { Client } = require('pg');

const client = new Client({
  host: process.env.DB_ENDPOINT,
  port: 5432,
  database: 'cas_cms',
  user: 'cas_user',
  password: process.env.DB_PASSWORD,
  ssl: { rejectUnauthorized: false }
});

await client.connect();
```

**Python (psycopg2):**
```python
import psycopg2

conn = psycopg2.connect(
    host=os.environ['DB_ENDPOINT'],
    port=5432,
    database='cas_cms',
    user='cas_user',
    password=os.environ['DB_PASSWORD'],
    sslmode='require'
)
```

## 🔒 Security Best Practices

### Credential Management

1. **Never commit credentials** to version control
   - ✅ Use `terraform.tfvars` (gitignored)
   - ✅ Use environment variables (`TF_VAR_*`)
   - ✅ Use AWS Secrets Manager
   - ❌ Never hardcode in `.tf` files

2. **Password requirements**
   - Minimum 8 characters
   - Mix of uppercase, lowercase, numbers, symbols
   - Avoid: `/`, `@`, `"`, spaces

3. **Rotate credentials regularly**
   ```bash
   # Update password in Secrets Manager
   aws secretsmanager put-secret-value \
     --secret-id dev-db-credentials \
     --secret-string '{"username":"cas_user","password":"NewPassword123!#"}'
   ```

### Network Security

- **RDS in private subnets** (no internet access)
- **Security group** allows only VPC CIDR (10.x.0.0/16)
- **Use VPN or bastion host** for external access
- **Enable VPC Flow Logs** for monitoring

### IAM Best Practices

- **Principle of least privilege** for all IAM roles
- **Enable MFA** for AWS console access
- **Use IAM roles** instead of access keys
- **Rotate access keys** every 90 days
- **Enable CloudTrail** for audit logging

## 🐛 Troubleshooting

### Common Issues

#### 1. Terraform Init Fails

```bash
# Clear Terraform cache
rm -rf .terraform .terraform.lock.hcl

# Re-initialize
terraform init
```

#### 2. AWS Credentials Not Found

```bash
# Verify AWS configuration
aws sts get-caller-identity

# Re-configure if needed
aws configure
```

#### 3. RDS Password Invalid

**Error:** Password cannot contain `/`, `@`, `"`, or spaces

**Solution:** Use only alphanumeric and these special chars: `!#$%^&*()_+-=`

#### 4. Lambda OTP Not Working

```bash
# Check Lambda logs
aws logs tail /aws/lambda/createAuthChallenge --follow
aws logs tail /aws/lambda/verifyAuthChallenge --follow

# Verify triggers are attached
aws cognito-idp describe-user-pool \
  --user-pool-id <USER_POOL_ID> \
  --query 'UserPool.LambdaConfig'
```

#### 5. Database Connection Refused

**Issue:** Cannot connect to RDS from local machine

**Solution:** RDS is in private subnet - use one of these:
- Deploy bastion host in public subnet
- Use AWS Systems Manager Session Manager
- Connect from EC2 instance in same VPC
- Set up VPN connection to VPC

#### 6. State Lock Error

```bash
# Force unlock (use with caution!)
terraform force-unlock <LOCK_ID>
```

### Debug Mode

Enable Terraform debug logging:

```bash
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform-debug.log
terraform apply
```

## 📊 Outputs Reference

After deployment, access outputs:

```bash
terraform output          # All outputs
terraform output vpc_id   # Specific output
terraform output -json    # JSON format
```

**Available Outputs:**

| Output | Description | Example |
|--------|-------------|---------|
| `vpc_id` | VPC identifier | `vpc-0303c07bcadfa2ccc` |
| `public_subnet_ids` | Public subnet IDs | `["subnet-xxx", "subnet-yyy"]` |
| `private_subnet_ids` | Private subnet IDs | `["subnet-zzz", "subnet-aaa"]` |
| `cognito_user_pool_id` | Cognito pool ID | `us-east-1_prWz1uVda` |
| `cognito_user_pool_arn` | Cognito pool ARN | `arn:aws:cognito-idp:...` |
| `cognito_app_client_id` | App client ID | `45tb7gep1lgjq8n9f5f4dpk1jd` |
| `lambda_create_auth_challenge_arn` | Create auth Lambda ARN | `arn:aws:lambda:...` |
| `lambda_define_auth_challenge_arn` | Define auth Lambda ARN | `arn:aws:lambda:...` |
| `lambda_verify_auth_challenge_arn` | Verify auth Lambda ARN | `arn:aws:lambda:...` |
| `rds_cluster_endpoint` | Writer endpoint | `dev-aurora-cluster.cluster-xxx.rds.amazonaws.com` |
| `rds_reader_endpoint` | Reader endpoint | `dev-aurora-cluster.cluster-ro-xxx.rds.amazonaws.com` |
| `rds_port` | Database port | `5432` |
| `rds_database_name` | Database name | `cas_cms` |
| `rds_secrets_manager_name` | Secret name | `dev-db-credentials` |
| `rds_secrets_manager_arn` | Secret ARN | `arn:aws:secretsmanager:...` |

## 📚 Additional Resources

- **Lambda OTP Documentation:** [`modules/lambda_cognito_trigger/README.md`](modules/lambda_cognito_trigger/README.md)
- **AWS Cognito Custom Auth:** https://docs.aws.amazon.com/cognito/latest/developerguide/amazon-cognito-user-pools-authentication-flow.html
- **Aurora Serverless v2:** https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-serverless-v2.html
- **Terraform Best Practices:** https://www.terraform-best-practices.com/

## 📝 License

This project is for personal/educational use.

## 👤 Author

**Madhukeshwar Patil**
- GitHub: [@MadhukeshwarPatil](https://github.com/MadhukeshwarPatil)
- Repository: [terraform-cas-pratice](https://github.com/MadhukeshwarPatil/terraform-cas-pratice)

---

**Happy Terraforming! 🚀**
