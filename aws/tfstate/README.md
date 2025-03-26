
tim@Tims-MBP tfstate % pwd
/Users/tim/Documents/workspace/sre/terraform/aws/tfstate
tim@Tims-MBP tfstate % terraform init
Initializing the backend...
Initializing provider plugins...
- Reusing previous version of hashicorp/aws from the dependency lock file
- Using previously-installed hashicorp/aws v4.67.0

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
tim@Tims-MBP tfstate % terraform import aws_s3_bucket.state_bucket bluedragon-employer-prod
aws_s3_bucket.state_bucket: Importing from ID "bluedragon-employer-prod"...
aws_s3_bucket.state_bucket: Import prepared!
  Prepared aws_s3_bucket for import
aws_s3_bucket.state_bucket: Refreshing state... [id=bluedragon-employer-prod]

Import successful!

The resources that were imported are shown above. These resources are now in
your Terraform state and will henceforth be managed by Terraform.

tim@Tims-MBP tfstate % terraform import aws_dynamodb_table.terraform_locks terraform-locks
aws_dynamodb_table.terraform_locks: Importing from ID "terraform-locks"...
aws_dynamodb_table.terraform_locks: Import prepared!
  Prepared aws_dynamodb_table for import
aws_dynamodb_table.terraform_locks: Refreshing state... [id=terraform-locks]

Import successful!

The resources that were imported are shown above. These resources are now in
your Terraform state and will henceforth be managed by Terraform.

tim@Tims-MBP tfstate % terraform plan -out=bucket
aws_dynamodb_table.terraform_locks: Refreshing state... [id=terraform-locks]
aws_s3_bucket.state_bucket: Refreshing state... [id=bluedragon-employer-prod]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create
  ~ update in-place

Terraform will perform the following actions:

  # aws_dynamodb_table.terraform_locks will be updated in-place
  ~ resource "aws_dynamodb_table" "terraform_locks" {
        id                          = "terraform-locks"
        name                        = "terraform-locks"
        tags                        = {}
        # (12 unchanged attributes hidden)

      ~ point_in_time_recovery {
          ~ enabled = false -> true
        }

      + server_side_encryption {
          + enabled = true
        }

        # (2 unchanged blocks hidden)
    }

  # aws_s3_bucket_acl.state_bucket_acl will be created
  + resource "aws_s3_bucket_acl" "state_bucket_acl" {
      + acl    = "private"
      + bucket = "bluedragon-employer-prod"
      + id     = (known after apply)

      + access_control_policy (known after apply)
    }

  # aws_s3_bucket_lifecycle_configuration.state_bucket_lifecycle will be created
  + resource "aws_s3_bucket_lifecycle_configuration" "state_bucket_lifecycle" {
      + bucket = "bluedragon-employer-prod"
      + id     = (known after apply)

      + rule {
          + id     = "move_to_glacier"
          + status = "Enabled"

          + noncurrent_version_expiration {
              + noncurrent_days = 365
            }

          + noncurrent_version_transition {
              + noncurrent_days           = 30
              + storage_class             = "GLACIER"
                # (1 unchanged attribute hidden)
            }
        }
    }

  # aws_s3_bucket_ownership_controls.ownership will be created
  + resource "aws_s3_bucket_ownership_controls" "ownership" {
      + bucket = "bluedragon-employer-prod"
      + id     = (known after apply)

      + rule {
          + object_ownership = "ObjectWriter"
        }
    }

  # aws_s3_bucket_public_access_block.block_public_access will be created
  + resource "aws_s3_bucket_public_access_block" "block_public_access" {
      + block_public_acls       = true
      + block_public_policy     = true
      + bucket                  = "bluedragon-employer-prod"
      + id                      = (known after apply)
      + ignore_public_acls      = true
      + restrict_public_buckets = true
    }

  # aws_s3_bucket_server_side_encryption_configuration.state_bucket_encryption will be created
  + resource "aws_s3_bucket_server_side_encryption_configuration" "state_bucket_encryption" {
      + bucket = "bluedragon-employer-prod"
      + id     = (known after apply)

      + rule {
          + apply_server_side_encryption_by_default {
              + sse_algorithm     = "AES256"
                # (1 unchanged attribute hidden)
            }
        }
    }

  # aws_s3_bucket_versioning.state_bucket_versioning will be created
  + resource "aws_s3_bucket_versioning" "state_bucket_versioning" {
      + bucket = "bluedragon-employer-prod"
      + id     = (known after apply)

      + versioning_configuration {
          + mfa_delete = (known after apply)
          + status     = "Enabled"
        }
    }

Plan: 6 to add, 1 to change, 0 to destroy.

──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Saved the plan to: bucket

To perform exactly these actions, run the following command to apply:
    terraform apply "bucket"
