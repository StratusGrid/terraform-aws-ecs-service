variable "appspec_hook_after_allow_test_traffic" {
  description = "Name of the Lambda function to invoke during the AfterAllowTestTraffic application deployment hook"
  type        = string
  default     = ""
}

variable "appspec_hook_after_allow_traffic" {
  description = "Name of the Lambda function to invoke during the AfterAllowTraffic deployment hook"
  type        = string
  default     = ""
}

variable "appspec_hook_after_install" {
  description = "Name of the Lambda function to invoke during the AfterInstall application deployment hook"
  type        = string
  default     = ""
}

variable "appspec_hook_before_allow_traffic" {
  description = "Name of the Lambda function to invoke during the BeforeAllowTraffic deployment hook"
  type        = string
  default     = ""
}

variable "appspec_hook_before_install" {
  description = "Name of the Lambda function to invoke during the BeforeInstall application deployment hook"
  type        = string
  default     = ""
}

variable "assign_public_ip" {
  description = "Boolean to indicate whether to assign public IPs to task network interfaces"
  type        = bool
  default     = false
}

variable "codedeploy_auto_rollback_enabled" {
  description = "Boolean to determine whether CodeDeploy should automatically roll back when a rollback event is triggered"
  type        = bool
  default     = true
}

variable "codedeploy_auto_rollback_events" {
  description = "CodeDeploy rollback events which will trigger an automatic rollback"
  type        = list(string)
  default = [
    "DEPLOYMENT_FAILURE",
    "DEPLOYMENT_STOP_ON_ALARM",
    "DEPLOYMENT_STOP_ON_REQUEST"
  ]
}

variable "codedeploy_deployment_configuration_name" {
  description = "CodeDeploy predefined deployment configuration name. See https://docs.aws.amazon.com/codedeploy/latest/userguide/deployment-configurations.html for valid predefined configurations."
  type        = string
  default     = "CodeDeployDefault.ECSAllAtOnce"
}

variable "codedeploy_role_additional_policies" {
  description = "Map of additional policies to attach to the CodeDeploy role. Should be formatted as {key = arn}"
  type        = map(string)
  default     = {}
}

variable "codedeploy_termination_wait_time" {
  description = "Wait time in seconds for CodeDeploy to wait before terminating previous production tasks after redirecting traffic to the new tasks"
  type        = number
  default     = 300
}

variable "codepipeline_container_definitions" {
  description = "This is the template container definition which CodePipeline will interpolate and deploy the service with CodeDeploy."
  type        = string
}
variable "codepipeline_source_bucket_id" {
  description = "S3 bucket where the output artifact zip should be placed (appspec and task definition) to be pulled into pipeline as a source. This bucket should be the same for all services which are deployed from a single contiguous CodePipeline because CodePipeline needs a single bucket to use for all artifacts across all Actions. Must be reachable by principal applying TF and the CodeDeploy Group role."
  type        = string
}

variable "codepipeline_source_bucket_kms_key_arn" {
  description = "ARN of the KMS key used to encrypt objects in the bucket used to store and retrieve artifacts for the codepipeline. This KMS key should be the same for all services which are deployed from a single contiguous CodePipeline because CodePipeline needs a single KMS key to use for all artifacts across all Actions. If referencing the aws_kms_key resource, use the arn attribute. If referencing the aws_kms_alias data source or resource, use the target_key_arn attribute."
  type        = string
}

variable "codepipeline_source_object_key" {
  description = "Key for zip file inside of S3 bucket whhich CodePipeline pulls in as a source stage.  Must be reachable by principal applying TF and the CodeDeploy Group role."
  type        = string
}

variable "custom_capacity_provider_strategy" {
  description = "Map to define the custom capacity provider strategy for the service. This would be used to utilize Fargate Spot for instance."
  type        = map(string)
  default     = {}
}

variable "desired_count" {
  description = "Number of tasks to run before autoscaling changes"
  type        = number
  default     = 2
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster to deploy the service to"
  type        = string
}

variable "enable_execute_command" {
  description = "Enable ecs container exec for container cli access"
  type        = bool
  default     = true
}

variable "health_check_grace_period_seconds" {
  description = "Number of seconds before a failing healthcheck on a new ecs task will kill the task"
  type        = number
  default     = 60
}

