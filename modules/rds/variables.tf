# RDS Aurora PostgreSQL Module - Input Variables

variable "env_prefix" {
  description = "Environment prefix (e.g., dev, qa, uat, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where RDS will be deployed"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block for security group rules"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for RDS subnet group"
  type        = list(string)
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
  sensitive   = true
  # No default - must be provided via terraform.tfvars or environment variable
  # Example: export TF_VAR_db_username="your_username"
}

variable "db_password" {
  description = "Master password for the database"
  type        = string
  sensitive   = true
  # No default - must be provided via terraform.tfvars or environment variable
  # Example: export TF_VAR_db_password="your_secure_password"
  # Password requirements: No /, @, ", or spaces allowed
}

variable "database_name" {
  description = "Name of the default database to create"
  type        = string
  default     = "auth_cms"
}

variable "engine_version" {
  description = "Aurora PostgreSQL engine version"
  type        = string
  default     = "17.4"
}

variable "min_capacity" {
  description = "Minimum capacity for Aurora Serverless v2 (in ACUs)"
  type        = number
  default     = 0.5
}

variable "max_capacity" {
  description = "Maximum capacity for Aurora Serverless v2 (in ACUs)"
  type        = number
  default     = 1.0
}

variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "preferred_backup_window" {
  description = "Preferred backup window (UTC)"
  type        = string
  default     = "03:00-04:00"
}

variable "preferred_maintenance_window" {
  description = "Preferred maintenance window (UTC)"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "kms_key_id" {
  description = "KMS key ID for encryption (leave null for default AWS key)"
  type        = string
  default     = null
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when destroying cluster"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = true
}

variable "performance_insights_retention_period" {
  description = "Performance Insights retention period in days"
  type        = number
  default     = 7
}

variable "monitoring_interval" {
  description = "Enhanced monitoring interval in seconds (0, 1, 5, 10, 15, 30, 60)"
  type        = number
  default     = 60
}

variable "publicly_accessible" {
  description = "Make the database publicly accessible"
  type        = bool
  default     = false
}

variable "create_reader_instance" {
  description = "Create a reader instance"
  type        = bool
  default     = false
}
