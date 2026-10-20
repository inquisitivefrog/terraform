bucket             = "bluedragon-tfstate-admin-dev" # created by tfstate/bootstrap/dev
prefix             = "single_instance"
kms_encryption_key = "projects/bluedragon-sre-vuft1e/locations/us-west1/keyRings/tfstate-dev-imtcz3jz/cryptoKeys/state-bucket-key" # tfstate/environments/dev: terraform output state_bucket_key_id
