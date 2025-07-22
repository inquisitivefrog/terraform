
tim@Tims-MBP stage1-infra % pwd
/Users/tim/Documents/workspace/sre/terraform/aws/ecommerce-k8s/stage1-infra
tim@Tims-MBP stage1-infra % cd ../stage2-k8s 

tim@Tims-MBP stage2-k8s % terraform init -backend-config=backend.hcl -reconfigure
Initializing the backend...

Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.
Initializing provider plugins...
- Reusing previous version of hashicorp/aws from the dependency lock file
- Reusing previous version of hashicorp/helm from the dependency lock file
- Reusing previous version of hashicorp/kubernetes from the dependency lock file
- Reusing previous version of hashicorp/time from the dependency lock file
- Installing hashicorp/aws v5.100.0...
- Installed hashicorp/aws v5.100.0 (signed by HashiCorp)
- Installing hashicorp/helm v2.17.0...
- Installed hashicorp/helm v2.17.0 (signed by HashiCorp)
- Installing hashicorp/kubernetes v2.37.1...
- Installed hashicorp/kubernetes v2.37.1 (signed by HashiCorp)
- Installing hashicorp/time v0.13.1...
- Installed hashicorp/time v0.13.1 (signed by HashiCorp)

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.

tim@Tims-MBP stage2-k8s % aws s3 ls --region us-east-1
2025-06-20 10:46:45 blued-ecommerce-app-us-east-1-prod
2025-06-20 10:38:05 bluedragon-ecommerce-terraform-state


