output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = module.ecr.repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = module.ecs.service_name
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = module.alb.alb_dns_name
}

output "codepipeline_name" {
  description = "CodePipeline name"
  value       = module.codepipeline.pipeline_name
}

output "app_url" {
  description = "Application URL"
  value       = "http://${module.alb.alb_dns_name}"
}
