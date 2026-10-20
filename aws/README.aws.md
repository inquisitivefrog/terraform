# aws CLI commands used in this repo

The AWS CLI commands found across `aws/` (scripts, READMEs and old notes),
grouped by service, with the closest gcloud command beside each. The GCP side
is in `../gcp/README.gcloud.md`.

Account `084375569056` (default profile, IAM user `bluedragon`). Regions:
dev `us-west-2`, prod `us-west-1`; ecommerce-k8s used `us-east-1`.

Never point these at the grid-meter account (`184375956348`, profile
`grid-meter-freetier`): it runs a live demo. Check with
`aws sts get-caller-identity` first.

Tips:

- `--query '…'` filters output with JMESPath, e.g.
  `--query 'Reservations[*].Instances[*].[InstanceId,State.Name]'`.
- `--output table|text|json` sets the format; `text` suits scripts.
- `--region` and `--profile` pick the region and credentials per command.
- `aws <service> <command> help` shows the manual.

## Helper scripts (`aws/scripts/`)

| Script | What it does |
|---|---|
| `aws_wipe.sh` | Tears down the tfstate layer (environments, then bootstrap) after single_instance is destroyed. Only runs on account `084375569056`; only touches `bluedragon-` resources |
| `kube_use.sh dev\|prod` | Points kubectl at the single_instance EKS cluster and shows nodes and pods. Leaves the grid-meter context alone |
| `ssh_ec2.sh dev\|prod [public\|private]` | SSHes to an EC2 instance; the private one through the public one (ProxyJump) |
| `inspect_aws.sh`, `scan_aws.sh` | Read-only listings of resources across regions, plus budget spend |
| `make_docs.sh` | Generates module READMEs with terraform-docs |

## Accounts and configuration

| Command | What it does | gcloud |
|---|---|---|
| `aws configure` | Saves access keys, default region and output format to `~/.aws/` | `gcloud auth login`, `gcloud auth application-default login` |
| `aws sts get-caller-identity` | Shows which account and user you are | `gcloud config list` |
| `aws budgets describe-budgets --account-id 084375569056 --query 'Budgets[*].[BudgetName,CalculatedSpend.ActualSpend.Amount]' --output text` | Shows budget spend | `gcloud billing budgets list --billing-account=…` |

## S3

| Command | What it does | gcloud |
|---|---|---|
| `aws s3 ls` | Lists buckets | `gcloud storage ls` |
| `aws s3 ls s3://BUCKET --recursive` | Lists objects | `gcloud storage ls -r gs://BUCKET` |
| `aws s3 mb s3://BUCKET --region R` | Creates a bucket | `gcloud storage buckets create gs://BUCKET --location=R` |
| `aws s3 cp FILE s3://BUCKET/KEY` | Uploads or downloads | `gcloud storage cp` |
| `aws s3 rm s3://BUCKET --recursive` | Deletes current objects (not old versions) | `gcloud storage rm "gs://BUCKET/**"` |
| `aws s3 rb s3://BUCKET --force` | Deletes a bucket and its current objects | `gcloud storage rm -r gs://BUCKET` |
| `aws s3api list-buckets --query 'Buckets[?starts_with(Name, \`bluedragon-\`)].Name'` | Lists buckets, filtered | `gcloud storage ls --filter=…` |
| `aws s3api head-bucket --bucket BUCKET` | Checks a bucket exists and you can reach it | `gcloud storage buckets describe gs://BUCKET` |
| `aws s3api head-object --bucket BUCKET --key KEY` | Shows an object's metadata | `gcloud storage objects describe gs://BUCKET/KEY` |
| `aws s3api get-bucket-lifecycle-configuration --bucket BUCKET` | Shows lifecycle rules | `gcloud storage buckets describe gs://BUCKET --format='value(lifecycle_config)'` |
| `aws s3api restore-object --bucket BUCKET --key KEY --restore-request …` | Restores an object from Glacier | not needed: Coldline is read directly |
| `aws s3api delete-bucket --bucket BUCKET` | Deletes an empty bucket | `gcloud storage buckets delete gs://BUCKET` |

Emptying a versioned bucket (from `tfstate/README.md`; `aws_wipe.sh` does this):

