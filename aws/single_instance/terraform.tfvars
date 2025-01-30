# File 1: terraform.tfvars

ami                  = "ami-07d2649d67dbe8900" # region-locked
availability_zones   = ["us-west-1b", "us-west-1c"]
ec2_keypair          = "bluedragon"
employer             ="Fireworks Inc"
env                  = "prod"
instance_type        = "t2.micro"
my_laptop_cidr_block = "23.93.111.61/32" # https://whatismyipaddress.com/
region               = "us-west-1"
vpc_cidr_block       = "10.0.0.0/16"
tfstate_bucket       = "bluedragon-employer-prod"

