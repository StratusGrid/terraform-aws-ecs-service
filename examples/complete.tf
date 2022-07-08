locals {
  ecs_cluster_name = "${var.name_prefix}-ecs-cluster${local.name_suffix}"
  ecs_service_name      = "${var.name_prefix}-ecs-service${local.name_suffix}"
  ecs_service_log_group = "/ecs/${local.ecs_cluster_name}/${local.ecs_service_name}"
}

resource "aws_lambda_function" "test_lambda" {
  filename      = "lambda_function_payload.zip"
  function_name = "lambda_function_name"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "index.test"

  source_code_hash = filebase64sha256("lambda_function_payload.zip")

  runtime = "nodejs12.x"

  environment {
    variables = {
      foo = "bar"
    }
  }
}

module "service_alb_sg" {
  source  = "registry.terraform.io/terraform-aws-modules/security-group/aws"
  version = "~>4.0"

  name            = "${var.name_prefix}-ecs-alb-sg${local.name_suffix}"
  use_name_prefix = false
  description     = "Security group to allow inbound traffic to the service load balancer."
  vpc_id          = data.aws_vpc.this.id

  ingress_cidr_blocks = [
    "192.168.0.0/16"
  ]
  egress_rules = ["all-all"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "Allow access to service port."
    },
  ]
}

module "service_alb" {
  source  = "registry.terraform.io/terraform-aws-modules/alb/aws"
  version = "~> 6.0"

  name = "${var.name_prefix}-alb${local.name_suffix}"

  enable_deletion_protection = true

  load_balancer_type = "application"
  internal           = true
  vpc_id             = data.aws_vpc.this.id
  subnets            = data.aws_subnet_ids.private_subnets.ids
  security_groups    = [module.service_alb_sg.security_group_id]

  # Configure logging bucket if it is enabled
  access_logs = var.alb_logging_enabled ? {
    bucket = var.logging_bucket
    #prefix = "alb"
  } : {}

  target_groups = [
    {
      name             = "${var.name_prefix}-tg-blue${local.name_suffix}"
      backend_protocol = "HTTP"
      protocol_version = "HTTP1"
      backend_port     = 80
      target_type      = "ip"

      health_check = {
        enabled             = true
        interval            = 30
        path                = "/heartbeat"
        port                = 80
        protocol            = "HTTP"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 5
      }
    },
    {
      name             = "${var.name_prefix}-tg-green${local.name_suffix}"
      backend_protocol = "HTTP"
      protocol_version = "HTTP1"
      backend_port     = 80
      target_type      = "ip"

      health_check = {
        enabled             = true
        interval            = 30
        path                = "/heartbeat"
        port                = 80
        protocol            = "HTTP"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 5
      }
    }
  ]

  tags = merge(local.common_tags, {})
}

resource "aws_alb_listener" "service_alb_listener_blue" {
  load_balancer_arn = module.service_alb.lb_arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = module.service_alb.target_group_arns[0]
  }

  lifecycle {
    ignore_changes = [
      default_action
    ]
  }
}

resource "aws_alb_listener" "service_alb_listener_green" {
  load_balancer_arn = module.service_alb.lb_arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = module.service_alb.target_group_arns[1]
  }

  lifecycle {
    ignore_changes = [
      default_action
    ]
  }
}

resource "aws_ecs_cluster" "this" {
  name               = local.ecs_cluster_name
  tags               = merge(local.common_tags, {})
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name = aws_ecs_cluster.this.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}


module "ecs_service_sg" {
  source  = "registry.terraform.io/terraform-aws-modules/security-group/aws"
  version = "~> 4.3"

  name        = "${var.name_prefix}-ecs-service-sg${local.name_suffix}"
  description = "SG for the ECS Service"
  vpc_id      = data.aws_vpc.this.id

  egress_rules = ["all-all"]

  ingress_with_source_security_group_id = [
    {
      rule                     = "all-all"
      description              = "Allow all traffic from ALB."
      source_security_group_id = module.allowed_sg.security_group_id
    }
  ]
}


