output "cluster_name" { value = aws_eks_cluster.this.name }
output "cluster_endpoint" { value = aws_eks_cluster.this.endpoint }
output "ecr_repositories" { value = { for name, repo in aws_ecr_repository.service : name => repo.repository_url } }
output "postgres_endpoints" { value = { for name, db in aws_db_instance.postgres : name => db.address } }
output "redis_endpoint" { value = aws_elasticache_replication_group.redis.primary_endpoint_address }
output "sqs_url" { value = aws_sqs_queue.events.url }
output "secrets_manager_arn" { value = aws_secretsmanager_secret.application.arn }
