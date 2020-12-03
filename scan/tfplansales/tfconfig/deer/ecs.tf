resource "aws_ecs_cluster" "cluster" {
    name = var.cluster_name
}

resource "aws_ecs_service" "ecs_service" {
  name                               = var.project_name
  cluster                            = aws_ecs_cluster.cluster.id
  task_definition                    = aws_ecs_task_definition.ecs_task_definition.family
  launch_type                        = "FARGATE"
  network_configuration {
    assign_public_ip = true
    subnets = data.aws_subnet_ids.vpn_subnets.ids
    security_groups = [
      aws_security_group.private_security_group.id
    ]
  }

  deployment_minimum_healthy_percent = "100"
  desired_count                      = var.min

  load_balancer {
    target_group_arn = aws_lb_target_group.aws_lb_target_group.arn
    container_name   = var.project_name
    container_port   = var.container_port
  }
  lifecycle {
    ignore_changes = ["desired_count"]
  }
}

data "template_file" "ecs_template_file" {
  template = file("task-definitions/service.json")

  vars = {
    cw_log_group     = aws_cloudwatch_log_group.log_group.name
    environment_name = var.environment_name
    git_commit       = var.git_commit
    project_name     = var.project_name
    container_port   = var.container_port
    image            = local.image
    region           = var.region
  }
}

resource "aws_ecs_task_definition" "ecs_task_definition" {
  family                   = var.project_name
  container_definitions    = data.template_file.ecs_template_file.rendered
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = data.aws_iam_role.iam_role.arn
  task_role_arn            = data.aws_iam_role.iam_role.arn
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory

  lifecycle {
    create_before_destroy = true
  }
}
