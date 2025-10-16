# Production Environment Configuration

module "vpc" {
  source = "../../modules/vpc"

  env_prefix           = "prod"
  vpc_cidr             = "10.3.0.0/16"
  public_subnet_cidrs  = ["10.3.1.0/24", "10.3.2.0/24"]
  private_subnet_cidrs = ["10.3.3.0/24", "10.3.4.0/24"]
  availability_zones   = ["us-east-1a", "us-east-1b"]
}
