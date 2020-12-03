locals {
  server_url   = aws_route53_record.route53_record.fqdn
  image        = "docker.deere.com/${lower(var.org_name)}/${var.project_name}:${var.git_commit}"
  vpc_name_tag = "aws-isg-apps-*${var.environment_name}-useast1-vpn"
  appVersion = "AppVersion"

  default_tags = {
    Name      = var.name_tag
    component = var.component_tag
    github    = "https://github.deere.com/${var.org_name}/${var.project_name}.git"
  }
}

variable "git_commit" {
  description = "The git commit hash."
}

variable health_endpoint {
  type        = "string"
  default     = "/health/IafHATH/ping"
  description = "Health endpoint for the application. Should return a 200 response when app is healthy"
}

variable project_name {
  type        = "string"
  default     = "isg-sales-report-service"
  description = "Name of the application"
}

variable cluster_name {
  type        = "string"
  default     = "isg-sales-report-service-fargate"
  description = "The name of the ecs cluster to host your task/service on."
}

variable component_tag {
  type        = "string"
  default     = "isg-sales"
  description = "The component tag to attach to your aws resources. Managed  at https://mycloud.deere.com/mycloud/components/list"
}

variable "name_tag" {
  type        = "string"
  default     = "isg-sales-report-service"
  description = "The 'Name' tag to attach to your AWS resources."
}

variable "org_name" {
  type        = "string"
  default     = "ISGSalesSystem"
  description = "The name of your GitHub Organization that your code lives in."
}

variable "container_port" {
  type        = "string"
  default     = 3000
  description = "The port that your application listens for traffic on."
}

variable "region" {
  type        = "string"
  default     = "us-east-1"
  description = "The region to run your aws infrastructure in."
}

variable "environment_name" {
  type        = "string"
  description = "Name of the current environment"
}

variable "cpu" {
  type        = "string"
  default     = "256"
  description = "Number of cpu units used by the task"
}

variable "memory" {
  type        = "string"
  default     = "512"
  description = "Memory amount in MiB used by the task"
}

variable "min" {
  type        = "string"
  default     = 2
  description = "The minimum number of instance to scale in. This value is also used as desired_count for initial deployment which is ignored in later deployment"
}

variable "max" {
  type        = "string"
  default     = 4
  description = "The maximum number of instance to scale out."
}

variable "target_value" {
  type        = "string"
  default     = 60
  description = "The target value for CPU metric for scaling policy."
}

variable "scale_in_cooldown" {
  type        = "string"
  default     = 300
  description = "Time in seconds, after a scale in activity completes before another scale in activity can start."
}

variable "scale_out_cooldown" {
  type        = "string"
  default     = 300
  description = "Time, in seconds, after a scale out activity completes before another scale out activity can start."
}

variable "AppVersion" {
  type = "string"
}
