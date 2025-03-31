# File 1: terraform.tfvars

availability_zones   = ["us-west-1b", "us-west-1c"]
ec2_keypair          = "bluedragon"
env                  = "prod"
instance_type        = "t3.micro"
my_laptop_cidr_block = "23.93.84.244/32" # https://ipv4.icanhazip.com/
region               = "us-west-1"
vpc_cidr_block       = "10.0.0.0/16"
