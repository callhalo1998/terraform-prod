terraform {
  source = "../../../../terraform/cloudfront/cloudfront_functions"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  function_name = "landing-page-viewer-request"
  runtime       = "cloudfront-js-2.0"
  comment       = "CloudFront function for landing page viewer request handling"
  publish       = true
  code_file     = "${get_repo_root()}/devops-prod/terragrunt/prod/cloudfront/cloudfront-function/index.js"
}