resource "aws_appautoscaling_target" "ecs_service" {
  resource_id        = "service/${local.ecs_cluster_name}/${local.ecs_service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  max_capacity       = var.ecs_service_max_capacity
  min_capacity       = var.ecs_service_min_capacity
  depends_on         = [module.ecs_fargate_service]
}

resource "aws_appautoscaling_policy" "ecs_service" {
  name               = "${var.name_prefix}-service-autoscaling-policy${local.name_suffix}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_service.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_service.service_namespace

  target_tracking_scaling_policy_configuration {
    disable_scale_in   = false
    scale_in_cooldown  = var.ecs_scale_in_cooldown
    scale_out_cooldown = var.ecs_scale_out_cooldown
    target_value       = var.ecs_autoscaling_metric_target_value

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

module "ecs_fargate_service" {
    source  = "registry.terraform.io/StratusGrid/ecs-service/aws"
    version = "~> 1.0"

  input_tags       = merge(local.common_tags, {})
  ecs_cluster_name = aws_ecs_cluster.this.name
  service_name     = local.ecs_service_name
  taskdef_family   = local.ecs_service_name
  platform_version = "1.4.0"
  log_group_path   = local.ecs_service_log_group

  codedeploy_termination_wait_time = var.termination_wait_time

  desired_count  = var.ecs_service_task_desired_count
  taskdef_cpu    = var.ecs_service_taskdef_cpu
  taskdef_memory = var.ecs_service_taskdef_memory

  trusted_account_numbers = var.ecs_deploy_trusted_accounts

  subnets         = data.aws_subnet_ids.private_subnets.ids
  security_groups = [module.ecs_service_sg.security_group_id]

  #NOTE: ALBs are not created by the module.
  health_check_grace_period_seconds = 60
  lb_listener_prod_arn              = aws_alb_listener.service_alb_listener_blue.arn
  lb_listener_test_arn              = aws_alb_listener.service_alb_listener_green.arn
  lb_target_group_blue_arn          = module.service_alb.target_group_arns[0]
  lb_target_group_blue_name         = module.service_alb.target_group_names[0]
  lb_target_group_green_name        = module.service_alb.target_group_names[1]
  lb_container_name                 = "service" # has to match name in container definition within task_definition
  lb_container_port                 = 80         # has to match name in container definition within task_definition

  codepipeline_source_bucket_id          = var.codepipeline_source_bucket_id
  codepipeline_source_bucket_kms_key_arn = var.codepipeline_source_bucket_kms_key_arn
  codepipeline_source_object_key         = "deployment/ecs/service-artifacts.zip"

  # Include Lambdas by name to invoke as deployment hooks in the appspec as required
  appspec_hook_after_install = aws_lambda_function.test_lambda.function_name

  taskdef_execution_role_arn = module.ecs_service_iam_role.iam_role_arn
  taskdef_task_role_arn      = module.ecs_service_iam_role.iam_role_arn

  # This is just an initial definition, not codedeploy
  ### This is only needed because you can't put <> in the image field
  initialization_container_definitions = <<EOF
[
  {
    "name": "service",
    "image": "IMAGE1_NAME",
    "portMappings": [
      {
        "hostPort": 80,
        "protocol": "tcp",
        "containerPort": 80
      }
    ]
  }
]
EOF
  codepipeline_container_definitions   = <<EOF
[
  {
    "name": "service",
    "image": "<IMAGE1_NAME>",
    "cpu": ${var.ecs_service_container_cpu},
    "memory": ${var.ecs_service_container_memory},
    "memoryReservation": ${var.ecs_service_container_memory_reservation},
    "essential": true,
		"logConfiguration": {
      "logDriver": "awslogs",
      "secretOptions": null,
      "options": {
        "awslogs-group": "${local.ecs_service_log_group}",
        "awslogs-region": "${data.aws_region.current.name}",
        "awslogs-stream-prefix": "ecs"
      }
    },
    "secrets": [
    ],
    "portMappings": [
      {
        "hostPort": 80,
        "protocol": "tcp",
        "containerPort": 80
      }
    ]
  }
 ]
EOF
}
