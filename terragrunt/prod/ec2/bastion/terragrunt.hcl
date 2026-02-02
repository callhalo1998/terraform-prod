terraform {
  source = "../../../../terraform/ec2"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "private_subnet" {
  config_path = "../../vpc/private-subnet"
}

dependency "sg" {
  config_path = "../sg"
}

dependency "eip" {
  config_path = "../../vpc/prod-vpc"
}

inputs = {
  environment                  = "prod"
  name                         = "prod-bastion"
  ami_id                       = "ami-0106926f63b303d74"
  instance_type                = "t3.micro"
  allocation_id                = dependency.eip.outputs.eip_ids["prod-bastion"]
  subnet_id                    = dependency.private_subnet.outputs.private_subnet_ids["prod-private-subnet-1"]
  security_group_ids           = [dependency.sg.outputs.security_group_ids["prod-bastion-sg"]]
  key_name                     = "prod-bastion"
  iam_instance_profile         = "prod-bastion-role"
  ebs_optimized                = true
  root_volume_type             = "gp3"
  root_volume_size_gb          = 8
}