variable "initialization_container_definitions" {
  description = "This is the placeholder container definition that the cluster will be provisioned with. It does not need to be working and will be replaced on the first CodeDeploy execution."
  type        = string
}

variable "input_tags" {
  description = "Map of tags to apply to resources"
  type        = map(string)
  default = {
    Developer   = "StratusGrid"
    Provisioner = "Terraform"
  }
}

variable "lb_container_name" {
  description = "Name of container in the task's container definition which is attached to the load balancer"
  type        = string
}

variable "lb_container_port" {
  description = "Exposed container port, must match the task's container definition and will be attached to the load balancer"
  type        = number
}

variable "lb_listener_prod_arn" {
  description = "CodeDeploy group production traffic listener"
  type        = string
}

variable "lb_listener_test_arn" {
  description = "CodeDeploy group test traffic listener"
  type        = string
}

variable "lb_target_group_blue_arn" {
  description = "ARN of target group to be used as blue in CodeDeploy deployment style"
  type        = string
}

variable "lb_target_group_blue_name" {
  description = "Name of target group to be used as blue in CodeDeploy deployment style"
  type        = string
}

variable "lb_target_group_green_name" {
  description = "ARN of target group to be used as green in CodeDeploy deployment style"
  type        = string
}

variable "log_group_path" {
  description = "Cloudwatch log group path"
  type        = string
}

variable "log_retention_days" {
  description = "Number of days CloudWatch Log Group should retain logs from this service for"
  type        = number
  default     = 30
}

variable "platform_version" {
  description = "ECS platform version to use"
  type        = string
  default     = "1.4.0"
}

variable "propagate_tags" {
  description = "Setting to determine where to replicate tags to"
  type        = string
  default     = "TASK_DEFINITION"
}

variable "security_groups" {
  description = "Security groups to attach to task network interfaces"
  type        = list(string)
}

variable "service_name" {
  description = "Name of ECS Service"
  type        = string
}

variable "service_registries" {
  description = "Service discovery registries to attach to the service. AWS currently only supports a single registry."
  type        = map(string)
  default     = {}
}

variable "subnets" {
  description = "Subnets to attach task network interfaces to"
  type        = list(string)
}

variable "taskdef_cpu" {
  description = "CPU units to allocate to the task"
  type        = number
}

variable "taskdef_efs_volume_configurations" {
  description = "A map of EFS volume configurations for use in the ECS task definition."

  type = map(object({
    file_system_id          = string
    root_directory          = string
    # transit_encryption      = string # Optional - Valid values: "ENABLED" or "DISABLED". Specifies whether to enable encryption of data in transit between the ECS task and the EFS file system.
    transit_encryption_port = number # Optional - Specifies the port to use for encryption of data in transit between the ECS task and the EFS file system.
    authorization_config = optional(object({
      access_point_id = string # Optional - ID of the EFS access point to use for the volume.
      iam = string # Optional - Valid values: "ENABLED" or "DISABLED". Whether to use IAM to authenticate access to the EFS file system.
    }))
  }))

  default = null
}

variable "taskdef_execution_role_arn" {
  description = "Execution role for ECS to use when provisioning the tasks. Used for things like pulling ecr images, emitting logs, getting secrets to inject, etc."
  type        = string
}

variable "taskdef_family" {
  description = "Task Definition name which is then versioned. Should match the service name."
  type        = string
}

variable "taskdef_memory" {
  description = "MB of memory to allocate to the task"
  type        = number
}

variable "taskdef_network_mode" {
  description = "Network mode for task network interfaces, should always be awsvpc for Fargate"
  type        = string
  default     = "awsvpc"
}

variable "taskdef_requires_compatibilities" {
  description = "ECS compatibilities to help determine task placement"
  type        = list(string)
  default = [
    "FARGATE"
  ]
}

variable "taskdef_task_role_arn" {
  description = "Role attached to ECS tasks to give them access to resources"
  type        = string
}

variable "trusted_account_numbers" {
  description = "List of 12-digit AWS account numbers which can assume the IAM Role which has rights to trigger the CodeDeploy Deployment. This can be used to allow the CodeDeploy to be triggered from another account(s). String type for use in IAM policy."
  type        = list(string)
}

variable "use_custom_capacity_provider_strategy" {
  description = "Boolean to enable a custom capacity provider strategy for the ecs service. This would be used to utilize Fargate Spot for instance."
  type        = bool
  default     = false
}

