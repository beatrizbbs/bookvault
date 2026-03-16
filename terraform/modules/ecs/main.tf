locals {
  cluster_name     = "${var.name}-cluster"
  service_name     = "${var.name}-service"
  task_family_name = "${var.name}-task"
  log_group_name   = "/ecs/${var.name}"
}

data "aws_iam_policy_document" "task_execution_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "task_execution" {
  name               = "${var.name}-task-exec-role"
  assume_role_policy = data.aws_iam_policy_document.task_execution_assume_role.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "task_execution_secrets" {
  count = length(var.secrets_access_arns) > 0 ? 1 : 0

  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = var.secrets_access_arns
  }
}

resource "aws_iam_role_policy" "task_execution_secrets" {
  count = length(var.secrets_access_arns) > 0 ? 1 : 0

  name   = "${var.name}-task-exec-secrets"
  role   = aws_iam_role.task_execution.id
  policy = data.aws_iam_policy_document.task_execution_secrets[0].json
}

resource "aws_cloudwatch_log_group" "this" {
  name              = local.log_group_name
  retention_in_days = var.log_retention_in_days

  tags = var.tags
}

resource "aws_ecs_cluster" "this" {
  name = local.cluster_name

  tags = var.tags
}

resource "aws_security_group" "ecs_service" {
  name        = "${var.name}-ecs-sg"
  description = "ECS service security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
    description     = "Allow ALB to reach ECS tasks"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow outbound internet access through NAT"
  }

  tags = merge(var.tags, { Name = "${var.name}-ecs-sg" })
}

resource "aws_ecs_task_definition" "this" {
  family                   = local.task_family_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tostring(var.cpu)
  memory                   = tostring(var.memory)
  execution_role_arn       = aws_iam_role.task_execution.arn

  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = var.image
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
      environment = var.environment_variables
      secrets = [
        for secret in var.secrets : {
          name      = secret.name
          valueFrom = secret.value_from
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = var.tags
}

resource "aws_ecs_service" "this" {
  name            = local.service_name
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_service.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  depends_on = [aws_iam_role_policy_attachment.task_execution]

  tags = var.tags
}
