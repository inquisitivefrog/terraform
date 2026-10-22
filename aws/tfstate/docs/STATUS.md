# Status: AWS Terraform rebuild

Rolling record of how this repo looked when the rebuild started, what has
changed since, and what is deployed. Add new entries at the top of the
change log, and update "Current state" and "Open items" when they change.

- Account: `650836812595` (Free plan, $120 credits until 2027-04-22) since
  2026-10-22; before that `084375569056`
- IAM user / CLI profile: `blue-elephant` (pinned in every provider, backend
  and script; providers also set `allowed_account_ids`)
- Region: `us-east-2` for dev, prod and ecommerce-k8s. An SCP from the
  organization's management account (`100434099521`) denies all other regions
- Terraform: AWS provider `~> 6.65` (6.69.1 installed)

## Remember

- **Stop AWS costs between sessions:** destroy single_instance (prod, then
  dev), then run `aws/scripts/aws_wipe.sh` for the tfstate layer. Rebuild
  with the build order below, starting at step 1.
- **Shortcuts:** `aws/scripts/kube_use.sh dev|prod` switches kubectl and
  shows nodes and pods; `aws/scripts/ssh_ec2.sh dev|prod [public|private]`
  SSHes in. kubectl follows the current context, not your directory.
- **SSH to the private EC2 instance goes through the public one; no key is
  stored on either instance.** Until 2026-10-16 the public instance's user
  data copied your private key onto it so you could SSH onward. That was
  removed because the key ended up in plan output and Terraform state. Now
  your laptop keeps the key and `ssh -J` hops through:

  ```sh
  ssh -i ~/.ssh/aws_ssh -J ubuntu@<public-ip> ubuntu@<private-ip>
  ```

  Add the key to your agent first (`ssh-add ~/.ssh/aws_ssh`)
  so the second hop can use it. Details: `single_instance/docs/KUBECTL.md`,
  "Reaching the EC2 instances". One key pair serves dev and prod.
- **Apply dev before prod:** prod looks up the IAM roles and users that dev
  creates.
- **Your home IP changes:** check `curl -4 ifconfig.me` against
  `my_laptop_cidr_block` before plan/apply or kubectl.

## Current state (2026-10-22)

New account `650836812595` (us-east-2) has:

| Layer | dev | prod |
|---|---|---|
| `tfstate/bootstrap` (local state) | **applied** 2026-10-22: `blue-elephant-tfstate-admin-dev` + `-logs`; `check_resources.sh dev` 5/5 PASS | not applied |
| `tfstate/environments` | **applied** 2026-10-22: `alias/tfstate-dev` (enabled, rotation on); `check_resources.sh dev` 7/7 PASS | not applied |
| EC2 key pair `blue-elephant` | imported (shared) | imported (shared) |
| `single_instance` | **applied** 2026-10-22 (env `multi`, suffix `765jm01j`, `vpc-0efe071f9d720d8c8`): `check_resources.sh dev` 23/23 PASS; SSH public and private OK; 4 EKS nodes Ready, all pods Running. Estimate **$211/month, $6.94/day** | not applied |
| `ecommerce-k8s` | not applied (Pod Identity change in code) | — |

Plus the `monthly-5usd` budget (CLI-created). The table below is the old
account `084375569056` as last left.

### Deployed in AWS (old account)

| Layer | dev (us-west-2) | prod (us-west-1) |
|---|---|---|
| `tfstate/bootstrap` (local state) | **destroyed** 2026-10-16 by `aws_wipe.sh` | **destroyed** 2026-10-16 by `aws_wipe.sh` |
| `tfstate/environments` (state in bootstrap bucket, key `terraform.tfstate`) | **destroyed** 2026-10-16 (was suffix `gmeemt5w`); KMS keys pending deletion | **destroyed** 2026-10-16 (was suffix `l4ilb4si`); KMS keys pending deletion |
| EC2 key pair `bluedragon` | ed25519, re-created 2026-10-16 after exposure; matches `~/.aws/bluedragon_uswest2.pem` (old key kept as `.pem.exposed`) | matches `~/.aws/bluedragon_uswest1.pem` (same key as `~/.aws/bluedragon.pem`) |
| `single_instance` | **destroyed** 2026-10-16 (last suffix `pvneok82`); state empty. Rebuild: `plan -out` + `apply` | **destroyed** 2026-10-16 (last suffix `w0xkpjbs`); state empty. Rebuild after dev |
| `ecommerce-k8s` | not deployed (us-east-1, own state bucket, which was wiped); stages validate | — |

Unrelated bucket in the same account: `grid-meter-app-tfstate-084375569056`
holds another project's Terraform state. Do not delete it.

### Where state lives

| Root | Bucket | Key | Encryption |
|---|---|---|---|
| `tfstate/bootstrap/{env}` | local `terraform.tfstate` | — | — |
| `tfstate/environments/{env}` | `blue-elephant-tfstate-admin-{env}` | `terraform.tfstate` | SSE-S3 |
| `single_instance/environments/{env}` | `blue-elephant-tfstate-admin-{env}` | `single_instance/terraform.tfstate` | SSE-KMS via `alias/tfstate-{env}` |
| `ecommerce-k8s/*` | `blue-elephant-ecommerce-terraform-state` (us-east-2) | per stage | — |

