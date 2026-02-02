remote_state {
  backend = "s3"
  config = {
    bucket  = "prod--terraform-state"
    key     = "${path_relative_to_include()}/terraform.tfstate"
    region  = "eu-west-3"
    encrypt = true
  }
}