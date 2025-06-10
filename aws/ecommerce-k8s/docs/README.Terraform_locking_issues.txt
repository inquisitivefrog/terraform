
Plan: 1 to add, 3 to change, 1 to destroy.

───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Saved the plan to: tfplan

To perform exactly these actions, run the following command to apply:
    terraform apply "tfplan"
Releasing state lock. This may take a few moments...
tim@Tims-MBP ecommerce-k8s % terraform apply tfplan
module.networking.aws_security_group_rule.eks_control_plane_ingress: Destroying... [id=sgrule-618758665]
module.eks.module.eks.aws_eks_cluster.this[0]: Modifying... [id=ecommerce-cluster]
module.networking.aws_security_group_rule.eks_control_plane_ingress: Destruction complete after 1s
module.networking.aws_security_group_rule.eks_control_plane_ingress: Creating...
module.networking.aws_security_group_rule.eks_control_plane_ingress: Creation complete after 1s [id=sgrule-3234424322]
module.eks.module.eks.aws_eks_cluster.this[0]: Still modifying... [id=ecommerce-cluster, 00m10s elapsed]
module.eks.module.eks.aws_eks_cluster.this[0]: Still modifying... [id=ecommerce-cluster, 01m44s elapsed]
╷
│ Error: failed to upload state: operation error S3: PutObject, https response error StatusCode: 0, RequestID: , HostID: , request send failed, Put "https://bluedragon-ecommerce-terraform-state.s3.us-east-1.amazonaws.com/ecommerce-k8s/terraform.tfstate?x-id=PutObject": dial tcp: lookup bluedragon-ecommerce-terraform-state.s3.us-east-1.amazonaws.com: no such host
│ 
│ 
╵
╷
│ Error: Failed to save state
│ 
│ Error saving state: failed to upload state: operation error S3: PutObject, https response error StatusCode: 0, RequestID: , HostID: , request send
│ failed, Put "https://bluedragon-ecommerce-terraform-state.s3.us-east-1.amazonaws.com/ecommerce-k8s/terraform.tfstate?x-id=PutObject": dial tcp: lookup
│ bluedragon-ecommerce-terraform-state.s3.us-east-1.amazonaws.com: no such host
╵
╷
│ Error: Failed to persist state to backend
│ 
│ The error shown above has prevented Terraform from writing the updated state to the configured backend. To allow for recovery, the state has been written
│ to the file "errored.tfstate" in the current working directory.
│ 
│ Running "terraform apply" again at this point will create a forked state, making it harder to recover.
│ 
│ To retry writing this state, use the following command:
│     terraform state push errored.tfstate
│ 
╵
╷
│ Error: waiting for EKS Cluster (ecommerce-cluster) VPC configuration update (82f9ba56-6032-3ca7-b9ec-19d9375d787b): operation error EKS: DescribeUpdate, https response error StatusCode: 0, RequestID: , request send failed, Get "https://eks.us-east-1.amazonaws.com/clusters/ecommerce-cluster/updates/82f9ba56-6032-3ca7-b9ec-19d9375d787b": dial tcp: lookup eks.us-east-1.amazonaws.com: no such host
│ 
│   with module.eks.module.eks.aws_eks_cluster.this[0],
│   on .terraform/modules/eks.eks/main.tf line 35, in resource "aws_eks_cluster" "this":
│   35: resource "aws_eks_cluster" "this" {
│ 
╵
╷
│ Error: Error releasing the state lock
│ 
│ Error message: unable to retrieve file from S3 bucket 'bluedragon-ecommerce-terraform-state' with key 'ecommerce-k8s/terraform.tfstate.tflock': operation
│ error S3: GetObject, https response error StatusCode: 0, RequestID: , HostID: , request send failed, Get
│ "https://bluedragon-ecommerce-terraform-state.s3.us-east-1.amazonaws.com/ecommerce-k8s/terraform.tfstate.tflock?x-id=GetObject": dial tcp: lookup
│ bluedragon-ecommerce-terraform-state.s3.us-east-1.amazonaws.com: no such host
│ 
│ Terraform acquires a lock when accessing your state to prevent others
│ running Terraform to potentially modify the state at the same time. An
│ error occurred while releasing this lock. This could mean that the lock
│ did or did not release properly. If the lock didn't release properly,
│ Terraform may not be able to run future commands since it'll appear as if
│ the lock is held.
│ 
│ In this scenario, please call the "force-unlock" command to unlock the
│ state manually. This is a very dangerous operation since if it is done
│ erroneously it could result in two people modifying state at the same time.
│ Only call this command if you're certain that the unlock above failed and
│ that no one else is holding a lock.
╵


tim@Tims-MBP ecommerce-k8s % terraform destroy --auto-approve
╷
│ Error: Error acquiring the state lock
│ 
│ Error message: operation error S3: PutObject, https response error StatusCode: 412, RequestID: CMQBKWR7FGJ7FVT9, HostID:
│ OfGpwDg+U/ocvNC69941dmGyHv+ck8joLqgu+CVFIcpm9kw0aW268m1jRdMOAUNFLVk0syKGAKs=, api error PreconditionFailed: At least one of the pre-conditions you
│ specified did not hold
│ Lock Info:
│   ID:        d2b10487-b325-0a64-0b2d-3794bc815b39
│   Path:      bluedragon-ecommerce-terraform-state/ecommerce-k8s/terraform.tfstate
│   Operation: OperationTypeApply
│   Who:       tim@Tims-MBP
│   Version:   1.12.1
│   Created:   2025-06-10 20:39:24.081703 +0000 UTC
│   Info:      
│ 
│ 
│ Terraform acquires a state lock to protect the state from being written
│ by multiple users at the same time. Please resolve the issue above and try
│ again. For most commands, you can disable locking with the "-lock=false"
│ flag, but this is not recommended.
╵
tim@Tims-MBP ecommerce-k8s % ls
README.ecommerce.txt	errored.tfstate		logs			old			tfplan
backend.hcl		iam-policy.json		main.tf			outputs.tf		variables.tf
ecommerce-app		kubernetes		modules			terraform.tfvars
tim@Tims-MBP ecommerce-k8s % cp errored.tfstate errored.tfstate.backup
tim@Tims-MBP ecommerce-k8s % terraform state push errored.tfstate
╷
│ Error: Error acquiring the state lock
│ 
│ Error message: operation error S3: PutObject, https response error StatusCode: 412, RequestID: P7S5KJHJ5K3XRTJV, HostID:
│ VTzRXa4jRZJh1UxUq88m1ISivZIlRhZ+ifWllqwxWjbdVtE2EIcNkHTCB+GFLayWYvyvkZtmKRQ=, api error PreconditionFailed: At least one of the pre-conditions you
│ specified did not hold
│ Lock Info:
│   ID:        d2b10487-b325-0a64-0b2d-3794bc815b39
│   Path:      bluedragon-ecommerce-terraform-state/ecommerce-k8s/terraform.tfstate
│   Operation: OperationTypeApply
│   Who:       tim@Tims-MBP
│   Version:   1.12.1
│   Created:   2025-06-10 20:39:24.081703 +0000 UTC
│   Info:      
│ 
│ 
│ Terraform acquires a state lock to protect the state from being written
│ by multiple users at the same time. Please resolve the issue above and try
│ again. For most commands, you can disable locking with the "-lock=false"
│ flag, but this is not recommended.
╵

tim@Tims-MBP ecommerce-k8s % 
tim@Tims-MBP ecommerce-k8s % terraform force-unlock d2b10487-b325-0a64-0b2d-3794bc815b39
Do you really want to force-unlock?
  Terraform will remove the lock on the remote state.
  This will allow local Terraform commands to modify this state, even though it
  may still be in use. Only 'yes' will be accepted to confirm.

  Enter a value: yes

Terraform state has been successfully unlocked!

The state has been unlocked, and Terraform commands should now be able to
obtain a new lock on the remote state.

