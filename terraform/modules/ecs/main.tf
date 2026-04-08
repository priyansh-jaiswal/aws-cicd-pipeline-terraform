# ── ECS Cluster ───────────────────────────────────────────────────
resource "aws_ecs_cluster" "app" {
  name = "${var.project}-cluster"
  tags = { Project = var.project }
}

# ── Security Group for ECS tasks ──────────────────────────────────
resource "aws_security_group" "ecs_sg" {
  name        = "${var.project}-ecs-sg"
  description = "Allow traffic from ALB to ECS"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Project = var.project }
}

# ── CloudWatch Log Group ──────────────────────────────────────────
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.project}"
  retention_in_days = 7
}

# ── ECS Task Definition ───────────────────────────────────────────
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  task_role_arn            = var.ecs_task_role_arn
  execution_role_arn       = var.ecs_exec_role_arn

  container_definitions = jsonencode([
    {
      name      = "flask-app"
      image     = "${var.ecr_repo_url}:latest"
      essential = true
      portMappings = [{
        containerPort = 5000
        hostPort      = 5000
        protocol      = "tcp"
      }]
      environment = [
        { name = "ENV",        value = "production" },
        { name = "AWS_REGION", value = var.aws_region }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project}"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = { Project = var.project }
}

# ── ECS Service ───────────────────────────────────────────────────
resource "aws_ecs_service" "app" {
  name            = "${var.project}-service"
  cluster         = aws_ecs_cluster.app.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnets
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "flask-app"
    container_port   = 5000
  }

  tags = { Project = var.project }
}
