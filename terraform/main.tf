terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
}

# ── ECR Module ───────────────────────────────────────────────────
module "ecr" {
  source  = "./modules/ecr"
  project = var.project
}

# ── IAM Module ───────────────────────────────────────────────────
module "iam" {
  source      = "./modules/iam"
  project     = var.project
  aws_account = var.aws_account_id
  aws_region  = var.aws_region
}

# ── ALB Module ───────────────────────────────────────────────────
module "alb" {
  source  = "./modules/alb"
  project = var.project
  vpc_id  = var.vpc_id
  subnets = var.subnet_ids
}

# ── ECS Module ───────────────────────────────────────────────────
module "ecs" {
  source              = "./modules/ecs"
  project             = var.project
  aws_region          = var.aws_region
  ecr_repo_url        = module.ecr.repository_url
  ecs_task_role_arn   = module.iam.ecs_task_role_arn
  ecs_exec_role_arn   = module.iam.ecs_exec_role_arn
  target_group_arn    = module.alb.target_group_arn
  alb_sg_id           = module.alb.alb_sg_id
  vpc_id              = var.vpc_id
  subnets             = var.subnet_ids
}

# ── CodePipeline Module ──────────────────────────────────────────
module "codepipeline" {
  source                = "./modules/codepipeline"
  project               = var.project
  aws_region            = var.aws_region
  ecr_repo_url          = module.ecr.repository_url
  ecr_repo_name         = module.ecr.repository_name
  ecs_cluster_name      = module.ecs.cluster_name
  ecs_service_name      = module.ecs.service_name
  codepipeline_role_arn = module.iam.codepipeline_role_arn
  codebuild_role_arn    = module.iam.codebuild_role_arn
  github_owner          = var.github_owner
  github_repo           = var.github_repo
  github_branch         = var.github_branch
  github_token          = var.github_token
}
