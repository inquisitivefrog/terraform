# aws/tfstate

The state layer every other AWS root depends on. Account `650836812595`,
profile `blue-elephant`, region `us-east-2` (see `../../README.AWS.md`).

| Root | Creates | State |
|---|---|---|
| `bootstrap/{dev,prod}` | `blue-elephant-tfstate-admin-{env}` (versioned, encrypted, public access blocked) and `-logs` | local `terraform.tfstate` |
| `environments/{dev,prod}` | KMS key + `alias/tfstate-{env}`, used by `single_instance/environments/{env}/backend.hcl` | the bootstrap bucket, key `terraform.tfstate` |

## Build (per env)

```sh
cd aws/tfstate/bootstrap/dev        # then prod
terraform init
terraform plan -out bootstrap-dev && terraform apply bootstrap-dev

cd ../../environments/dev           # then prod
terraform init -reconfigure -backend-config=backend.hcl
terraform plan -out bucket-dev && terraform apply bucket-dev

../../../scripts/check_resources.sh dev
```

## Tear down

Destroy `single_instance` first (prod, then dev). Then either run
`aws/scripts/aws_wipe.sh`, which does the rest in order and empties the
versioned buckets, or by hand per env:

1. Delete `single_instance/terraform.tfstate` from the bootstrap bucket (it
   is encrypted with the state CMK; once the CMK is gone it can't be read).
2. `environments/<env>`: `terraform plan -destroy -out d && terraform apply d`.
3. Empty the versioned buckets (`force_destroy = false`), then destroy
   `bootstrap/<env>` the same way.

Full table and the reasons for each step: `../README.aws.md`, "Build and
tear-down order". History: `docs/STATUS.md`.
