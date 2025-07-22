
tim@Tims-MBP ecommerce-k8s % pwd
/Users/tim/Documents/workspace/sre/terraform/aws/ecommerce-k8s
tim@Tims-MBP ecommerce-k8s % find . -name "*.tf" -o -name "*.hcl" -o -name "*.tfvars" -o -name "*.json" -o -name "*.yaml"
./stage2-k8s/backend.hcl
./stage2-k8s/outputs.tf
./stage2-k8s/main.tf
./stage2-k8s/terraform.tfvars
./stage2-k8s/variables.tf
./stage2-k8s/.terraform.lock.hcl
./stage1-infra/backend.hcl
./stage1-infra/outputs.tf
./stage1-infra/main.tf
./modules/s3/outputs.tf
./modules/s3/main.tf
./modules/s3/variables.tf
./modules/networking/outputs.tf
./modules/networking/main.tf
./modules/networking/variables.tf
./modules/iam/outputs.tf
./modules/iam/main.tf
./modules/iam/variables.tf
./modules/eks/outputs.tf
./modules/eks/main.tf
./modules/eks/variables.tf
./modules/vpc/outputs.tf
./modules/vpc/main.tf
./modules/vpc/variables.tf
./.terraform.lock.hcl
tim@Tims-MBP ecommerce-k8s % cd stage1-infra 

tim@Tims-MBP stage1-infra % aws s3 mb s3://bluedragon-ecommerce-terraform-state --region us-east-1
make_bucket: bluedragon-ecommerce-terraform-state
tim@Tims-MBP stage1-infra % aws s3 ls --region us-east-1                                          
2025-06-20 10:38:05 bluedragon-ecommerce-terraform-state

tim@Tims-MBP stage1-infra % terraform init -backend-config=backend.hcl                 
Initializing the backend...
Initializing modules...
Initializing provider plugins...
- Reusing previous version of hashicorp/aws from the dependency lock file
- Reusing previous version of hashicorp/cloudinit from the dependency lock file
- Reusing previous version of hashicorp/time from the dependency lock file
- Reusing previous version of hashicorp/null from the dependency lock file
- Reusing previous version of hashicorp/tls from the dependency lock file
- Installing hashicorp/null v3.2.4...
- Installed hashicorp/null v3.2.4 (signed by HashiCorp)
- Installing hashicorp/tls v4.1.0...
- Installed hashicorp/tls v4.1.0 (signed by HashiCorp)
- Installing hashicorp/aws v5.100.0...
- Installed hashicorp/aws v5.100.0 (signed by HashiCorp)
- Installing hashicorp/cloudinit v2.3.7...
- Installed hashicorp/cloudinit v2.3.7 (signed by HashiCorp)
- Installing hashicorp/time v0.13.1...
- Installed hashicorp/time v0.13.1 (signed by HashiCorp)

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.

tim@Tims-MBP stage1-infra % aws dynamodb create-table --table-name terraform-state-lock --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 --region us-east-1 --profile default
{
    "TableDescription": {
        "AttributeDefinitions": [
            {
                "AttributeName": "LockID",
                "AttributeType": "S"
            }
        ],
        "TableName": "terraform-state-lock",
        "KeySchema": [
            {
                "AttributeName": "LockID",
                "KeyType": "HASH"
            }
        ],
        "TableStatus": "CREATING",
        "CreationDateTime": "2025-06-20T10:41:09.975000-07:00",
        "ProvisionedThroughput": {
            "NumberOfDecreasesToday": 0,
            "ReadCapacityUnits": 1,
            "WriteCapacityUnits": 1
        },
        "TableSizeBytes": 0,
        "ItemCount": 0,
        "TableArn": "arn:aws:dynamodb:us-east-1:084375569056:table/terraform-state-lock",
        "TableId": "b9ec0264-c8ff-40b8-9f55-2236da5b9072",
        "DeletionProtectionEnabled": false
    }
}

tim@Tims-MBP stage1-infra % aws dynamodb describe-table --table-name terraform-state-lock --region us-east-1 --profile default 
{
    "Table": {
        "AttributeDefinitions": [
            {
                "AttributeName": "LockID",
                "AttributeType": "S"
            }
        ],
        "TableName": "terraform-state-lock",
        "KeySchema": [
            {
                "AttributeName": "LockID",
                "KeyType": "HASH"
            }
        ],
        "TableStatus": "ACTIVE",
        "CreationDateTime": "2025-06-20T10:41:09.975000-07:00",
        "ProvisionedThroughput": {
            "NumberOfDecreasesToday": 0,
            "ReadCapacityUnits": 1,
            "WriteCapacityUnits": 1
        },
        "TableSizeBytes": 0,
        "ItemCount": 0,
        "TableArn": "arn:aws:dynamodb:us-east-1:084375569056:table/terraform-state-lock",
        "TableId": "b9ec0264-c8ff-40b8-9f55-2236da5b9072",
        "DeletionProtectionEnabled": false
    }
}
tim@Tims-MBP stage1-infra % aws dynamodb scan --table-name terraform-state-lock --region us-east-1 --profile terraform-admin


An error occurred (AccessDenied) when calling the AssumeRole operation: User: arn:aws:iam::084375569056:user/bluedragon is not authorized to perform: sts:AssumeRole on resource: arn:aws:iam::084375569056:role/terraform-admin

tim@Tims-MBP stage1-infra % aws dynamodb scan --table-name terraform-state-lock --region us-east-1 --profile default        
{
    "Items": [],
    "Count": 0,
    "ScannedCount": 0,
    "ConsumedCapacity": null
}

