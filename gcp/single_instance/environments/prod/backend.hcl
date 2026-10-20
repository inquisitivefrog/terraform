bucket             = "bluedragon-tfstate-admin-prod" # created by tfstate/bootstrap/prod
prefix             = "single_instance"
kms_encryption_key = "projects/bluedragon-sre-vuft1e/locations/us-west2/keyRings/tfstate-prod-6wtegjuq/cryptoKeys/state-bucket-key" # tfstate/environments/prod: terraform output state_bucket_key_id