Locking uses S3 native lock files (`use_lockfile = true`); no DynamoDB table.

## Build order (from scratch)

1. `tfstate/bootstrap/{dev,prod}`: `terraform init`, `plan -out bootstrap-{env}`, `apply bootstrap-{env}`
2. `tfstate/environments/{dev,prod}`: `terraform init -upgrade -backend-config=backend.hcl -reconfigure`, `plan -out bucket-{env}`, `apply bucket-{env}`
3. EC2 key pair `blue-elephant` in us-east-2 (one for dev and prod): imported
   2026-10-22 from `~/.ssh/aws_ssh.pub`. Command and checks:
   `README.aws.md`, "EC2 SSH key pair"
4. `single_instance/environments/dev`, then `prod` (prod reads dev's IAM): check `curl -4 ifconfig.me` matches
   `my_laptop_cidr_block` in `terraform.tfvars`, then
   `terraform init -upgrade -backend-config=backend.hcl -reconfigure`, then plan/apply
5. kubectl: see `single_instance/docs/KUBECTL.md`

`terraform.tfvars` is git-ignored in every environment. On a fresh clone,
copy `terraform.tfvars.example` to `terraform.tfvars` and fill it in.
To check that nothing ignored is still tracked: `git ls-files -ci --exclude-standard`
(it should print nothing).

Saved plan files (`plan-*`, `bootstrap-*`, `bucket-*`, `dev-bucket`, `prod-bucket`)
are git-ignored. Provider lock files are git-ignored and machine-local; if
`init` reports a checksum mismatch, delete `.terraform.lock.hcl` and re-run init.

## Change log

### 2026-10-22: single_instance/dev applied and verified

Second `plan -out bucket-dev`: 5 to add (2 EC2 `t3.small`, `ec2_policy`,
`assume_admin` for sre and dba); applied. Verified with
`check_resources.sh dev` (23 passed), `ssh_ec2.sh dev [private]`,
`kube_use.sh dev`, `inspect_aws.sh`, `scan_aws.sh`.
`estimate_costs.sh`: $210.91/month ($6.94/day): EKS $73, NAT $32.85, EC2
$60.74, Fargate $9, Redis $12.41, EBS $9.60, IPv4 $7.30, KMS $6. At that
rate the $120 Free-plan credits last about 17 days.

- **scan_aws.sh:** removed `aws kms schedule-key-deletion --key-id <key-id>`
  from this read-only scan (it only failed because `<key-id>` became a shell
  redirect); `Tags` columns in table output (which crashed the CLI with
  "list index out of range" / "Row should have 4 elements") replaced by the
  Name tag; `iam list-policies --scope Local`.
- **aws_env.sh:** `AWS_PAGER=""`, so long output no longer stops in `less`.
- **EKS node volumes encrypted (fixed same day):** the `eks_nodes` launch
  template's `ebs` block had no `encrypted = true`, so node root volumes
  were unencrypted. Added it (AWS-managed `aws/ebs` key, as on the EC2
  instances). Plan: 0 add, 2 change (launch template v2, node group). EKS's
  managed rolling update (not kubectl/kubeadm) surged new nodes, drained
  and terminated the old ones; `VersionUpdate` Successful about 15 min.
  `check_resources.sh` has a new check, "EKS node volumes encrypted: N of
  N" (needs N > 0); dev now 24 passed, 0 failed.

### 2026-10-22: org SCP also denies IAM groups and OIDC providers

The single_instance/dev apply's third error: `iam:CreateGroup` denied by
SCP `p-q1nvo865` (organization `o-dgbvkwy7f6`). IAM policy simulator
(`aws iam simulate-principal-policy`) with
`--context-entries ContextKeyName=aws:RequestedRegion,ContextKeyValues=us-east-2,ContextKeyType=string`
shows the real denies are only `iam:CreateGroup` and the other group actions,
`iam:CreateLoginProfile` and `iam:CreateOpenIDConnectProvider`. EKS (incl.
Pod Identity, add-ons, access entries), ELB, S3, EC2, KMS and the rest of IAM
are allowed. Without the region context the simulator wrongly reports
almost everything as denied (the region SCP's condition matches a missing
key).

- **single_instance:** the `operations` group, its membership, inline policy
  and group attachment are gone; `aws_iam_user_policy_attachment.assume_admin`
  attaches `AssumeAdminRolePolicy` to `sre` and `dba` directly (same
  permission). dev plans 5 to add (2 EC2 at `t3.small`, `ec2_policy`, 2
  attachments).
- **ecommerce-k8s:** the load-balancer controller moves from IRSA (OIDC
  provider) to EKS Pod Identity: `modules/eks` adds the
  `eks-pod-identity-agent` add-on (after the node groups) instead of the OIDC
  provider; `files/iam-alb-controller-role.json` trusts
  `pods.eks.amazonaws.com`; stage1 adds `aws_eks_pod_identity_association`
  for `kube-system/aws-load-balancer-controller`; stage2 drops the
  `role-arn` annotation and the web-identity token settings. Node groups
  `t3.medium` → `t3.small` (tfvars) with a Free Tier validation.
  `modules/alb-controller` and `files/values.yaml` (unused by the stages)
  still carry the old annotation.

### 2026-10-22: single_instance/dev apply; Free plan rejects t3.medium

`plan -out bucket-dev` (110 to add), `apply bucket-dev` started 18:14Z. Both
EC2 instances failed at launch: CloudTrail RunInstances
`Client.InvalidParameterCombination`, "The specified instance type is not
eligible for Free Tier" (`t3.medium`). The rest of the apply carried on.

- **Free plan limits EC2 to Free Tier types.** In us-east-2 on 2026-10-22:
  `t3/t4g/t8i.micro` (1 GiB), `t3/t4g/t8i.small` (2 GiB), `c7i-flex.large`
  (4 GiB), `m7i-flex.large` (8 GiB). Check with
  `aws ec2 describe-instance-types --filters Name=free-tier-eligible,Values=true`.
- **dev `instance_type`:** `t3.medium` → `t3.small` (local tfvars). Prod was
  already `t3.micro`. EKS nodes use `t3.micro` (eligible).
- **Validation:** `instance_type` and `eks_node_instance_type` in both
  single_instance environments now fail at plan unless Free Tier eligible.
- **ecommerce-k8s** stage1 node group is `t3.medium` × 4: must change before
  its apply.
- **check_resources.sh:** the EC2 checks now expect 2 running instances and
  2 with IMDSv2 required. The old IMDS check counted non-compliant instances
  and expected 0, which also passed with no instances at all (as here).
- **Next:** let the apply finish (it will report 2 errors), then plan again:
  expect 2 to add (the instances).

### 2026-10-22: tfstate/environments/dev applied in the new account

`init -upgrade -reconfigure -backend-config=backend.hcl` (the saved backend
still pointed at the old us-west-2 bucket, so a plain `plan` failed with
"S3 bucket bluedragon-tfstate-admin-dev does not exist"), `plan -out
bucket-dev` (2 to add: KMS key + `alias/tfstate-dev`), `apply bucket-dev`.
`check_resources.sh dev`: 7 passed, 0 failed. AWS provider now 6.70.0 in
this root's lock file.

- **Re-init after the move:** `tfstate/environments/prod` and
  `single_instance/environments/prod` still have the old us-west-1 backend
  saved in `.terraform/`; re-init each once `tfstate/bootstrap/prod` exists.
  `single_instance/environments/dev` was re-initialized 2026-10-22 (empty).
- **check_resources.sh:** the "single_instance state object" check moved
  from the tfstate/environments section (it failed whenever single_instance
  wasn't applied) into the single_instance section, and now expects the
  object to be `aws:kms` encrypted.

### 2026-10-22: tfstate/bootstrap/dev applied in the new account

`plan -out bootstrap-dev` (13 to add, S3 only), `apply bootstrap-dev`: 13
added. `check_resources.sh dev`: 5 passed, 0 failed.

- **check_resources.sh fix:** `expect` now turns tabs into spaces before
  comparing. `--output text` separates list values with tabs, so the
  multi-value checks (public access block, Redis TLS/at-rest/AUTH) could
  never pass before.

### 2026-10-22: everything in aws/ moved to the Free-plan account; $5 budget

Code only at the time; nothing applied in the new account. All nine roots
`validate`; `tfstate/bootstrap/dev` plans 13 to add against the new account.

New AWS account `650836812595` (Free plan, $120 credits, expires
2027-04-22) replaces `084375569056` for tfstate, single_instance,
ecommerce-k8s and the upcoming `aws/datastore-clusters` tree.

- **Region:** the account is in organization `o-dgbvkwy7f6` (management
  account `100434099521`), whose SCP denies every region except us-east-2
  (global endpoints such as IAM, Budgets and the Price List API in us-east-1
  still work). dev, prod and ecommerce-k8s all move to us-east-2. AZs: dev
  `us-east-2a/b`, prod `us-east-2b/c`, ecommerce `us-east-2a/b`.
- **Credentials pinned:** every AWS provider sets `profile = "blue-elephant"`
  and `allowed_account_ids = ["650836812595"]` (variables `aws_profile` and
  `aws_account_id` in the environment roots, inline in bootstrap and
  ecommerce-k8s), so a wrong profile fails at plan time. Every backend.hcl
  sets `profile`. The EKS token exec and `kubeconfig_command` pass
  `--profile`.
- **Name collisions (dev and prod now share a region):** regional names
  that had no env now end in `-<env>`: `redis-single-instance-<env>`,
  subnet group `<env>-private`, `ecs-cluster-<env>`, task family
  `tasks-<env>`, `alias/eks-key-<env>`, `alias/my-custom-sns-key-<env>`,
  `example-topic-<env>`, `custom-topic-<env>.fifo`. The cache, compute and
  kms modules take a new `env` variable. DeveloperPolicy and AdminPolicy
  match these with wildcards.
- **Scripts:** new `scripts/aws_env.sh` holds `ACCOUNT_ID`, `AWS_PROFILE`
  (exported, not inherited), `REGION` per env, `REGIONS` and
  `require_account`; every script sources it. `check_resources.sh` now pins
  network, EC2, Redis, SNS and node group checks to the env's VPC (new output
  `vpc_id`) and tf env name, so dev can't pass on prod's resources.
  `ssh_ec2.sh` uses one key, `~/.ssh/aws_ssh`.
- **IAM user:** `admin_user_name` (KMS key admin, ecommerce aws-auth and
  access entry) is `blue-elephant`; the ecommerce kubectl RBAC YAML subjects
  follow.
- **ecommerce-k8s:** live config only (stages, modules, files, scripts):
  account, region, profile and user replaced. `docs/`, `deprecated/`,
  `*.orig` and logs are left as history. Scripts with hard-coded old resource
  IDs (`02_alb_health.sh`, `06_share.sh`, `residue_check.sh`) only had
  account and region swapped; their IDs are stale until a redeploy.

- **CLI profile:** `blue-elephant` (IAM user `blue-elephant`,
  AdministratorAccess), region `us-east-2`. Verify with
  `aws sts get-caller-identity --profile blue-elephant`.
- **Budget:** `monthly-5usd`, created with the CLI (not Terraform yet; import
  it once this account has a state backend). $5/month cost budget. Emails
  `allinonegulp@gmail.com` when actual spend or the month's forecast goes
  over $5.
- **Prefix renamed `bluedragon` → `blue-elephant`** in all live config
  (not history): state buckets `blue-elephant-tfstate-admin-{dev,prod}`,
  `blue-elephant-dev-bucket-*`, `blue-elephant-log-bucket-*`, Project tag
  `blue-elephant-single-instance`, ecommerce state bucket
  `blue-elephant-ecommerce-terraform-state`, app bucket
  `blue-elephant-ecommerce-app-us-east-2-prod`, Kubernetes roles
  `blue-elephant-admin`/`-impersonator`, `ecommerce-k8s/files/blue-elephant-*.yaml`
  (git mv) and Terraform addresses `blue_elephant_*`. `aws_wipe.sh` and
  `estimate_costs.sh` now look for `blue-elephant-` buckets. All bucket names
  were free on 2026-10-22.
- **Key pair:** `blue-elephant` (ed25519) imported into us-east-2 from
  `~/.ssh/aws_ssh.pub`; details in `README.aws.md`, "EC2 SSH key pair".
- **Next:** follow the build order from step 1. Watch credits: EKS, NAT
  gateways and ElastiCache in both envs run well past $5/month.

### 2026-10-21: security fixes (group 1) and cleanup (group 3); not applied

Code only; AWS stays destroyed. All six roots `validate`; scratch-copy plans
with a local backend (the S3 backends are gone): single_instance dev 110 to
add, each bootstrap 13, each tfstate environment 2. Prod single_instance
can't be planned until dev's shared IAM exists.

- **Redis:** `aws_elasticache_replication_group` (one node, Redis 7.1,
  `default.redis7`) replaces `aws_elasticache_cluster`, which can't do TLS
  or AUTH for Redis. In-transit and at-rest encryption on; 32-character AUTH
  token from `random_password`, output `redis_auth_token` (sensitive; in the
  KMS-encrypted state). Outputs `redis_primary_endpoint`. Test from the
  private EC2: `REDISCLI_AUTH=<token> redis-cli -h <endpoint> -p 6379 --tls PING`.
- **IAM:** DeveloperPolicy and AdminPolicy no longer take dev's ARNs
  (`ec2_arns`, `s3_bucket_arn`, `elasticache_arn`, `ecs_*_arn`,
  `sns_topic_arns`, all removed). They match resources by name in any region
  (`bluedragon-dev-bucket-*`, `redis-single-instance`, `ecs-cluster`,
  `example-topic`, KMS keys) and EC2 instances by the new tag
  `Project = bluedragon-single-instance`, so one copy covers dev and prod and
  instance replacements don't rewrite them. `ec2:Describe*` is on `*` (it
  has no resource-level permissions).
