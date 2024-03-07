resource "aws_ecs_task_definition" "this" {

  family                   = var.taskdef_family
  execution_role_arn       = var.taskdef_execution_role_arn
  task_role_arn            = var.taskdef_task_role_arn
  network_mode             = var.taskdef_network_mode
  requires_compatibilities = var.taskdef_requires_compatibilities
  cpu                      = var.taskdef_cpu
  memory                   = var.taskdef_memory

  dynamic "volume" {
    for_each = var.taskdef_efs_volume_configurations != null ? [1] : []
    content {
    name      = volume.key

    dynamic "efs_volume_configuration" {
        for_each = var.taskdef_efs_volume_configurations != null ? var.taskdef_efs_volume_configurations : {}
        content {
          file_system_id          = efs_volume_configuration.value["file_system_id"]
          root_directory          = efs_volume_configuration.value["root_directory"]
          transit_encryption      = efs_volume_configuration.value["transit_encryption"]
          transit_encryption_port = efs_volume_configuration.value["transit_encryption_port"]

          dynamic "authorization_config" {
            for_each = efs_volume_configuration.value["authorization_config"] != null ? [1] : []
            content {
              access_point_id = efs_volume_configuration.value["authorization_config"]["access_point_id"]
              iam             = efs_volume_configuration.value["authorization_config"]["iam"]
            }
          }
        }
      }
    }
  }

  tags = merge(local.common_tags, {})

  container_definitions = var.initialization_container_definitions
}


resource "aws_ecs_service" "this" {

  name             = var.service_name
  cluster          = "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${var.ecs_cluster_name}"
  task_definition  = aws_ecs_task_definition.this.arn
  desired_count    = var.desired_count
  launch_type      = var.use_custom_capacity_provider_strategy == true ? null : "FARGATE"
  platform_version = var.platform_version
  propagate_tags   = var.propagate_tags

  network_configuration {
    security_groups  = var.security_groups
    subnets          = var.subnets
    assign_public_ip = var.assign_public_ip
  }

  enable_execute_command = var.enable_execute_command

  dynamic "service_registries" {
    for_each = var.service_registries
    content {
      registry_arn = service_registries.value
    }
  }

  dynamic "capacity_provider_strategy" {
    for_each = var.custom_capacity_provider_strategy
    content {
      base              = lookup(var.custom_capacity_provider_strategy, "primary_capacity_provider_base")
      capacity_provider = lookup(var.custom_capacity_provider_strategy, "primary_capacity_provider")
      weight            = lookup(var.custom_capacity_provider_strategy, "primary_capacity_provider_weight")
    }
  }

  dynamic "capacity_provider_strategy" {
    for_each = var.custom_capacity_provider_strategy
    content {
      capacity_provider = lookup(var.custom_capacity_provider_strategy, "secondary_capacity_provider")
      weight            = lookup(var.custom_capacity_provider_strategy, "secondary_capacity_provider_weight")
    }
  }

  health_check_grace_period_seconds = var.health_check_grace_period_seconds

  load_balancer {
    target_group_arn = var.lb_target_group_blue_arn
    container_name   = var.lb_container_name
    container_port   = var.lb_container_port
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  tags = merge(local.common_tags, {})

  #ignoring changes since codedeploy manages this after the initial deployment
  lifecycle {
    ignore_changes = [
      task_definition,
      load_balancer
    ]
  }
}
