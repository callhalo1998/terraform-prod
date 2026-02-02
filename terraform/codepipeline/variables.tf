variable "pipeline_name" {
  description = "Name of the CodePipeline"
  type        = string
  default     = null
}

variable "codepipeline_role_arn" {
  description = "IAM Role ARN that CodePipeline assumes"
  type        = string
  default     = null
}

variable "artifact_bucket_name" {
  description = "S3 bucket name used to store pipeline artifacts"
  type        = string
  default     = null
}

variable "artifact_store_type" {
  description = "Type of artifact store (typically 'S3')"
  type        = string
  default     = "S3"
}

# ─── Source Stage ─────────────────────────────────────────────
variable "source_stage_name" {
  description = "Name of the source stage"
  type        = string
  default     = "Source"
}

variable "source_action_name" {
  description = "Name of the action in the source stage"
  type        = string
  default     = "Source"
}

variable "source_action_category" {
  description = "Category of the source action"
  type        = string
  default     = "Source"
}

variable "source_action_owner" {
  description = "Owner of the source action"
  type        = string
  default     = "AWS"
}

variable "source_action_provider" {
  description = "Provider for the source action (e.g., S3)"
  type        = string
  default     = "S3"
}

variable "source_action_version" {
  description = "Version of the source action provider"
  type        = string
  default     = "1"
}

variable "source_configuration" {
  description = "Configuration map for source stage, keys depend on source provider"
  type        = map(string)
  default     = {}
}

# ─── Build Stage ─────────────────────────────────────────────
variable "build_stage_name" {
  description = "Name of the build stage"
  type        = string
  default     = "Build"
}

variable "build_action_name" {
  description = "Name of the action in the build stage"
  type        = string
  default     = "Build"
}

variable "build_action_category" {
  description = "Category of the build action"
  type        = string
  default     = "Build"
}

variable "build_action_owner" {
  description = "Owner of the build action"
  type        = string
  default     = "AWS"
}

variable "build_action_provider" {
  description = "Provider for the build action (e.g., CodeBuild)"
  type        = string
  default     = "CodeBuild"
}

variable "build_action_version" {
  description = "Version of the build action provider"
  type        = string
  default     = "1"
}

variable "source_output_artifact" {
  description = "Input artifact for the build stage"
  type        = string
  default     = "SourceArtifact"
}

variable "build_output_artifact" {
  description = "Output artifact from the build stage"
  type        = string
  default     = "BuildArtifact"
}

# ─── Deploy Stage ─────────────────────────────────────────────
variable "deploy_stage_name" {
  description = "Name of the deploy stage"
  type        = string
  default     = "Deploy"
}

variable "deploy_action_name" {
  description = "Name of the action in the deploy stage"
  type        = string
  default     = "Deploy"
}

variable "deploy_action_category" {
  description = "Category of the deploy action"
  type        = string
  default     = "Deploy"
}

variable "deploy_action_owner" {
  description = "Owner of the deploy action"
  type        = string
  default     = "AWS"
}

variable "deploy_action_provider" {
  description = "Provider for the deploy action (e.g., ECS)"
  type        = string
  default     = "ECS"
}

variable "deploy_action_version" {
  description = "Version of the deploy action provider"
  type        = string
  default     = "1"
}

variable "ecs_cluster_name" {
  description = "ECS cluster name used in the deploy stage"
  type        = string
  default     = null
}

variable "ecs_service_name" {
  description = "ECS service name used in the deploy stage"
  type        = string
  default     = null
}

variable "image_definitions_file" {
  description = "JSON file containing image definitions for ECS"
  type        = string
  default     = "imagedefinitions.json"
}

variable "name" {
  description = "Name of the CodeBuild project"
  type        = string
  default     = null
}

variable "project_description" {
  description = "Description of the CodeBuild project"
  type        = string
  default     = null
}

variable "build_timeout" {
  description = "Timeout in minutes for the build"
  type        = number
  default     = 60
}

variable "codebuild_role_arn" {
  description = "IAM role ARN that CodeBuild will assume"
  type        = string
  default     = null
}

variable "artifact_type" {
  description = "Type of artifact output (e.g., CODEPIPELINE)"
  type        = string
  default     = "CODEPIPELINE"
}

variable "compute_type" {
  description = "Compute type for CodeBuild environment"
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
}

variable "build_image" {
  description = "Docker image used for CodeBuild"
  type        = string
  default     = "aws/codebuild/standard:5.0"
}

variable "environment_type" {
  description = "Type of the build environment"
  type        = string
  default     = "LINUX_CONTAINER"
}

variable "privileged_mode" {
  description = "Whether to enable privileged mode for Docker builds"
  type        = bool
  default     = true
}

variable "image_pull_credentials_type" {
  description = "Credentials type for pulling the build image"
  type        = string
  default     = "CODEBUILD"
}

variable "aws_account_id" {
  description = "AWS Account ID to pass as environment variable"
  type        = string
  default     = null
}

variable "aws_region" {
  description = "AWS Region to pass as environment variable"
  type        = string
  default     = null
}

variable "source_type" {
  description = "Source provider type (e.g., CODEPIPELINE)"
  type        = string
  default     = "CODEPIPELINE"
}

variable "buildspec_path" {
  description = "Optional buildspec file path (null = default buildspec.yml in repo)"
  type        = string
  default     = null
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
  default     = null
}

variable "deploy_bucket_name" {
  type        = string
  default     = null
}

variable "deploy_extract" {
  type        = bool
  default     = true
}

variable "deploy_stage_enabled" {
  type        = bool
  default     = true
}

variable "deploy_object_key" {
  type        = string
  default     = null
}

variable "enable_local_cache" {
  type = bool
  default = true
}

variable "cache_modes" {
  type = list(string)
  default = ["LOCAL_DOCKER_LAYER_CACHE"]
}

variable "codedeploy_application_name" {
  description = "Name of the AWS CodeDeploy application (must match aws_codedeploy_app.name)."
  type        = string
  default     = ""
}

variable "codedeploy_deployment_group_name" {
  description = "Name of the AWS CodeDeploy deployment group (must match aws_codedeploy_deployment_group.deployment_group_name)."
  type        = string
  default     = ""
}

variable "enable_blue_green" {
  type        = bool
  default     = false
}

variable "codedeploy_role_arn" {
  type        = string
  default     = ""
}

variable "blue_target_group_name" {
  type        = string
  default     = ""
}

variable "green_target_group_name" {
  type        = string
  default     = ""
}

variable "prod_listener_arn" {
  type        = string
  default     = ""
}

variable "test_listener_arn" {
  type        = string
  default     = ""
}

variable "blue_tg_name" {
  description = "Name of the BLUE target group"
  type        = string
}

variable "green_tg_name" {
  description = "Name of the GREEN target group"
  type        = string
}

variable "codebuild_projects" {
  type        = any
}

variable "source_actions" {
  type        = any
}

variable "build_actions" {
  type        = any
}
