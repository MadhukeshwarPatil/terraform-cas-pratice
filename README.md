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
│   └── cognito/                # Cognito User Pool module
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
```

## 🔒 Security Notes

- **Never commit** AWS credentials or sensitive values
- **Use IAM roles** with least privilege principle
- **Enable MFA** for production AWS accounts
- **Rotate credentials** regularly
- **Review security groups** and network ACLs
- **Enable CloudTrail** for audit logging
- **Use AWS Secrets Manager** for sensitive data

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
