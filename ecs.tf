# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html

data "aws_iam_policy_document" "assumeRolePolicy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecsRole" {
  name               = "reshuffle-${var.system}-ecs"
  assume_role_policy = data.aws_iam_policy_document.assumeRolePolicy.json
  tags               = local.defaultTags
}

resource "aws_iam_role_policy_attachment" "ecsRolePolicy" {
  role       = aws_iam_role.ecsRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_cloudwatch_log_group" "logs" {
  name              = "/fargate/service/reshuffle-${var.system}"
  retention_in_days = var.logRetentionDays
  tags              = local.defaultTags
}

resource "aws_ecs_cluster" "ecsCluster" {
  name = "reshuffle-${var.system}-ecs"
  tags = local.defaultTags
}

resource "aws_ecs_task_definition" "ecsTask" {
  family                   = "reshuffle-${var.system}-ecs-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.containerCPU
  memory                   = var.containerMemory
  execution_role_arn       = aws_iam_role.ecsRole.arn
  tags                     = local.defaultTags

  container_definitions = <<DEFINITION
[
  {
    "name": "reshuffle-${var.system}-container",
    "image": "${var.containerImage}",
    "essential": true,
    "portMappings": [
      {
        "protocol": "tcp",
        "containerPort": ${var.containerPort},
        "hostPort": ${var.containerPort}
      }
    ],
    "environment": [
      {
        "name": "CONFIG",
        "value": "${var.config}"
      },
      {
        "name": "DATABASE_URL",
        "value": "${0 < var.dbInstanceCount ? "postgres://${aws_db_instance.primary[0].username}:${aws_db_instance.primary[0].password}@${aws_db_instance.primary[0].endpoint}/${aws_db_instance.primary[0].name}" : ""}"
      },
      {
        "name": "NODE_ENV",
        "value": "${var.nodeEnv}"
      },
      {
        "name": "PORT",
        "value": "${var.containerPort}"
      },
      {
        "name": "STUDIO_CLIENT_ID",
        "value": "${var.studioClientID}"
      },
      {
        "name": "STUDIO_CLIENT_SECRET",
        "value": "${var.studioClientSecret}"
      },
      {
        "name": "CLIENT_USERNAME",
        "value": "${var.studioClientUsername}"
      },
      {
        "name": "CLIENT_PASSWORD",
        "value": "${var.studioClientPassword}"
      },
      {
        "name": "STUDIO_BASE_URL",
        "value": "${var.studioBaseURL}"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/fargate/service/reshuffle-${var.system}",
        "awslogs-region": "${var.region}",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]
DEFINITION
}

resource "aws_ecs_service" "ecsService" {
  name                    = "reshuffle-${var.system}-service"
  cluster                 = aws_ecs_cluster.ecsCluster.id
  launch_type             = "FARGATE"
  task_definition         = aws_ecs_task_definition.ecsTask.arn
  desired_count           = var.cotainerCount
  # tags                    = local.defaultTags
  # enable_ecs_managed_tags = true
  # propagate_tags          = "SERVICE"

  network_configuration {
    security_groups  = [aws_security_group.sgecs.id]
    subnets          = aws_subnet.subnet.*.id
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.lbTargetGroup.id
    container_name   = "reshuffle-${var.system}-container"
    container_port   = var.containerPort
  }

  # workaround for https://github.com/hashicorp/terraform/issues/12634
  depends_on = [aws_lb_listener.lbListener]
}