```sh
aws s3api list-object-versions --bucket BUCKET --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' > objects.json
aws s3api delete-objects --bucket BUCKET --delete file://objects.json
aws s3api list-object-versions --bucket BUCKET --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' > markers.json
aws s3api delete-objects --bucket BUCKET --delete file://markers.json
aws s3 rb s3://BUCKET
```

GCP does it in one step: `gcloud storage rm -r --all-versions gs://BUCKET`.

## EC2 and VPC

| Command | What it does | gcloud |
|---|---|---|
| `aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType]' --output table` | Lists instances | `gcloud compute instances list` |
| `aws ec2 describe-key-pairs` | Lists SSH key pairs | none: OS Login uses your Google identity |
| `aws ec2 import-key-pair --key-name bluedragon --public-key-material fileb:///tmp/KEY.pub --region R` | Uploads a public key (build step 3) | none |
| `aws ec2 describe-vpcs` / `describe-subnets` / `describe-route-tables` | Lists networking | `gcloud compute networks list`, `… subnets list`, `… routes list` |
| `aws ec2 describe-internet-gateways` / `describe-nat-gateways` / `describe-addresses` | Lists gateways and Elastic IPs | `gcloud compute routers nats list --router=… --region=…`, `gcloud compute addresses list` |
| `aws ec2 describe-security-groups` / `describe-security-group-rules` | Lists security groups | `gcloud compute firewall-rules list` |
| `aws ec2 describe-network-interfaces` | Lists ENIs (often what blocks a VPC delete) | `gcloud compute instances describe … --format='value(networkInterfaces)'` |
| `aws ec2 describe-vpc-endpoints` / `describe-flow-logs` / `describe-volumes` / `describe-tags` | Lists endpoints, flow logs, disks, tags | `gcloud compute disks list`; flow logs are a subnet setting |
| `aws ec2 describe-transit-gateways` / `describe-vpn-gateways` / `describe-vpn-connections` / `describe-local-gateways` | Audit listings in `scan_aws.sh` | `gcloud compute vpn-gateways list` |
| `aws ec2 wait instance-terminated --instance-ids ID` | Waits until a state is reached | `gcloud compute operations wait` |

Manual VPC teardown, in dependency order (from old cleanup notes; Terraform
destroy normally does this): `delete-nat-gateway` → `release-address` →
`detach-internet-gateway` → `delete-internet-gateway` →
`delete-network-interface` → `disassociate-route-table` → `delete-route-table`
→ `delete-subnet` → `delete-security-group` → `delete-vpc-endpoints` →
`delete-vpc`.

## Reaching the instances

| Command | What it does | gcloud |
|---|---|---|
| `ssh -i ~/.aws/bluedragon_uswest2.pem -J ubuntu@PUBLIC_IP ubuntu@PRIVATE_IP` | SSH to the private instance through the public one (`ssh_ec2.sh`) | `gcloud compute ssh … --tunnel-through-iap` + ProxyCommand (see `README.gcloud.md`) |
| `aws ssm describe-instance-information` | Lists instances the SSM agent has registered | none |
| `aws ssm start-session --target i-…` | Shell on an instance without SSH (Session Manager; needs the plugin in `single_instance/sessionmanager-bundle/`) | `gcloud compute ssh --tunnel-through-iap` |

## EKS

| Command | What it does | gcloud |
|---|---|---|
| `aws eks update-kubeconfig --region us-west-2 --name eks-dev-SUFFIX --alias eks-dev` | Writes a kubeconfig entry (`terraform output kubeconfig_command`) | `gcloud container clusters get-credentials` |
| `aws eks get-token --cluster-name NAME` | Prints a token; kubectl calls it via the kubeconfig | `gke-gcloud-auth-plugin` |
| `aws eks list-clusters` / `describe-cluster --name NAME` | Lists or shows clusters | `gcloud container clusters list` / `describe` |
| `aws eks list-nodegroups` / `describe-nodegroup` | Lists or shows node groups | `gcloud container node-pools list --cluster=…` |
| `aws eks update-nodegroup-config --scaling-config desiredSize=N` | Resizes a node group | `gcloud container clusters resize … --node-pool=… --num-nodes=N` |
| `aws eks wait cluster-active --name NAME` | Waits for a cluster state | gcloud waits by default |
| `aws eks update-cluster-config --access-config authenticationMode=CONFIG_MAP` | Switches between aws-auth and access entries | none: GKE uses IAM + RBAC |
| `aws eks create-access-entry` / `associate-access-policy` / `list-access-entries` / `delete-access-entry` | Grants an IAM principal cluster access (ecommerce-k8s) | `gcloud projects add-iam-policy-binding … --role=roles/container.developer` or RBAC |
| `aws eks delete-nodegroup` / `delete-cluster` | Deletes node groups, then the cluster | `gcloud container clusters delete` |

