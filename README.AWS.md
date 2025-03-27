# https://github.com/inquisitivefrog/terraform

This repository demonstrates use of Terraform to create environments in
Amazon Web Services.

All work was completed with the assistance of xAI Grok Generative Text tool.

These AWS Objects were created.

# create the S3 bucket for terraform.tfstate
cd aws/tfstate
terraform init
terraform fmt
terraform validate
terraform plan -out bucket
terraform apply
terraform show

# create the prod environment
cd ../single_instance
terraform init -reconfigure
terraform fmt -recursive
terraform validate
terraform plan -out plan
terraform apply plan
terraform show
