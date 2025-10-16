# RDS Aurora PostgreSQL Module - Outputs

output "cluster_id" {
  description = "The ID of the RDS cluster"
  value       = aws_rds_cluster.main.id
}

output "cluster_arn" {
  description = "The ARN of the RDS cluster"
  value       = aws_rds_cluster.main.arn
}

output "cluster_endpoint" {
  description = "The cluster endpoint (writer)"
  value       = aws_rds_cluster.main.endpoint
}

output "cluster_reader_endpoint" {
  description = "The cluster reader endpoint"
  value       = aws_rds_cluster.main.reader_endpoint
}

output "cluster_port" {
  description = "The port the cluster is listening on"
  value       = aws_rds_cluster.main.port
}

output "database_name" {
  description = "The name of the default database"
  value       = aws_rds_cluster.main.database_name
}

output "master_username" {
  description = "The master username"
  value       = aws_rds_cluster.main.master_username
  sensitive   = true
}

output "writer_instance_id" {
  description = "The ID of the writer instance"
  value       = aws_rds_cluster_instance.writer.id
}

output "writer_instance_endpoint" {
  description = "The endpoint of the writer instance"
  value       = aws_rds_cluster_instance.writer.endpoint
}

output "reader_instance_id" {
  description = "The ID of the reader instance (if created)"
  value       = var.create_reader_instance ? aws_rds_cluster_instance.reader[0].id : null
}

output "reader_instance_endpoint" {
  description = "The endpoint of the reader instance (if created)"
  value       = var.create_reader_instance ? aws_rds_cluster_instance.reader[0].endpoint : null
}

output "security_group_id" {
  description = "The ID of the RDS security group"
  value       = aws_security_group.rds.id
}

output "db_subnet_group_name" {
  description = "The name of the DB subnet group"
  value       = aws_db_subnet_group.main.name
}

output "secrets_manager_secret_arn" {
  description = "The ARN of the Secrets Manager secret containing DB credentials"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "secrets_manager_secret_name" {
  description = "The name of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.db_credentials.name
}
