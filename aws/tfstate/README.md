
BUILD
-----
tim@Tims-MBP tfstate % pwd
/Users/tim/Documents/workspace/sre/terraform/aws/tfstate

1. aws configure

tim@Tims-MBP prod % pwd
/Users/tim/Documents/workspace/sre/terraform/aws/tfstate/bootstrap/prod

1. terraform init
2. terraform validate
3. terraform plan -out=bootstrap-prod
4. terraform apply bootstrap-prod
5. aws s3 ls s3://bluedragon-tfstate-admin-prod --region us-west-1

tim@Tims-MBP dev % pwd
/Users/tim/Documents/workspace/sre/terraform/aws/tfstate/bootstrap/dev

1. terraform init
2. terraform validate
3. terraform plan -out=bootstrap-dev
4. terraform apply bootstrap-dev
5. aws s3 ls s3://bluedragon-tfstate-admin-dev --region us-west-2

tim@Tims-MBP % pwd
/Users/tim/Documents/workspace/sre/terraform/aws/tfstate/environment/prod

1. terraform init -backend-config=backend.hcl -reconfigure
2. terraform validate
3. terraform plan -out bucket-prod
4. terraform apply bucket-prod
5. aws s3 ls s3://bluedragon-tfstate-admin-prod/ --region us-west-1
6. terraform state list

tim@Tims-MBP % pwd
/Users/tim/Documents/workspace/sre/terraform/aws/tfstate/environment/dev

1. terraform init -backend-config=backend.hcl -reconfigure
2. terraform validate
3. terraform plan -out bucket-dev
4. terraform apply bucket-dev
5. aws s3 ls s3://bluedragon-tfstate-admin-dev/ --region us-west-2
6. terraform state list

DESTROY
-------
tim@Tims-MBP tfstate % pwd
/Users/tim/Documents/workspace/sre/terraform/aws/tfstate/environment/prod

1. terraform destroy

tim@Tims-MBP tfstate % pwd
/Users/tim/Documents/workspace/sre/terraform/aws/tfstate/environment/dev

1. terraform destroy

tim@Tims-MBP tfstate % pwd
/Users/tim/Documents/workspace/sre/terraform/aws/tfstate/bootstrap/dev

1. terraform destroy

tim@Tims-MBP tfstate % pwd
/Users/tim/Documents/workspace/sre/terraform/aws/tfstate/bootstrap/prod

1. terraform destroy

01. aws s3 ls
02. aws s3api list-object-versions --bucket bluedragon-tfstate-admin-5fgetyet --region us-west-1
03. aws s3api list-object-versions --bucket bluedragon-tfstate-admin-5fgetyet --region us-west-1 --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' > objects.json
04. cat objects.json 
05. aws s3api delete-objects --bucket bluedragon-tfstate-admin-5fgetyet --delete file://objects.json --region us-west-1
06. aws s3api list-object-versions --bucket bluedragon-tfstate-admin-5fgetyet --region us-west-1 --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' > markers.json
07. aws s3api delete-objects --bucket bluedragon-tfstate-admin-5fgetyet --delete file://markers.json --region us-west-1
08. aws s3api list-object-versions --bucket bluedragon-tfstate-admin-5fgetyet --region us-west-1
09. aws s3 rb s3://bluedragon-tfstate-admin-5fgetyet --force --region us-west-1
10. aws s3 ls

