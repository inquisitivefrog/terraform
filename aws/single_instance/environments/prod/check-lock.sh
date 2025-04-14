#!/bin/bash
terraform init -backend-config=backend.hcl -lockfile=readonly
if [ $? -ne 0 ]; then
  echo "Lock file mismatch detected. Run 'terraform init -upgrade' to resolve."
  exit 1
fi
