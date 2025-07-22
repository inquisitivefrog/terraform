#!/bin/bash

# Delete all objects and versions in the bucket
aws s3api delete-objects \
  --bucket bluedragon-ecommerce-terraform-state \
  --delete "$(aws s3api list-object-versions \
    --bucket bluedragon-ecommerce-terraform-state \
    --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}')"

# Delete all delete markers
aws s3api delete-objects \
  --bucket bluedragon-ecommerce-terraform-state \
  --delete "$(aws s3api list-object-versions \
    --bucket bluedragon-ecommerce-terraform-state \
    --query='{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}')"

# Confirm the bucket is empty
aws s3 ls s3://bluedragon-ecommerce-terraform-state
