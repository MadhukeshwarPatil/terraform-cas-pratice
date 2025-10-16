# Terraform AWS Infrastructure

A modular Terraform project for managing AWS infrastructure across multiple environments (dev, qa, uat, prod) with VPC networking and AWS Cognito user pools.

## 📋 Table of Contents

- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Usage](#usage)
- [Modules](#modules)
- [Environments](#environments)
- [Customization](#customization)
- [Best Practices](#best-practices)

## 🏗️ Project Structure

```
terraform-cas-pratice/
├── modules/
│   ├── vpc/                    # VPC module with subnets, IGW, NAT Gateway
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── cognito/                # Cognito User Pool module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── rds/                    # RDS Aurora PostgreSQL module
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── envs/
│   ├── dev/                    # Development environment
│   │   └── main.tf
│   ├── qa/                     # QA environment
│   │   └── main.tf
│   ├── uat/                    # UAT environment
│   │   └── main.tf
│   └── prod/                   # Production environment
│       └── main.tf
├── provider.tf                 # AWS provider configuration
├── .gitignore
└── README.md
```

## ✅ Prerequisites

Before you begin, ensure you have the following installed:

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configured with valid credentials
- An AWS account with appropriate permissions

### Configure AWS Credentials

```bash
# Configure AWS CLI with your credentials
aws configure

# Or set environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/MadhukeshwarPatil/terraform-cas-pratice.git
cd terraform-cas-pratice
```

### 2. Choose Your Environment

Navigate to the environment you want to deploy:

```bash
# For Development
cd envs/dev

# For QA
cd envs/qa

# For UAT
cd envs/uat

# For Production
cd envs/prod
```

### 3. Initialize Terraform

```bash
terraform init
```

This will download the required provider plugins and initialize the backend.

### 4. Review the Plan

```bash
terraform plan
```

This shows you what resources will be created.

### 5. Apply the Configuration

```bash
terraform apply
```

Type `yes` when prompted to confirm the creation of resources.

### 6. View Outputs

After successful deployment:

```bash
terraform output
```

## 📖 Usage

### Deploy Infrastructure

#### Development Environment

```bash
cd envs/dev
terraform init
terraform plan
terraform apply -auto-approve
```

#### QA Environment

```bash
cd envs/qa
terraform init
terraform plan
terraform apply -auto-approve
```

#### UAT Environment

```bash
cd envs/uat
terraform init
terraform plan
terraform apply -auto-approve
```

#### Production Environment

```bash
cd envs/prod
terraform init
terraform plan
terraform apply -auto-approve
```

### Destroy Infrastructure

To destroy all resources in an environment:

```bash
cd envs/<environment>
terraform destroy
```

Or with auto-approve:

```bash
terraform destroy -auto-approve
```

### Validate Configuration

Check if your Terraform configuration is valid:

```bash
terraform validate
```

### Format Code

Format your Terraform files:

```bash
terraform fmt -recursive
```

## 🧩 Modules

### VPC Module

Creates a complete VPC infrastructure with:
- VPC with customizable CIDR block
- 2 Public Subnets (with Internet Gateway)
- 2 Private Subnets (with NAT Gateway)
- Route tables and associations
- Environment-specific naming

**Key Resources:**
- VPC
- Internet Gateway
- NAT Gateway with Elastic IP
- Public and Private Subnets
- Public and Private Route Tables

### Cognito Module

Creates AWS Cognito User Pool with:
- Email, phone number, and preferred username as required attributes
- Custom attributes for OTP authentication:
  - `custom:otp` (6-digit: 100000-999999)
  - `custom:otp_attempts`
  - `custom:otp_exp`
  - `custom:otp_hash`
  - `custom:otp_sid`
  - `custom:dob`
  - `custom:locale`
- App client with custom authentication flows
- Token validity configurations

### RDS Module

Creates an Aurora PostgreSQL Serverless v2 database cluster with:
- Aurora PostgreSQL engine (version 17.4)
- Serverless v2 scaling configuration (0.5-1.0 ACU for dev)
- Database credentials stored in AWS Secrets Manager
- Security group with VPC-only access
- Private subnet deployment
- Automated backups (7 days retention)
- Enhanced monitoring with CloudWatch
- Performance Insights enabled
- Encryption at rest

**Key Resources:**
- RDS Aurora Cluster
- RDS Cluster Instance (Writer)
- Optional Reader Instance
- DB Subnet Group
- Security Group
- Parameter Groups (Cluster & DB)
- Secrets Manager (credentials)
- IAM Role for Enhanced Monitoring

## 🌍 Environments

Each environment has its own configuration with different CIDR blocks to avoid conflicts:

| Environment | VPC CIDR      | Public Subnets                    | Private Subnets                   |
|-------------|---------------|-----------------------------------|-----------------------------------|
| **dev**     | 10.0.0.0/16   | 10.0.1.0/24, 10.0.2.0/24         | 10.0.3.0/24, 10.0.4.0/24         |
| **qa**      | 10.1.0.0/16   | 10.1.1.0/24, 10.1.2.0/24         | 10.1.3.0/24, 10.1.4.0/24         |
| **uat**     | 10.2.0.0/16   | 10.2.1.0/24, 10.2.2.0/24         | 10.2.3.0/24, 10.2.4.0/24         |
| **prod**    | 10.3.0.0/16   | 10.3.1.0/24, 10.3.2.0/24         | 10.3.3.0/24, 10.3.4.0/24         |

## 🔧 Customization

### Modify VPC CIDR Blocks

Edit the `main.tf` file in your chosen environment:

```hcl
module "vpc" {
  source = "../../modules/vpc"

  env_prefix           = "dev"
  vpc_cidr             = "10.0.0.0/16"           # Change this
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]   # Change these
  private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]   # Change these
  availability_zones   = ["us-east-1a", "us-east-1b"]     # Change these
}
```

### Change AWS Region

Edit the `provider.tf` file in the root directory:

```hcl
provider "aws" {
  region = "us-east-1"  # Change to your preferred region
}
```

### Add More Environments

1. Create a new directory under `envs/`:
   ```bash
   mkdir envs/staging
   ```

2. Create a `main.tf` file with your configuration:
   ```bash
   cp envs/dev/main.tf envs/staging/main.tf
   ```

3. Update the environment name and CIDR blocks in the new `main.tf`

### Enable Lambda Triggers for Cognito

In your environment's `main.tf`:

```hcl
module "cognito" {
  source = "../../modules/cognito"

  env_prefix                        = "dev"
  enable_lambda_triggers            = true
  create_auth_challenge_lambda_arn  = "arn:aws:lambda:..."
  define_auth_challenge_lambda_arn  = "arn:aws:lambda:..."
  verify_auth_challenge_lambda_arn  = "arn:aws:lambda:..."
}
```

## 💡 Best Practices

1. **Always run `terraform plan` before `apply`** to review changes
2. **Use separate state files** for each environment (already configured)
3. **Never commit `.tfvars` files** with sensitive data (already in .gitignore)
4. **Tag your resources** properly (already configured with environment tags)
5. **Test in dev first**, then promote to QA → UAT → Prod
6. **Use remote state** for production environments (configure S3 backend)
7. **Enable state locking** with DynamoDB for team environments
8. **Review outputs** after deployment to get resource IDs

## 📊 Outputs

After deployment, you can view the created resource IDs:

```bash
terraform output

# Example outputs:
# vpc_id = "vpc-xxxxx"
# public_subnet_ids = ["subnet-xxxxx", "subnet-yyyyy"]
# private_subnet_ids = ["subnet-zzzzz", "subnet-aaaaa"]
# cognito_user_pool_id = "us-east-1_xxxxx"
# cognito_app_client_id = "xxxxx"
# rds_cluster_endpoint = "dev-aurora-cluster.cluster-xxxxx.us-east-1.rds.amazonaws.com"
# rds_reader_endpoint = "dev-aurora-cluster.cluster-ro-xxxxx.us-east-1.rds.amazonaws.com"
# rds_database_name = "cas_cms"
# rds_port = 5432
# rds_secrets_manager_name = "dev-db-credentials"
```

## 🗄️ Database Configuration

### RDS Aurora PostgreSQL

The RDS module creates an Aurora PostgreSQL Serverless v2 cluster with credentials securely stored in AWS Secrets Manager.

#### Retrieve Database Credentials

To get the database username and password:

```bash
# Get credentials from Secrets Manager
aws secretsmanager get-secret-value \
  --secret-id <environment>-db-credentials \
  --query SecretString \
  --output text | jq -r '.'

# Example output:
# {
#   "username": "<username>",
#   "password": "<password>"
# }
```

#### Connect to Database

Once you have the credentials, connect using psql:

```bash
# Get the database endpoint
DB_ENDPOINT=$(terraform output -raw rds_cluster_endpoint)

# Connect using psql
psql -h $DB_ENDPOINT \
     -p 5432 \
     -U <username> \
     -d cas_cms

# Or as a one-liner
psql postgresql://<username>:<password>@$DB_ENDPOINT:5432/cas_cms
```

#### Connection String Examples

**For Applications:**

```bash
# PostgreSQL connection string
postgresql://<username>:<password>@dev-aurora-cluster.cluster-xxxxx.us-east-1.rds.amazonaws.com:5432/cas_cms

# JDBC URL (for Java applications)
jdbc:postgresql://dev-aurora-cluster.cluster-xxxxx.us-east-1.rds.amazonaws.com:5432/cas_cms

# Node.js (pg library)
const { Client } = require('pg');
const client = new Client({
  host: 'dev-aurora-cluster.cluster-xxxxx.us-east-1.rds.amazonaws.com',
  port: 5432,
  database: 'cas_cms',
  user: '<username>',
  password: '<password>',
});

# Python (psycopg2)
import psycopg2
conn = psycopg2.connect(
    host="dev-aurora-cluster.cluster-xxxxx.us-east-1.rds.amazonaws.com",
    port=5432,
    database="cas_cms",
    user="<username>",
    password="<password>"
)
```

#### Retrieve Credentials Programmatically

**AWS CLI:**

```bash
# Get username
aws secretsmanager get-secret-value \
  --secret-id dev-db-credentials \
  --query SecretString \
  --output text | jq -r '.username'

# Get password
aws secretsmanager get-secret-value \
  --secret-id dev-db-credentials \
  --query SecretString \
  --output text | jq -r '.password'
```

**Python (boto3):**

```python
import boto3
import json

def get_db_credentials(secret_name):
    client = boto3.client('secretsmanager', region_name='us-east-1')
    response = client.get_secret_value(SecretId=secret_name)
    secret = json.loads(response['SecretString'])
    return secret['username'], secret['password']

username, password = get_db_credentials('dev-db-credentials')
```

**Node.js (AWS SDK):**

```javascript
const AWS = require('aws-sdk');
const secretsManager = new AWS.SecretsManager({ region: 'us-east-1' });

async function getDbCredentials(secretName) {
  const data = await secretsManager.getSecretValue({ SecretId: secretName }).promise();
  const secret = JSON.parse(data.SecretString);
  return { username: secret.username, password: secret.password };
}

const credentials = await getDbCredentials('dev-db-credentials');
```

#### Database Configuration Options

You can customize the RDS configuration in your environment's `main.tf`:

```hcl
module "rds" {
  source = "../../modules/rds"

  env_prefix         = "dev"
  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = module.vpc.vpc_cidr
  private_subnet_ids = module.vpc.private_subnet_ids

  # Database credentials
  db_username   = "<username>"     # Default: cas_user
  db_password   = "<password>"     # Set your password (no @, /, ", or spaces)
  database_name = "cas_cms"        # Default database name

  # Aurora Serverless v2 scaling
  min_capacity = 0.5               # Minimum ACUs (0.5-128)
  max_capacity = 1.0               # Maximum ACUs (0.5-128)

  # Backup configuration
  backup_retention_period = 7      # Days to retain backups
  
  # Environment-specific settings
  skip_final_snapshot  = true      # Set to false for production
  deletion_protection  = false     # Set to true for production
  publicly_accessible  = false     # Keep false for security

  # Optional: Create a reader instance
  create_reader_instance = false   # Set to true if you need read replicas
}
```

#### Important Notes

1. **Password Requirements**: RDS passwords cannot contain `/`, `@`, `"`, or spaces. Use other special characters like `!`, `#`, `$`, `%`, etc.

2. **Security**: The database is deployed in private subnets and only accessible from within the VPC (CIDR: 10.x.0.0/16).

3. **Secrets Manager**: Credentials are automatically stored in AWS Secrets Manager with the name `<environment>-db-credentials`.

4. **Scaling**: Aurora Serverless v2 automatically scales between min_capacity and max_capacity based on workload.

5. **Monitoring**: Enhanced monitoring and Performance Insights are enabled by default for development environments.

## 🔒 Security Notes

- **Never commit** AWS credentials or sensitive values
- **Use IAM roles** with least privilege principle
- **Enable MFA** for production AWS accounts
- **Rotate credentials** regularly using AWS Secrets Manager rotation
- **Review security groups** and network ACLs
- **Enable CloudTrail** for audit logging
- **Use AWS Secrets Manager** for sensitive data (already configured for RDS)
- **Database access** is restricted to VPC CIDR range only
- **RDS encryption** at rest is enabled by default
- **Use VPN or bastion host** to access RDS from outside AWS

## 🐛 Troubleshooting

### Common Issues

1. **Provider initialization fails**
   ```bash
   rm -rf .terraform .terraform.lock.hcl
   terraform init
   ```

2. **State lock timeout**
   ```bash
   # Manually unlock (use with caution)
   terraform force-unlock <LOCK_ID>
   ```

3. **Resource already exists**
   ```bash
   # Import existing resource
   terraform import <resource_type>.<resource_name> <resource_id>
   ```

## 📝 License

This project is for personal use.

## 👤 Author

**Madhukeshwar Patil**
- GitHub: [@MadhukeshwarPatil](https://github.com/MadhukeshwarPatil)

## 🤝 Contributing

This is a personal project. If you clone it, feel free to modify it for your own use.

---

**Happy Terraforming! 🚀**