- **IMDSv2** on the EKS node launch template (`http_tokens = required`, hop
  limit 2); the EC2 instances already had it.
- **VPC flow logs encrypted** with their KMS key: `kms_key_id` was commented
  out and used the key ID; CloudWatch Logs needs the ARN. Restored the key
  policy's encryption-context condition.
- **tfstate/environments** now creates only the state KMS key and
  `alias/tfstate-{env}`. Removed the unused suffixed state and log buckets,
  the SNS topic and its KMS key (`tfstate/modules/messages` deleted): about
  $2/month less, 2 resources per env instead of 21.
- **Cleanup:** removed 28 unused variables/data sources (tflint), made the
  compute module's `instance_type` required (default was `""`), added
  `required_version` to the bootstraps, deleted the 2025 experiments
  `single_instance/environments/dev/eks/{terraform,yaml}` (a second EKS
  cluster, `eks_cluster2`).
- **Provider lock files committed** for the six AWS roots
  (darwin_arm64 + linux_amd64); un-ignored in `.gitignore`.
- **Scripts:** `aws/scripts/check_resources.sh dev|prod` and
  `aws/scripts/estimate_costs.sh` (AWS versions of Azure's). Only the
  "not applied" paths and the price lookups are tested so far (both regions:
  EC2, EBS, EKS, NAT, ElastiCache, ALB); the rest needs a rebuild. Price
  lookups showed Redis 6 now carries ElastiCache extended-support charges
  ($0.018-0.035 per node-hour extra), which the move to 7.1 avoids.
- **Docs:** rewrote `README.AWS.md` (layout, build and teardown order, links);
  fixed `environment/` paths in `aws/tfstate/README.md`.
- **Scanners:** installed tflint 0.64.0 (GitHub release), trivy 0.76.1,
  checkov 3.3.20. `.tflint.hcl` per cloud (`aws/` moved up from
  `aws/single_instance/`; AWS ruleset pin fixed: 0.50.0 never existed, now
  0.49.0). `trivy.yaml` reported MEDIUM only; now MEDIUM, HIGH, CRITICAL.
  Hook and GitHub Action run them report-only. Accepted exceptions inline
  (`# trivy:ignore:AWS-0040` for the laptop-only EKS endpoint). Guide:
  `aws/README.aws.test.md`.

### 2026-10-19

- Deleted `aws/scripts/cleanup_aws.sh`: it deleted every S3 bucket in
  whatever account the AWS profile pointed at, without confirmation (risk to
  the live grid-meter account `184375956348`). `aws_wipe.sh` replaces it.
- Deleted `aws/scripts/cleanup_aws_2.sh`: no account check, and it deleted
  IAM roles matching `Admin`, `Developer` or `eks-`, which would hit
  grid-meter's roles if run under its profile. `aws_wipe.sh` replaces it.
- GCP port started in `gcp/tfstate` (project `bluedragon-sre-vuft1e`); its
  record is `gcp/tfstate/docs/STATUS.md`.

### 2026-10-16

- **Rewrote `aws/scripts/aws_wipe.sh`** to tear down the tfstate layer (4
  enabled KMS keys, about $4/month, plus the 8 `bluedragon-tfstate-admin-*`
  buckets). Refuses to run while either single_instance state has resources
  and checks it's in account 084375569056. Asks you to type `wipe`, then
  destroys `tfstate/environments/{prod,dev}` and then
  `tfstate/bootstrap/{prod,dev}` with Terraform output shown. Before each
  destroy it empties that state's versioned buckets; it retries if late access
  logs arrive. Ends with a leftover check in us-west-1 and us-west-2. Old
  version: hid all output, deleted every `bluedragon-*` bucket outside
  Terraform (orphaning the KMS keys), and only checked us-west-2.
- **Ran `aws_wipe.sh`:** all four tfstate roots destroyed (bootstrap dev: 13
  destroyed), leftover check clean in both regions. The account now holds
  nothing from this repo except the free EC2 key pairs `bluedragon`; KMS keys
  are pending deletion. Next rebuild starts at build order step 1.
- **Destroyed prod, then dev; both stopped partway.** Prod: everything gone
  except `bluedragon-log-bucket-w0xkpjbs` (BucketNotEmpty: versioned access
  logs). Dev: node group, instances, IAM and most resources gone; left were the
  EKS cluster (no nodes), NAT gateway, EIP, VPC, subnets, IGW, cluster SG, EKS
  KMS key, `app1` namespace, the ingress and `bluedragon-log-bucket-pvneok82`.
  Causes: (1) log buckets had no `force_destroy`; (2) the ALB controller
  (helm release) was destroyed before the ingress, so nothing removed the
  ingress's `ingress.k8s.aws/resources` finalizer and the delete timed out
  after 20 minutes (no ALB existed). Fixes: `force_destroy = true` on the log
  bucket, and the ingress `depends_on` the helm release so it's destroyed
  first. Cleanup: remove the finalizer with kubectl, `apply -target` the log
  bucket to record `force_destroy`, then destroy again.
  Prod finished: a full destroy plan failed because prod's IAM data sources
  look up dev's shared IAM, already deleted; `terraform destroy -target` on the
  log bucket and `random_string.suffix` removed the last 2. Prod state is empty.
  Dev finished after removing the ingress finalizer: 15 destroyed, state
  empty. Checked both regions afterwards: no EKS, NAT, EIP, EC2, non-default
  VPC, load balancer or ElastiCache left. Remaining: the tfstate buckets and
  KMS keys (kept for the rebuild) and grid-meter's state bucket.
- **Private instance had no outbound internet.** Its security group
  (`private_ec2`) only allowed egress to the VPC CIDR on 22 and 443, so
  nothing reached the NAT gateway: the user data's `apt-get install
  redis-tools` and CloudWatch agent download failed silently, apt patching
  couldn't work, and SSM (no VPC endpoints) couldn't connect. Redis on 6379
  wasn't allowed out either. Predates this rebuild. Now egress allows 443 and
  80 to `0.0.0.0/0` (through the NAT) and 6379 to the private subnets.
  Inbound is unchanged (SSH and ping from the public subnet). The private
  instance is replaced with `-replace` so its user data runs again.
  Applied: dev 1 added / 4 changed / 1 destroyed (private `10.1.4.26`), prod
  1 added / 2 changed / 1 destroyed (private `10.0.4.223`). Verified:
  `redis-cli` 7.0.15 installed on both; all four instances `Online` in SSM
  (agent 3.3.4793.0), so Session Manager works too. `redis-cli PING` to dev's
  ElastiCache from dev's private instance returns `PONG`.
- **EC2 instances: Ubuntu 20.04 -> 24.04.** The AMI filter was
  `ubuntu-focal-20.04` (standard support ended May 2025; the login banner
  listed 186 security updates available only through paid ESM), although the
  instances were tagged `ubuntu-24.04`. Now
  `ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*` (20261004
  build in both regions). User data: pip installs use
  `--break-system-packages` (24.04 blocks pip into the system Python), and
  the private instance no longer installs the SSM agent .deb (Canonical's AMI
  ships it as a snap). Replaces both instances in each environment; new IPs
  and new SSH host keys. Dev applied: 2 added, 3 changed, 2 destroyed
  (`DeveloperPolicy` and `AdminPolicy` also list dev's instance ARNs, so they
  update too); AMI `ami-03d70b8354a16a8bc`. Verified: public instance runs
  24.04.5, cloud-init finished, aws-cli 2.38.1, kubectl 1.37.1, terraform
  1.5.7, Python kubernetes/boto3 import; private instance runs 24.04.5 but
  `redis-cli` is missing (see open items). Prod applied (2 added, 1 changed,
  2 destroyed) with the same results: public `54.183.161.163`, private
  `10.0.4.137`.
- **Scripts:** added `aws/scripts/kube_use.sh` and `aws/scripts/ssh_ec2.sh`
  (tested against both clusters and both environments' state). Fixed
  `aws/scripts/inspect_aws.sh`, which failed with a syntax error: it had an
  unfinished function left over from a cleanup script. Verified by the user:
  `kube_use.sh` dev and prod, `ssh_ec2.sh` dev public and private.
- **dev and prod both managed the same IAM objects.** Prod skipped creating
  the shared roles, users and group, but still managed policies and
  attachments on them under the same AWS names. `EC2Policy` lists one
  environment's instance ARNs, so each apply overwrote the other's (dev plan
  after the prod apply: 1 to change, prod's us-west-1 ARNs back to dev's), and
  destroying prod would have deleted these from dev. Fix: the 9 attachments
  and policies on shared IAM (`operations_membership`,
  `attach_assume_admin_policy`, `developer_attach`, `admin_attach`,
  `operations_assume_role`, `ec2_ssm`, `ec2_eks_cluster`,
  `ecs_task_execution_role` attachment, `vpc_flow_logs_policy`) now exist only
  where `create_iam_resources = true` (dev). `EC2Policy` is per environment:
  `EC2Policy-<env>-<suffix>`. Prod must drop them from its state first with
  `terraform state rm` (this leaves AWS untouched); otherwise its plan would
  destroy them.
  Applied: prod `state rm` (10 removed), prod 1 added
  (`EC2Policy-prod-w0xkpjbs`), dev 1 added / 1 destroyed (`EC2Policy` ->
  `EC2Policy-multi-pvneok82`). Prod can now be destroyed without touching dev.
- **Prod apply (suffix `w0xkpjbs`): 78 of 79 created, then
  `Error: reading Security Group (): empty result` on
  `module.networking.aws_security_group_rule.eks_cluster_ingress`.** Prod never
  passed `eks_cluster_sg_id` or `sg_public_ec2_id` to the networking module,
  and both defaulted to `""`, so the rule had no group IDs. Dev passed both,
  which is why dev worked. Fix: prod now passes
  `eks_cluster_sg_id = module.eks.eks_cluster_sg_id`; the variable no longer
  has a default, so leaving it out fails at plan time instead of mid-apply.
  `sg_public_ec2_id` is removed: the rule's source is the module's own
  `aws_security_group.public_ec2`, which is what dev was passing back in.
  Re-applied prod: 1 added, 0 changed, 0 destroyed.
- **Repo checks:** new pre-commit hook `scripts/git-hooks/pre-commit`
  (enabled with `git config core.hooksPath scripts/git-hooks`, already set on
  this Mac) and GitHub Action `.github/workflows/repo-checks.yml`. Both block
  tracked files that `.gitignore` excludes, secrets (gitleaks, installed via
  Homebrew) and unformatted Terraform. `.gitleaksignore` accepts the 4
  redacted 2025 access key ID findings. See `docs/REPO_CHECKS.md`, which also
  has a cheat sheet of pre-commit, trivy, tflint, checkov and the rest.
- **Stopped tracking files `.gitignore` already excludes** (`git rm --cached`;
  the files stay on disk). They were committed in 2025, after the ignore rules
  were added, and git keeps tracking a file once it's committed. Removed:
  both prod `terraform.tfvars` (home IP, employer name), `tfstate/logs/*.log`,
  `basic/logs/aws_configure.log`, a saved binary plan
  `single_instance/environments/dev/bucket-dev`, and old state
  `ecommerce-k8s/stage2-k8s/statefile.json`. None contained credentials
  (checked). Added `terraform.tfvars.example` in each environment, and
  `.gitignore` now also covers `*statefile*.json`, `*.pem` and `*.key`. Older
  commits still contain these files; history was not rewritten.
- **Applied:** `single_instance/environments/dev`, the remaining 15 to add
  and 1 to change, with the security group, key-copy and IAM fixes below.
  Verified: 4 nodes Ready; heartbeat/monitor Services created and pods
  Running; ALB controller, coredns, aws-node and kube-proxy Running;
  `kubectl auth can-i` as `sre` gives yes in app1 and no in app2; SSH
  laptop -> public -> private with `ProxyJump`, with no private key on either
  instance. `app-ingress` has no ADDRESS (see Open items).
- **Rotated the us-west-2 EC2 key pair `bluedragon`** (ed25519) before the
  EC2 instances were created.
- **Applied (partial):** `single_instance/environments/dev`, 94 of 109.
  Failed: `EC2Role` already exists (an orphan created 2025-09-19, tagged
  `Environment=Dev`, with AmazonEC2FullAccess and AmazonS3FullAccess, no
  instance profile; not from this repo's code and missed by the wipe); and the
  heartbeat/monitor Services, because the API server could not reach the ALB
  controller's webhook on the nodes.
- **Deleted orphan `EC2Role`** (AWS CLI, outside Terraform): detached
  AmazonEC2FullAccess and AmazonS3FullAccess, then deleted the role. Checked
  first that nothing used it: no references in ecommerce-k8s or grid-meter-app
  (which moved to account 184375956348 on 2026-10-06); no instance profile;
  AWS `RoleLastUsed` empty, so unused since its creation on 2025-09-19.
- **Fixes after the dev apply (uncommitted):**
  - EKS security group: added an all-traffic ingress rule from itself. The
    control plane and nodes share this group, which only allowed 443 from the
    VPC, so webhooks (9443), kubelet (10250) and cross-node pod traffic
    (DNS) were blocked.
  - Public EC2 user data no longer copies a private key onto the instance;
    removed `ssh_private_key_path` everywhere. The us-west-2 key appeared in
    plan output shared in a chat session, so that key pair needs to be replaced.
    To reach the private instance, use `ssh -J ubuntu@<public-ip> ubuntu@<private-ip>`.
  - IAM is global: prod now sets `create_iam_resources = false` on its
    identity and vpc modules and looks up the roles, users and policies that
    dev creates. Before this, a prod apply would have collided with dev on
    `EC2Role`, `Admin`, `sre`, `vpc-flow-logs-role` and others. Fixed the
    identity output `ec2_role_name` for that case. **Prod now requires dev to
    be applied first.**
- **EKS access and node size:** single_instance EKS API endpoint is now
  public, limited to `my_laptop_cidr_block` (validation rejects empty or
  `0.0.0.0/0`); private access stays on for nodes. `access_config` set
  explicitly: `CONFIG_MAP` auth with cluster-creator admin, not left to
  provider or API defaults. EKS nodes are `t3.micro` (4 pods each,
  2 for system pods); new variables `eks_node_desired_size`/`eks_node_max_size`:
  dev 4/5 (its 8 pods need every slot), prod 3/4. dev `aws-auth` patch waits
  for the node group (`depends_on = [module.eks]`). New output
  `kubeconfig_command`; kubectl directions in `single_instance/docs/KUBECTL.md`.
  Laptop IP changed: `my_laptop_cidr_block` 23.93.84.244 -> 23.93.161.67 in
  both tfvars. Read-only plans: prod 92 to add, dev 109 to add.
- **ecommerce-k8s, M4 move:** deleted Intel (`darwin_amd64`) provider caches
  and lock files in `terraform-state`, `stage1-infra`, `stage2-k8s` and the
  stray root lock file, plus an empty `stage2-k8s/.terraform 2`; re-initialized
  for `darwin_arm64` (AWS 6.69.1). Fixed validation: stage1 dropped
  `control_plane_subnet_ids` and duplicate subnet tags (the vpc module sets
  them); stage1 now outputs `vpc_public_subnets`, which stage2 reads; stage2
  removed duplicate providers and outputs from `main.tf`, kept the
  `aws eks get-token` providers in `providers.tf`, added the `random` provider,
  and its remote-state key now matches stage1's backend key
  (`ecommerce-k8s/stage1-infra/terraform.tfstate`). EKS `cluster_version`
  1.29 -> 1.36 (EKS no longer offers 1.29), node group `ami_type`
  `AL2023_x86_64_STANDARD`. All three roots pass `terraform validate`. Its old
  `terraform-state/terraform.tfstate` (local) still describes the wiped bucket.
- **EKS update:** cluster version 1.28 -> 1.36 (AWS default, standard
  support to 2027-08). Node group uses `ami_type = "AL2023_x86_64_STANDARD"`;
  the launch template no longer sets `image_id` or bootstrap user data, so EKS
  supplies the Amazon Linux 2023 image and bootstraps with `nodeadm` (removed
  the `aws_ami` lookup and `/etc/eks/bootstrap.sh` script). Launch template is
  referenced by `latest_version` instead of `"$Latest"`. New variable
  `eks_node_instance_type` (default `t3.medium`) so prod EKS nodes no longer
  share `instance_type` (`t3.micro`, still used for EC2/ECS). Read-only plans:
  prod 92 to add, dev 109 to add, 0 change/destroy, no errors.
- **Commit (this file):** Added `alias/tfstate-{env}` on the tfstate stage's
  state KMS key; `single_instance` `backend.hcl` now sets `kms_key_id` to that
  alias, so single_instance state is KMS-encrypted. Applied the alias in dev
  and prod. Removed stale Intel-era lock files in `single_instance/environments`
  and re-initialized. Removed obsolete `tiller` entry from top-level `README.md`.
- **Applied:** logging fixes from `8f4206f` to all four tfstate roots
  (bootstrap 3 changes each; environments 4 changes + 1 destroy each).
- `8f4206f` Fix tfstate access logging and notifications:
  log bucket SSE-S3 (access log targets cannot use SSE-KMS), log bucket policy
  principal `logging.s3.amazonaws.com`, notifications filter on `.tfstate` and
  `state-logs/`, removed unused log-bucket KMS key, bootstrap no longer uses
  placeholder `key/dummy` ARNs.
- **Applied:** `tfstate/environments/{dev,prod}` (21 resources each).
- `ee9d315` Give single_instance its own state key: single_instance and the
  tfstate stage both used `terraform.tfstate` in the same bucket; a
  single_instance plan would have destroyed the tfstate stage's resources.

### 2026-10-15

- **AWS:** All resources for every project under this repo were wiped
  beforehand; IAM user `bluedragon` and the account remain. New access key
  created for `bluedragon` (the old key ending `IAEZ` was invalid).
- **Applied:** `tfstate/bootstrap/{dev,prod}` (13 resources each). Imported
  EC2 key pair `bluedragon` in us-west-1 and us-west-2.
- `2456e28` Parameterize account, admin user and key pair; upgrade AWS
  provider to 6.x: account ID from `aws_caller_identity`; new variables
  `admin_user_name`, `ssh_private_key_path`; `ec2_keypair` required; values in
  `terraform.tfvars`; identity module derives KMS region from the provider;
  all AWS provider pins `~> 6.65`.
- `05f08e1` Single-cluster EKS module; fix dev env, scripts, and repo hygiene:
  EKS module one cluster per env with AMI lookup; dev env rewired to it;
  kubernetes module pins helm 2.x and uses `var.region`; `cleanup_aws_2.sh`
  syntax fix and confirmation before deleting tfstate buckets; `scan_aws.sh`
  ordering fix; stopped tracking binary plan files; redacted access key IDs;
  `terraform fmt -recursive`.
- Retired the pre-commit hook (`.git/hooks/pre-commit.old-macbook`): it
  pointed at a Python virtualenv on the old Intel MacBook that no longer exists.

## Original state (baseline, 2026-10-15)

As found at the start of the rebuild, before `05f08e1`. Upstream was `b6f7cbf`.

- Built in 2023–24 with generative AI assistance on an older Intel MacBook;
  `README.AWS.md` credits xAI Grok.
- Local, uncommitted work in progress: the EKS module was mid-refactor from
  multiple clusters (`cluster_names`, `for_each`) to one per environment;
  prod was updated, dev was not and failed `terraform validate`.
- `aws/scripts/cleanup_aws_2.sh` (untracked) had a bash syntax error and
  deleted every `bluedragon*` bucket without confirmation, including state.
- Binary saved plans (`plan-dev`, `plan-prod`, `bootstrap-*`, `bucket-*`) were
  committed; `.gitignore` pattern `*plan` did not match them.
- AWS access key IDs appeared in driftctl output under `single_instance/docs`
  and `single_instance/logs` (still present in git history; key since revoked).
- Hardcoded account `084375569056`, user `bluedragon`, key path
  `~/.aws/bluedragon.pem` across modules, tfvars and ecommerce-k8s.
- AWS provider pinned to 5.x (`5.94.1`, `~> 5.0`, `~> 5.95.0`).
- tfstate bootstrap encrypted buckets with a placeholder `key/dummy` KMS ARN.
- single_instance and tfstate/environments shared one state object per env.
- Prod EKS: version 1.28 with `t3.micro` nodes and an Amazon Linux 2 AMI lookup;
  API endpoint private-only.
- ecommerce-k8s: EKS 1.29; stage1 and stage2 failed `terraform validate`.

## Open items

- **Dev ingress has no load balancer:** `app-ingress` shows no ADDRESS. The
  ALB controller (chart 1.6.0) has no IAM role (no IRSA) and the public
  subnets have no `kubernetes.io/role/elb` tag, so it can't create an ALB.
  Expected; fix together with the chart update below.
- **Laptop IP drift:** the EKS API and SSH rules allow only
  `my_laptop_cidr_block`. When the home IP changes, update both tfvars and
  apply, or Terraform's Kubernetes resources and kubectl time out.
- **Dev EKS capacity is full:** dev's 4 `t3.micro` nodes have 8 free pod
  slots and all 8 are used. Any new workload needs more nodes or bigger nodes.
- **ALB controller chart is old:** dev pins `aws-load-balancer-controller`
  chart 1.6.0 (2023) with no IRSA role annotation; update before relying on it.
- **ecommerce-k8s not plan-tested:** validates, but its state bucket
  `bluedragon-ecommerce-terraform-state` must be re-created (`terraform-state`
  root, whose local state is stale) before init with the backend.
  `stage2-k8s/statefile.json` (old Terraform state) is committed. stage1
  tfvars uses 4 `t3.medium` nodes; the default endpoint CIDR is `0.0.0.0/0`.
- **EKS control-plane logging off** (trivy AWS-0038, checkov CKV_AWS_37):
  set `enabled_cluster_log_types`; small CloudWatch cost.
- **Kubernetes pod hardening** (most checkov/trivy findings): no security
  context, NET_RAW allowed, root user, `:latest` tags in the `kubernetes`
  module. Fold into the ALB/ingress work (group 2).
- **Remaining scanner findings before making them blocking:**
  single_instance trivy 10 MEDIUM, checkov 24; `ecommerce-k8s` tflint 40.
- **Group 1 untested in AWS:** Redis TLS/AUTH, the tag- and name-based IAM
  policies and the flow-log KMS key need a dev rebuild to confirm.
- **EKS node volumes are gp2;** gp3 is 20% cheaper ($0.08 vs $0.10 per GB-month
  in us-west-2) and at least as fast.
