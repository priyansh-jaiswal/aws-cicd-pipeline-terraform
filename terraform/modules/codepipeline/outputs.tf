output "pipeline_name" {
  description = "CodePipeline name"
  value       = aws_codepipeline.app.name
}

output "pipeline_arn" {
  description = "CodePipeline ARN"
  value       = aws_codepipeline.app.arn
}

output "artifacts_bucket" {
  description = "S3 artifacts bucket name"
  value       = aws_s3_bucket.artifacts.bucket
}
