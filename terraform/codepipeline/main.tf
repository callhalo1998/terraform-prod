terraform {
  backend "s3" {}
}

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.7.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
  }
}

# ------------------------------------------------------------------------------  
# CodeBuild
# ------------------------------------------------------------------------------

resource "aws_codebuild_project" "this" {
  for_each      = var.codebuild_projects

  name          = each.value.name
  description   = each.value.project_description
  build_timeout = each.value.build_timeout
  service_role  = var.codebuild_role_arn

  artifacts {
    type = each.value.artifact_type
  }

  environment {
    compute_type                = each.value.compute_type
    image                       = each.value.build_image
    type                        = each.value.environment_type
    privileged_mode             = each.value.privileged_mode
    image_pull_credentials_type = each.value.image_pull_credentials_type

    dynamic "environment_variable" {
      for_each = merge(
        {
          AWS_ACCOUNT_ID = var.aws_account_id
          AWS_REGION     = var.aws_region
        },
        each.value.environment_variables
      )
      content {
        name  = environment_variable.key
        value = environment_variable.value
      }
    }
  }

  source {
    type     = each.value.source_type
    buildspec = each.value.buildspec_path
  }

  dynamic "cache" {
    for_each = each.value.enable_local_cache ? [1] : []
    content {
      type  = "LOCAL"
      modes = each.value.cache_modes
    }
  }

  tags = {
    Name        = each.value.name
    Environment = each.value.environment
    Terraform   = "true"
  }
}

# ------------------------------------------------------------------------------  
# CodeDeploy
# ------------------------------------------------------------------------------

#--- CodeDeploy Application ---#
resource "aws_codedeploy_app" "this" {
  count            = var.enable_blue_green ? 1 : 0
  name             = var.codedeploy_application_name
  compute_platform = "ECS"
}

#--- CodeDeploy Deployment Group ---#
resource "aws_codedeploy_deployment_group" "this" {
  count                 = var.enable_blue_green ? 1 : 0
  app_name              = aws_codedeploy_app.this[0].name
  deployment_group_name = var.codedeploy_deployment_group_name
  service_role_arn      = var.codedeploy_role_arn

  deployment_style {
    deployment_type   = "BLUE_GREEN"
    deployment_option = "WITH_TRAFFIC_CONTROL"
  }

  blue_green_deployment_config {
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }

    deployment_ready_option {
      action_on_timeout = "STOP_DEPLOYMENT"
    }
  }

  ecs_service {
    cluster_name = var.ecs_cluster_name
    service_name = var.ecs_service_name
  }

  load_balancer_info {
    target_group_pair_info {
      target_group { name = var.blue_tg_name }
      target_group { name = var.green_tg_name }

      prod_traffic_route {
        listener_arns = [var.prod_listener_arn]
      }

      dynamic "test_traffic_route" {
        for_each = var.test_listener_arn == null ? [] : [1]
        content {
          listener_arns = [var.test_listener_arn]
        }
      }
    }
  }

  tags = {
    Name        = var.codedeploy_deployment_group_name
    Environment = var.environment
    Terraform   = "true"
  }
}

# ------------------------------------------------------------------------------  
# CodePipeline
# ------------------------------------------------------------------------------

resource "aws_codepipeline" "this" {
  name     = var.pipeline_name
  role_arn = var.codepipeline_role_arn

  artifact_store {
    location = var.artifact_bucket_name
    type     = var.artifact_store_type
  }

  #--- Source stage ---#
  stage {
    name = var.source_stage_name

    dynamic "action" {
      for_each = var.source_actions
      content {
        name             = action.value.name
        category         = "Source"
        owner            = action.value.owner
        provider         = action.value.provider
        version          = action.value.version
        output_artifacts = action.value.output_artifacts
        run_order        = try(action.value.run_order, 1)
        configuration    = action.value.configuration
      }
    }
  }

  #--- Build stage ---#
  stage {
    name = var.build_stage_name

    dynamic "action" {
      for_each = var.build_actions
      content {
        name             = action.value.name
        category         = try(action.value.category, "Build")
        owner            = try(action.value.owner, "AWS")
        provider         = try(action.value.provider, "CodeBuild")
        version          = try(action.value.version, "1")
        input_artifacts  = try(action.value.input_artifacts, [])
        output_artifacts = try(action.value.output_artifacts, [])
        run_order        = try(action.value.run_order, 1)

        configuration = merge(
          { ProjectName = action.value.project_name },
          try(action.value.configuration, {})
        )
      }
    }
  }

  #--- Deploy stage ---#
  dynamic "stage" {
    for_each = var.deploy_stage_enabled ? [1] : []
    content {
      name = var.deploy_stage_name

      # -------------------- ECS Deploy (backend - default) --------------------
      dynamic "action" {
        for_each = var.deploy_action_provider == var.deploy_action_provider && var.deploy_action_provider == "ECS" ? [1] : []
        content {
          name            = var.deploy_action_name
          category        = var.deploy_action_category
          owner           = var.deploy_action_owner
          provider        = var.deploy_action_provider
          version         = var.deploy_action_version
          input_artifacts = [var.build_output_artifact]

          configuration = {
            ClusterName = var.ecs_cluster_name
            ServiceName = var.ecs_service_name
            FileName    = var.image_definitions_file
          }
        }
      }

      # -------------------- S3 Deploy (frontend static) -----------------------
      dynamic "action" {
        for_each = var.deploy_action_provider == var.deploy_action_provider && var.deploy_action_provider == "S3" ? [1] : []
        content {
          name            = var.deploy_action_name
          category        = var.deploy_action_category
          owner           = var.deploy_action_owner
          provider        = var.deploy_action_provider
          version         = var.deploy_action_version
          input_artifacts = [var.build_output_artifact]

          configuration = merge(
            { BucketName = var.deploy_bucket_name },
            var.deploy_extract == null ? {} : { Extract = tostring(var.deploy_extract) },
            var.deploy_object_key == null ? {} : { ObjectKey = var.deploy_object_key }
          )
        }
      }

      # -------------------- CodeDeploy (Blue/Green) ------------------------
      dynamic "action" {
        for_each = var.deploy_action_provider == "CodeDeployToECS" ? [1] : []
        content {
          name            = var.deploy_action_name
          category        = var.deploy_action_category
          owner           = var.deploy_action_owner
          provider        = "CodeDeployToECS"
          version         = var.deploy_action_version
          input_artifacts = [var.build_output_artifact]

          configuration = {
            ApplicationName                 = var.codedeploy_application_name
            DeploymentGroupName             = var.codedeploy_deployment_group_name
            TaskDefinitionTemplateArtifact  = var.build_output_artifact
            AppSpecTemplateArtifact         = var.build_output_artifact
          }
        }
      }
    }
  }

  tags = {
    Name        = var.pipeline_name
    Environment = var.environment
    Terraform   = true
  }
}
