#!/bin/bash

# Full cleanup script for tfstate and single_instance projects
# Run from /Users/tim/Documents/workspace/sre/terraform/aws/

# Check if script is run from the correct directory
EXPECTED_DIR="/Users/tim/Documents/workspace/sre/terraform/aws"
CURRENT_DIR=$(pwd)
if [ "$CURRENT_DIR" != "$EXPECTED_DIR" ]; then
  echo "Error: This script must be run from $EXPECTED_DIR"
  echo "Current directory is $CURRENT_DIR"
  echo "Please cd to $EXPECTED_DIR and try again."
  exit 1
fi

# Function to document Terraform resources
document_tf() {
  local dir=$1
  echo "Documenting resources in $dir..."
  cd "$dir" || { echo "Failed to cd into $dir"; return 1; }
  if [ -f README.md ]; then
      rm README.md
  fi
  terraform-docs markdown . > README.md
  cd - >/dev/null || exit 1
}

# Main cleanup
echo "Starting code documentation..."

# Document tfstate environments
document_tf "tfstate/bootstrap/dev"
document_tf "tfstate/bootstrap/prod"
document_tf "tfstate/environments/dev"
document_tf "tfstate/environments/prod"

# Document single_instance environments
document_tf "single_instance/environments/dev"
document_tf "single_instance/environments/prod"

# Document single_instance modules 
document_tf "single_instance/modules/cache"
document_tf "single_instance/modules/compute"
document_tf "single_instance/modules/identity"
document_tf "single_instance/modules/kms"
document_tf "single_instance/modules/messages"
document_tf "single_instance/modules/networking"
document_tf "single_instance/modules/storage"
document_tf "single_instance/modules/vpc"
echo "Full documentation complete!"

