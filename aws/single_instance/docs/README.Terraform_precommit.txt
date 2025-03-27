
Docs
----
1. https://github.com/antonbabenko/pre-commit-terraform
2. :

Installation
------------
tim@Tims-MBP single_instance % brew install pre-commit
==> Downloading https://formulae.brew.sh/api/formula.jws.json
==> Downloading https://formulae.brew.sh/api/cask.jws.json
==> Downloading https://ghcr.io/v2/homebrew/core/pre-commit/manifests/4.2.0
################################################################################################################################### 100.0%
==> Fetching pre-commit
==> Downloading https://ghcr.io/v2/homebrew/core/pre-commit/blobs/sha256:fe5c110c13a889acfc336eb92d16f6556043b2399ba898cf17cc3b64dfd483be
################################################################################################################################### 100.0%
==> Pouring pre-commit--4.2.0.ventura.bottle.tar.gz
🍺  /usr/local/Cellar/pre-commit/4.2.0: 325 files, 6.9MB
==> Running `brew cleanup pre-commit`...
Disable this behaviour by setting HOMEBREW_NO_INSTALL_CLEANUP.
Hide these hints with HOMEBREW_NO_ENV_HINTS (see `man brew`).
==> `brew cleanup` has not been run in the last 30 days, running now...
Disable this behaviour by setting HOMEBREW_NO_INSTALL_CLEANUP.
Hide these hints with HOMEBREW_NO_ENV_HINTS (see `man brew`).
Error: Permission denied @ apply2files - /usr/local/lib/docker/cli-plugins
tim@Tims-MBP single_instance % which pre-commit
/usr/local/bin/pre-commit
tim@Tims-MBP single_instance % pre-commit --version
pre-commit 4.2.0
(py3) tim@Tims-MBP single_instance % pre-commit autoupdate --repo https://github.com/pre-commit/pre-commit-hooks
[https://github.com/pre-commit/pre-commit-hooks] updating v4.5.0 -> v5.0.0
(py3) tim@Tims-MBP single_instance % pre-commit --version
pre-commit 4.2.0


Configuration
-------------
tim@Tims-MBP single_instance % cat .pre-commit-config.yaml
# See https://pre-commit.com for more information
# See https://pre-commit.com/hooks.html for more hooks
repos:
- repo: https://github.com/pre-commit/pre-commit-hooks
  rev: v4.5.0
  hooks:
  - id: trailing-whitespace
  - id: end-of-file-fixer
  - id: check-added-large-files
  - id: check-merge-conflict
  - id: no-commit-to-branch
    args: ['--branch', 'master']
  - id: detect-aws-credentials
  - id: detect-private-key

- repo: https://github.com/antonbabenko/pre-commit-terraform
  rev: v1.88.4
  hooks:
  - id: terraform_fmt
  - id: terraform_docs
    name: Generate tf documents for modules
    files: ^modules/
    args:
    - --hook-config=--path-to-file=README.md        # Valid UNIX path. I.e. ../TFDOC.md or docs/README.md etc.
    - --hook-config=--add-to-existing-file=true     # Boolean. true or false
    - --hook-config=--create-file-if-not-exist=true # Boolean. true or false
  - id: terraform_docs
    name: Generate tf documents for environments
    files: ^environments/
    args:
    - --hook-config=--path-to-file=README.md        # Valid UNIX path. I.e. ../TFDOC.md or docs/README.md etc.
    - --hook-config=--add-to-existing-file=true     # Boolean. true or false
    - --hook-config=--create-file-if-not-exist=true # Boolean. true or false
  - id: terraform_validate
    files: ^environments/
    args:
      - --tf-init-args=-backend=false
  - id: terraform_tflint
  - id: terraform_trivy
    args:
      - --args=--format=json
      - --args=--skip-dirs="**/.terraform"
(py3) tim@Tims-MBP single_instance % rm -rf ~/.cache/pre-commit/*
zsh: sure you want to delete all the files in /Users/tim/.cache/pre-commit [yn]? y
(py3) tim@Tims-MBP single_instance % pre-commit install
pre-commit installed at .git/hooks/pre-commit
(py3) tim@Tims-MBP single_instance % pre-commit --version
pre-commit 4.2.0
(py3) tim@Tims-MBP single_instance % pre-commit run --all-files
[INFO] Initializing environment for https://github.com/pre-commit/pre-commit-hooks.
[INFO] Initializing environment for https://github.com/antonbabenko/pre-commit-terraform.
[INFO] Initializing environment for https://github.com/aquasecurity/tfsec.
[INFO] Initializing environment for https://github.com/bridgecrewio/checkov.
[INFO] Installing environment for https://github.com/pre-commit/pre-commit-hooks.
[INFO] Once installed this environment will be reused.
[INFO] This may take a few minutes...
[INFO] Installing environment for https://github.com/aquasecurity/tfsec.
[INFO] Once installed this environment will be reused.
[INFO] This may take a few minutes...
[INFO] Installing environment for https://github.com/bridgecrewio/checkov.
[INFO] Once installed this environment will be reused.
[INFO] This may take a few minutes...
trim trailing whitespace.................................................Failed
- hook id: trailing-whitespace
- exit code: 1
- files were modified by this hook

Fixing aws/single_instance/docs/README.Terraform_tflint.txt
Fixing aws/single_instance/docs/README.Terraform_tfsec.txt
Fixing aws/single_instance/docs/README.Terraform_checkov.txt
Fixing aws/single_instance/docs/README.Terraform_precommit.txt

fix end of files.........................................................Failed
- hook id: end-of-file-fixer
- exit code: 1
- files were modified by this hook

Fixing aws/single_instance/docs/README.Terraform_tflint.txt
Fixing aws/single_instance/docs/README.Terraform_tfsec.txt
Fixing aws/single_instance/docs/README.Terraform_checkov.txt
Fixing aws/single_instance/docs/README.Terraform_precommit.txt
Fixing aws/single_instance/trivy_current.txt

check for added large files..............................................Passed
check for merge conflicts................................................Passed
don't commit to branch...................................................Passed
detect aws credentials...................................................Passed
detect private key.......................................................Passed
Terraform fmt............................................................Passed
Generate tf documents for modules....................(no files to check)Skipped
Generate tf documents for environments...............(no files to check)Skipped
Terraform validate...................................(no files to check)Skipped
Terraform validate with tflint...........................................Failed
- hook id: terraform_tflint
- exit code: 2

Command 'tflint --init' successfully done:
All plugins are already installed


Execution
---------
tim@Tims-MBP single_instance % pre-commit run -a
[INFO] Initializing environment for https://github.com/pre-commit/pre-commit-hooks.
[WARNING] repo `https://github.com/pre-commit/pre-commit-hooks` uses deprecated stage names (commit, push) which will be removed in a future version.  Hint: often `pre-commit autoupdate --repo https://github.com/pre-commit/pre-commit-hooks` will fix this.  if it does not -- consider reporting an issue to that repo.
[INFO] Initializing environment for https://github.com/antonbabenko/pre-commit-terraform.
[INFO] Installing environment for https://github.com/pre-commit/pre-commit-hooks.
[INFO] Once installed this environment will be reused.
[INFO] This may take a few minutes...
trim trailing whitespace.................................................Failed
- hook id: trailing-whitespace
- exit code: 1
- files were modified by this hook

Fixing aws/basic/logs/aws_configure.log
Fixing aws/single_instance/modules/cache/elasticache.tf
Fixing aws/tfstate/logs/terraform_validate.log
Fixing aws/single_instance/modules/compute/ecs_fargate.tf
Fixing aws/tfstate/logs/aws_configure.log
Fixing aws/single_instance/tfsec_current.txt
Fixing aws/single_instance/modules/identity/iam_ec2.tf
Fixing aws/tfstate/docs/README.state_backup.txt
Fixing aws/tfstate/logs/terraform_init.log
Fixing aws/single_instance/modules/networking/outputs.tf
Fixing aws/single_instance/modules/identity/iam.tf
Fixing aws/single_instance/modules/storage/s3_dev_bucket.tf
Fixing aws/tfstate/docs/README.state_confirmation.txt
Fixing README.AWS.md
Fixing aws/tfstate/logs/terraform_apply.log
Fixing aws/tfstate/docs/README.state_backup_policy.txt
Fixing aws/tfstate/create_s3_bucket.tf
Fixing aws/tfstate/logs/terraform_state.log
Fixing aws/tfstate/README.md
Fixing aws/single_instance/README.AWS_SSM.txt
Fixing aws/single_instance/modules/vpc/vpc.tf
Fixing aws/single_instance/checkov_current.txt
Fixing aws/single_instance/modules/storage/s3_log_bucket.tf
Fixing aws/single_instance/modules/identity/variables.tf
Fixing aws/single_instance/modules/compute/ec2.tf

fix end of files.........................................................Failed
- hook id: end-of-file-fixer
- exit code: 1
- files were modified by this hook

Fixing aws/single_instance/modules/cache/variables.tf
Fixing aws/basic/logs/aws_configure.log
Fixing aws/single_instance/modules/cache/elasticache.tf
Fixing aws/tfstate/logs/terraform_validate.log
Fixing aws/tfstate/logs/aws_configure.log
Fixing aws/single_instance/tfsec_current.txt
Fixing aws/single_instance/modules/identity/iam_ec2.tf
Fixing aws/tfstate/variables.tf
Fixing aws/tfstate/logs/terraform_init.log
Fixing aws/tfstate/docs/README.state_confirmation.txt
Fixing aws/tfstate/terraform.tfvars
Fixing README.AWS.md
Fixing aws/tfstate/logs/aws_s3_bucket_confirmation.log
Fixing aws/tfstate/logs/terraform_apply.log
Fixing aws/tfstate/logs/terraform_show.log
Fixing aws/tfstate/logs/terraform_plan.log
Fixing aws/single_instance/modules/messages/outputs.tf
Fixing aws/tfstate/logs/terraform_state.log
Fixing aws/tfstate/README.md
Fixing aws/single_instance/variables.tf
Fixing aws/single_instance/checkov_current.txt
Fixing aws/single_instance/modules/networking/variables.tf

check for added large files..............................................Passed
check for merge conflicts................................................Passed
don't commit to branch...................................................Passed
detect aws credentials...................................................Passed
detect private key.......................................................Passed
Terraform fmt............................................................Failed
- hook id: terraform_fmt
- files were modified by this hook

vpc.tf
iam.tf
iam_ec2.tf
security_group.tf
sns.tf
s3_dev_bucket.tf
s3_log_bucket.tf
ec2.tf
ecs_fargate.tf
kms.tf
outputs.tf
create_s3_bucket.tf

Generate tf documents for modules....................(no files to check)Skipped
Generate tf documents for environments...............(no files to check)Skipped
Terraform validate...................................(no files to check)Skipped
Terraform validate with tflint...........................................Failed
- hook id: terraform_tflint
- exit code: 2

Command 'tflint --init' successfully done:
All plugins are already installed



TFLint in aws/single_instance/modules/cache/:
3 issue(s) found:

Warning: Missing version constraint for provider "aws" in `required_providers` (terraform_required_providers)

  on elasticache.tf line 10:
  10: resource "aws_elasticache_cluster" "example" {

Reference: https://github.com/terraform-linters/tflint-ruleset-terraform/blob/v0.10.0/docs/rules/terraform_required_providers.md

Warning: terraform "required_version" attribute is required (terraform_required_version)

  on terraform.tf line 0:
   (source code not available)

Reference: https://github.com/terraform-linters/tflint-ruleset-terraform/blob/v0.10.0/docs/rules/terraform_required_version.md

Warning: [Fixable] variable "vpc_subnet_public_id" is declared but not used (terraform_unused_declarations)

tim@Tims-MBP single_instance % grep trivy:ignore modules/identity/iam.tf
#trivy:ignore:AVD-AWS-0123
#trivy:ignore:AVD-AWS-0342
tim@Tims-MBP single_instance % pre-commit run -a > commit.txt
tim@Tims-MBP single_instance % grep -A 10 AVD-AWS-0342 commit.txt
tim@Tims-MBP single_instance % grep -A 10 avd-aws-0342 commit.txt
tim@Tims-MBP single_instance % wc -l commit.txt
     821 commit.txt