tim@Tims-MBP tfstate % terraform apply bucket
aws_s3_bucket_ownership_controls.ownership: Creating...
aws_s3_bucket_versioning.state_bucket_versioning: Creating...
aws_s3_bucket_server_side_encryption_configuration.state_bucket_encryption: Creating...
aws_s3_bucket_public_access_block.block_public_access: Creating...
aws_s3_bucket_lifecycle_configuration.state_bucket_lifecycle: Creating...
aws_dynamodb_table.terraform_locks: Modifying... [id=terraform-locks]
aws_s3_bucket_server_side_encryption_configuration.state_bucket_encryption: Creation complete after 0s [id=bluedragon-employer-prod]
aws_s3_bucket_ownership_controls.ownership: Creation complete after 0s [id=bluedragon-employer-prod]
aws_s3_bucket_public_access_block.block_public_access: Creation complete after 0s [id=bluedragon-employer-prod]
aws_s3_bucket_acl.state_bucket_acl: Creating...
aws_s3_bucket_acl.state_bucket_acl: Creation complete after 1s [id=bluedragon-employer-prod,private]
aws_s3_bucket_versioning.state_bucket_versioning: Creation complete after 1s [id=bluedragon-employer-prod]
aws_s3_bucket_lifecycle_configuration.state_bucket_lifecycle: Still creating... [10s elapsed]
aws_dynamodb_table.terraform_locks: Still modifying... [id=terraform-locks, 10s elapsed]
aws_s3_bucket_lifecycle_configuration.state_bucket_lifecycle: Still creating... [20s elapsed]
aws_dynamodb_table.terraform_locks: Still modifying... [id=terraform-locks, 20s elapsed]
aws_s3_bucket_lifecycle_configuration.state_bucket_lifecycle: Still creating... [30s elapsed]
aws_dynamodb_table.terraform_locks: Still modifying... [id=terraform-locks, 30s elapsed]
aws_dynamodb_table.terraform_locks: Modifications complete after 30s [id=terraform-locks]
aws_s3_bucket_lifecycle_configuration.state_bucket_lifecycle: Creation complete after 31s [id=bluedragon-employer-prod]

Apply complete! Resources: 6 added, 1 changed, 0 destroyed.
tim@Tims-MBP tfstate % aws s3api get-bucket-encryption --bucket bluedragon-employer-prod
{
    "ServerSideEncryptionConfiguration": {
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                },
                "BucketKeyEnabled": false
            }
        ]
    }
}
tim@Tims-MBP tfstate % aws s3api get-bucket-versioning --bucket bluedragon-employer-prod
{
    "Status": "Enabled"
}
tim@Tims-MBP tfstate % aws s3api get-public-access-block --bucket bluedragon-employer-prod
{
    "PublicAccessBlockConfiguration": {
        "BlockPublicAcls": true,
        "IgnorePublicAcls": true,
        "BlockPublicPolicy": true,
        "RestrictPublicBuckets": true
    }
}
tim@Tims-MBP tfstate % aws s3api get-bucket-lifecycle-configuration --bucket bluedragon-employer-prod
{
    "TransitionDefaultMinimumObjectSize": "all_storage_classes_128K",
    "Rules": [
        {
            "ID": "move_to_glacier",
            "Filter": {
                "Prefix": ""
            },
            "Status": "Enabled",
            "NoncurrentVersionTransitions": [
                {
                    "NoncurrentDays": 30,
                    "StorageClass": "GLACIER"
                }
            ],
            "NoncurrentVersionExpiration": {
                "NoncurrentDays": 365
            }
        }
    ]
}
tim@Tims-MBP tfstate % aws dynamodb describe-table --table-name terraform-locks
{
    "Table": {
        "AttributeDefinitions": [
            {
                "AttributeName": "LockID",
                "AttributeType": "S"
            }
        ],
        "TableName": "terraform-locks",
        "KeySchema": [
            {
                "AttributeName": "LockID",
                "KeyType": "HASH"
            }
        ],
        "TableStatus": "ACTIVE",
        "CreationDateTime": "2025-01-23T10:39:12.361000-08:00",
        "ProvisionedThroughput": {
            "NumberOfDecreasesToday": 0,
            "ReadCapacityUnits": 0,
            "WriteCapacityUnits": 0
        },
        "TableSizeBytes": 198,
        "ItemCount": 2,
        "TableArn": "arn:aws:dynamodb:us-west-1:084375569056:table/terraform-locks",
        "TableId": "12720b88-5bab-4002-95e3-5519ee8d6fc7",
        "BillingModeSummary": {
            "BillingMode": "PAY_PER_REQUEST",
            "LastUpdateToPayPerRequestDateTime": "2025-01-23T10:39:12.361000-08:00"
        },
        "SSEDescription": {
            "Status": "ENABLED",
            "SSEType": "KMS",
            "KMSMasterKeyArn": "arn:aws:kms:us-west-1:084375569056:key/294a1467-3a3f-47dd-a43f-631ec95bf9fd"
        },
        "DeletionProtectionEnabled": false
    }
}