## IAM

| Command | What it does | gcloud |
|---|---|---|
| `aws iam list-users` / `list-groups` / `list-roles` / `list-policies --scope Local` | Lists identities and policies | `gcloud iam service-accounts list`, `gcloud iam roles list --project …` |
| `aws iam get-role --role-name NAME` | Shows a role | `gcloud iam service-accounts describe EMAIL` |
| `aws iam list-attached-role-policies` / `list-role-policies` / `list-entities-for-policy` | Shows what's attached to what | `gcloud projects get-iam-policy …` |
| `aws iam get-policy` + `get-policy-version` | Shows a policy document | `gcloud iam roles describe` |
| `aws iam attach-user-policy --user-name bluedragon --policy-arn …/AdministratorAccess` | Attaches a policy | `gcloud projects add-iam-policy-binding` |
| `aws iam detach-role-policy` → `delete-role-policy` → `delete-role` / `delete-policy` | Deletes a role (detach policies first) | `gcloud iam service-accounts delete` |
| `aws iam list-instance-profiles` / `list-open-id-connect-providers` / `list-access-keys` | Audit listings | `gcloud iam service-accounts keys list` |

## KMS

| Command | What it does | gcloud |
|---|---|---|
| `aws kms list-keys` / `list-aliases` / `describe-key --key-id ID` | Lists or shows keys | `gcloud kms keys list --keyring=… --location=…` |
| `aws kms schedule-key-deletion --key-id ID --pending-window-in-days 7` | Deletes a key after a waiting period | `gcloud kms keys versions destroy` (key rings are never deleted) |

## SNS, ElastiCache, ECS, Load Balancers, Logs

| Command | What it does | gcloud |
|---|---|---|
| `aws sns list-topics` / `list-subscriptions` | Lists topics and subscriptions | `gcloud pubsub topics list` / `subscriptions list` |
| `aws sns publish --topic-arn ARN --message …` | Sends a test message | `gcloud pubsub topics publish T --message=…` |
| `aws elasticache describe-cache-clusters` / `describe-replication-groups` / `describe-cache-subnet-groups` / `describe-events` | Shows Redis clusters and events | `gcloud redis instances list --region=…` |
| `aws elasticache describe-users` / `describe-user-groups` | Shows Redis users (ecommerce-k8s auth) | `gcloud redis instances get-auth-string` |
| `aws ecs list-clusters` / `list-task-definitions` | Lists ECS clusters and tasks | `gcloud run services list` |
| `aws elbv2 describe-load-balancers` / `describe-target-groups` / `describe-target-health --target-group-arn ARN` | Shows ALBs and whether targets are healthy | `gcloud compute forwarding-rules list`, `gcloud compute backend-services get-health … --global` |
| `aws elbv2 delete-load-balancer` / `delete-target-group` | Deletes leftovers the ALB controller made | `gcloud compute forwarding-rules delete` |
| `aws logs describe-log-groups` / `describe-log-streams` | Lists CloudWatch log groups (VPC flow logs) | `gcloud logging read 'logName:"vpc_flows"' --limit 10` |

## DynamoDB (old state locking)

Older stacks locked state in a DynamoDB table. This repo now uses S3's
own lock files (`use_lockfile = true`), and the GCS backend locks natively.

| Command | What it does |
|---|---|
| `aws dynamodb create-table --table-name terraform-state-lock --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH …` | Creates a lock table |
| `aws dynamodb list-tables` / `describe-table` / `scan --table-name …` | Shows lock tables and held locks |
| `aws dynamodb delete-table --table-name …` | Deletes a lock table |
