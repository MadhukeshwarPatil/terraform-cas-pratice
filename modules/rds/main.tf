# RDS Aurora PostgreSQL Module - Main Configuration
# This module creates an Aurora PostgreSQL Serverless v2 cluster with credentials in Secrets Manager

# ------------------------
# Secrets Manager for DB Credentials
# ------------------------
resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${var.env_prefix}-db-credentials"
  description = "Database credentials for ${var.env_prefix} environment"

  tags = {
    Name        = "${var.env_prefix}-db-credentials"
    Environment = var.env_prefix
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
  })
}

# ------------------------
# DB Subnet Group
# ------------------------
resource "aws_db_subnet_group" "main" {
  name       = "${var.env_prefix}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name        = "${var.env_prefix}-db-subnet-group"
    Environment = var.env_prefix
  }
}

# ------------------------
# Security Group for RDS
# ------------------------
resource "aws_security_group" "rds" {
  name        = "${var.env_prefix}-rds-sg"
  description = "Security group for RDS Aurora PostgreSQL"
  vpc_id      = var.vpc_id

  # Allow PostgreSQL from VPC
  ingress {
    description = "PostgreSQL from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.env_prefix}-rds-sg"
    Environment = var.env_prefix
  }
}

# ------------------------
# RDS Cluster Parameter Group
# ------------------------
resource "aws_rds_cluster_parameter_group" "main" {
  name        = "${var.env_prefix}-aurora-postgres-cluster-pg"
  family      = "aurora-postgresql17"
  description = "Cluster parameter group for ${var.env_prefix} Aurora PostgreSQL"

  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
  }

  tags = {
    Name        = "${var.env_prefix}-aurora-postgres-cluster-pg"
    Environment = var.env_prefix
  }
}

# ------------------------
# RDS DB Parameter Group
# ------------------------
resource "aws_db_parameter_group" "main" {
  name        = "${var.env_prefix}-aurora-postgres-db-pg"
  family      = "aurora-postgresql17"
  description = "DB parameter group for ${var.env_prefix} Aurora PostgreSQL"

  tags = {
    Name        = "${var.env_prefix}-aurora-postgres-db-pg"
    Environment = var.env_prefix
  }
}

# ------------------------
# RDS Aurora Cluster
# ------------------------
resource "aws_rds_cluster" "main" {
  cluster_identifier = "${var.env_prefix}-aurora-cluster"
  engine             = "aurora-postgresql"
  engine_mode        = "provisioned"
  engine_version     = var.engine_version
  database_name      = var.database_name

  master_username = var.db_username
  master_password = var.db_password

  db_subnet_group_name            = aws_db_subnet_group.main.name
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.main.name
  vpc_security_group_ids          = [aws_security_group.rds.id]

  # Serverless v2 scaling configuration
  serverlessv2_scaling_configuration {
    min_capacity = var.min_capacity
    max_capacity = var.max_capacity
  }

  # Backup configuration
  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = var.preferred_backup_window
  preferred_maintenance_window = var.preferred_maintenance_window

  # Encryption
  storage_encrypted = true
  kms_key_id        = var.kms_key_id

  # Enable Performance Insights
  enabled_cloudwatch_logs_exports = ["postgresql"]

  # RDS Extended Support - Disabled
  engine_lifecycle_support = "open-source-rds-extended-support-disabled"

  # Skip final snapshot for non-prod environments
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.env_prefix}-aurora-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # Deletion protection for production
  deletion_protection = var.deletion_protection

  tags = {
    Name        = "${var.env_prefix}-aurora-cluster"
    Environment = var.env_prefix
  }

  depends_on = [aws_secretsmanager_secret_version.db_credentials]
}

# ------------------------
# RDS Aurora Cluster Instance (Writer)
# ------------------------
resource "aws_rds_cluster_instance" "writer" {
  identifier         = "${var.env_prefix}-aurora-instance-writer"
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.main.engine
  engine_version     = aws_rds_cluster.main.engine_version

  db_parameter_group_name = aws_db_parameter_group.main.name

  # Performance Insights
  performance_insights_enabled    = var.performance_insights_enabled
  performance_insights_kms_key_id = var.kms_key_id
  performance_insights_retention_period = var.performance_insights_retention_period

  # Monitoring
  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_interval > 0 ? aws_iam_role.rds_monitoring[0].arn : null

  publicly_accessible = var.publicly_accessible

  tags = {
    Name        = "${var.env_prefix}-aurora-instance-writer"
    Environment = var.env_prefix
    Role        = "writer"
  }
}

# ------------------------
# RDS Aurora Cluster Instance (Reader) - Optional
# ------------------------
resource "aws_rds_cluster_instance" "reader" {
  count = var.create_reader_instance ? 1 : 0

  identifier         = "${var.env_prefix}-aurora-instance-reader"
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.main.engine
  engine_version     = aws_rds_cluster.main.engine_version

  db_parameter_group_name = aws_db_parameter_group.main.name

  # Performance Insights
  performance_insights_enabled    = var.performance_insights_enabled
  performance_insights_kms_key_id = var.kms_key_id
  performance_insights_retention_period = var.performance_insights_retention_period

  # Monitoring
  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_interval > 0 ? aws_iam_role.rds_monitoring[0].arn : null

  publicly_accessible = var.publicly_accessible

  tags = {
    Name        = "${var.env_prefix}-aurora-instance-reader"
    Environment = var.env_prefix
    Role        = "reader"
  }
}

# ------------------------
# IAM Role for Enhanced Monitoring
# ------------------------
resource "aws_iam_role" "rds_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  name = "${var.env_prefix}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.env_prefix}-rds-monitoring-role"
    Environment = var.env_prefix
  }
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  role       = aws_iam_role.rds_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