tim@Tims-MBP tfstate % vi create_s3_bucket.tf
tim@Tims-MBP tfstate % terraform plan -out=bucket_logging
aws_dynamodb_table.terraform_locks: Refreshing state... [id=terraform-locks]
aws_s3_bucket.state_bucket: Refreshing state... [id=bluedragon-employer-prod]
aws_s3_bucket_public_access_block.block_public_access: Refreshing state... [id=bluedragon-employer-prod]
aws_s3_bucket_server_side_encryption_configuration.state_bucket_encryption: Refreshing state... [id=bluedragon-employer-prod]
aws_s3_bucket_ownership_controls.ownership: Refreshing state... [id=bluedragon-employer-prod]
aws_s3_bucket_lifecycle_configuration.state_bucket_lifecycle: Refreshing state... [id=bluedragon-employer-prod]
aws_s3_bucket_versioning.state_bucket_versioning: Refreshing state... [id=bluedragon-employer-prod]
aws_s3_bucket_acl.state_bucket_acl: Refreshing state... [id=bluedragon-employer-prod,private]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_s3_bucket.state_log_bucket will be created
  + resource "aws_s3_bucket" "state_log_bucket" {
      + acceleration_status         = (known after apply)
      + acl                         = (known after apply)
      + arn                         = (known after apply)
      + bucket                      = "bluedragon-employer-prod-logs"
      + bucket_domain_name          = (known after apply)
      + bucket_prefix               = (known after apply)
      + bucket_regional_domain_name = (known after apply)
      + force_destroy               = false
      + hosted_zone_id              = (known after apply)
      + id                          = (known after apply)
      + object_lock_enabled         = (known after apply)
      + policy                      = (known after apply)
      + region                      = (known after apply)
      + request_payer               = (known after apply)
      + tags                        = {
          + "Environment" = "prod"
          + "Name"        = "Fireworks Inc-logs"
        }
      + tags_all                    = {
          + "Environment" = "prod"
          + "Name"        = "Fireworks Inc-logs"
        }
      + website_domain              = (known after apply)
      + website_endpoint            = (known after apply)

      + cors_rule (known after apply)

      + grant (known after apply)

      + lifecycle_rule (known after apply)

      + logging (known after apply)

      + object_lock_configuration (known after apply)

      + replication_configuration (known after apply)

      + server_side_encryption_configuration (known after apply)

      + versioning (known after apply)

      + website (known after apply)
    }

  # aws_s3_bucket_logging.state_bucket_logging will be created
  + resource "aws_s3_bucket_logging" "state_bucket_logging" {
      + bucket        = "bluedragon-employer-prod"
      + id            = (known after apply)
      + target_bucket = (known after apply)
      + target_prefix = "state-logs/"
    }

  # aws_s3_bucket_public_access_block.state_log_bucket will be created
  + resource "aws_s3_bucket_public_access_block" "state_log_bucket" {
      + block_public_acls       = true
      + block_public_policy     = true
      + bucket                  = (known after apply)
      + id                      = (known after apply)
      + ignore_public_acls      = true
      + restrict_public_buckets = true
    }

  # aws_s3_bucket_server_side_encryption_configuration.state_log_bucket will be created
  + resource "aws_s3_bucket_server_side_encryption_configuration" "state_log_bucket" {
      + bucket = (known after apply)
      + id     = (known after apply)

      + rule {
          + apply_server_side_encryption_by_default {
              + sse_algorithm     = "AES256"
                # (1 unchanged attribute hidden)
            }
        }
    }

Plan: 4 to add, 0 to change, 0 to destroy.

──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Saved the plan to: bucket_logging

To perform exactly these actions, run the following command to apply:
    terraform apply "bucket_logging"
tim@Tims-MBP tfstate % terraform apply "bucket_logging"
aws_s3_bucket.state_log_bucket: Creating...
aws_s3_bucket.state_log_bucket: Creation complete after 1s [id=bluedragon-employer-prod-logs]
aws_s3_bucket_public_access_block.state_log_bucket: Creating...
aws_s3_bucket_server_side_encryption_configuration.state_log_bucket: Creating...
aws_s3_bucket_logging.state_bucket_logging: Creating...
aws_s3_bucket_public_access_block.state_log_bucket: Creation complete after 0s [id=bluedragon-employer-prod-logs]
aws_s3_bucket_logging.state_bucket_logging: Creation complete after 1s [id=bluedragon-employer-prod]
aws_s3_bucket_server_side_encryption_configuration.state_log_bucket: Creation complete after 1s [id=bluedragon-employer-prod-logs]

Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

tim@Tims-MBP tfstate % aws s3api get-bucket-logging --bucket bluedragon-employer-prod
{
    "LoggingEnabled": {
        "TargetBucket": "bluedragon-employer-prod-logs",
        "TargetPrefix": "state-logs/"
    }
}

tim@Tims-MBP tfstate % aws s3api get-public-access-block --bucket bluedragon-employer-prod-logs
{
    "PublicAccessBlockConfiguration": {
        "BlockPublicAcls": true,
        "IgnorePublicAcls": true,
        "BlockPublicPolicy": true,
        "RestrictPublicBuckets": true
    }
}
