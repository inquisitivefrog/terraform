#!/bin/bash
NEW_IP=$(curl -s ifconfig.me)
sed -i "s/laptop_cidr = \".*\"/laptop_cidr = \"$NEW_IP\/32\"/" terraform.tfvars
terraform plan -out=tfplan
terraform apply tfplan
