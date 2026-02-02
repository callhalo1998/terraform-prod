terraform {
  source = "../../../../terraform/ecs/cluster"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  # --- Cluster ---
  environment  = "prod"
  cluster_name = "prod--cluster"
}