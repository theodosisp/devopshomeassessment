output "cluster_name" {
  value       = aws_ecs_cluster.this.name
  description = "ECS cluster name."
}

output "cluster_arn" {
  value       = aws_ecs_cluster.this.arn
  description = "ECS cluster ARN."
}

output "service_name" {
  value       = aws_ecs_service.this.name
  description = "ECS service name."
}

output "service_arn" {
  value       = aws_ecs_service.this.arn
  description = "ECS service ARN."
}

output "alb_dns_name" {
  value       = aws_lb.this.dns_name
  description = "ALB DNS name (HTTP on :80)."
}

output "execution_role_arn" {
  value       = aws_iam_role.execution.arn
  description = "Task execution role ARN (for PassRole)."
}

output "task_role_arn" {
  value       = aws_iam_role.task.arn
  description = "Task IAM role ARN (runtime)."
}

output "target_group_arn" {
  value       = aws_lb_target_group.this.arn
  description = "ALB target group ARN."
}
