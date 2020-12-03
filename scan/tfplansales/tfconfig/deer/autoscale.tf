resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = var.max
  min_capacity       = var.min
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.ecs_service.name}"
  role_arn           = data.aws_iam_role.iam_role.arn
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_cpu_autoscaling" {
  name               = "${var.project_name}-ecs-cpu-autoscaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = var.target_value
    scale_in_cooldown  = var.scale_in_cooldown
    scale_out_cooldown = var.scale_out_cooldown
  }
}
