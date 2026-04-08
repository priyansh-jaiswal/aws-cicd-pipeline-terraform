# ── S3 bucket for pipeline artifacts ─────────────────────────────
resource "aws_s3_bucket" "artifacts" {
  bucket        = "${var.project}-artifacts-${random_id.suffix.hex}"
  force_destroy = true
  tags          = { Project = var.project }
}

resource "random_id" "suffix" {
  byte_length = 4
}

# ── CodeBuild Project ─────────────────────────────────────────────
resource "aws_codebuild_project" "app" {
  name          = "${var.project}-build"
  service_role  = var.codebuild_role_arn
  build_timeout = 20

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "ECR_REPO_URI"
      value = var.ecr_repo_url
    }

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }

  tags = { Project = var.project }
}

# ── CodePipeline ──────────────────────────────────────────────────
resource "aws_codepipeline" "app" {
  name     = "${var.project}-pipeline"
  role_arn = var.codepipeline_role_arn

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"
  }

  # ── Stage 1: Source (GitHub) ──────────────────────────────────
  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner      = var.github_owner
        Repo       = var.github_repo
        Branch     = var.github_branch
        OAuthToken = var.github_token
      }
    }
  }

  # ── Stage 2: Build (CodeBuild) ────────────────────────────────
  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.app.name
      }
    }
  }

  # ── Stage 3: Deploy (ECS) ─────────────────────────────────────
  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ClusterName = var.ecs_cluster_name
        ServiceName = var.ecs_service_name
        FileName    = "imagedefinitions.json"
      }
    }
  }

  tags = { Project = var.project }
}
