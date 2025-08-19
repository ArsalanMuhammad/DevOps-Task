########################
# ===== ECR ===========
########################
resource "aws_ecr_repository" "frontend" {
  name                 = "${var.project}-frontend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration { scan_on_push = true }
  tags = { Name = "${var.project}-frontend-ecr" }
}

########################
# ===== ECS Fargate ===
########################
resource "aws_ecs_cluster" "frontend" {
  name = "${var.project}-frontend-cluster"
}

# Execution role for ECS
resource "aws_iam_role" "ecs_task_exec" {
  name               = "${var.project}-ecsTaskExecRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
}

data "aws_iam_policy_document" "ecs_task_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}


resource "aws_iam_role_policy_attachment" "ecs_exec" {
  role       = aws_iam_role.ecs_task_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Simple container task (Node/NGINX demo on port 3000)
resource "aws_ecs_task_definition" "frontend" {
  family                   = "${var.project}-frontend-td"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_exec.arn

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = "${aws_ecr_repository.frontend.repository_url}:latest" # push your image
      essential = true
      portMappings = [{ containerPort = 3000, hostPort = 3000, protocol = "tcp" }]
      environment = [{ name = "API_BASE_URL", value = aws_apigatewayv2_api.http_api.api_endpoint }]
    }
  ])
}

resource "aws_ecs_service" "frontend" {
  name            = "${var.project}-frontend-svc"
  cluster         = aws_ecs_cluster.frontend.id
  task_definition = aws_ecs_task_definition.frontend.arn
  launch_type     = "FARGATE"
  desired_count   = 2

  network_configuration {
    subnets         = [for s in aws_subnet.private : s.id]
    security_groups = [aws_security_group.ecs_task.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "frontend"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.http]
}
