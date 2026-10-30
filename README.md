# terraform
Configuration Knowledge for Future Reference

Terraform for the same small platform (network, VMs, Kubernetes, cache,
keys, state backend) on AWS, GCP and Azure, plus a no-cost private cloud on a
laptop for designs too big for the free tiers. Everything it creates is demo
data: the value is reproducible code and notes, so each environment is torn
down and rebuilt freely.

## Where to look

| Folder | What's in it | Start with |
|---|---|---|
| [`aws/`](aws/) | The original stack: the state layer (`tfstate/`), `single_instance/` (VPC, EC2, EKS, ECS, ElastiCache, SNS, KMS, IAM; dev and prod) and `ecommerce-k8s/` (a separate EKS project with Helm and Argo CD), plus helper scripts | [aws/README.aws.md](aws/README.aws.md) |
| [`gcp/`](gcp/) | The same design ported to GCP: state bucket and key ring (`tfstate/`) and `single_instance/` (VPC, VMs, GKE, Memorystore) | [gcp/README.gcloud.md](gcp/README.gcloud.md) |
| [`azure/`](azure/) | The same design ported to Azure: state storage (`tfstate/`) and `single_instance/` (VNet, VMs, AKS, Redis, Key Vault) | [azure/README.az.md](azure/README.az.md) |
| [`private/`](private/) | A private cloud on Docker Desktop + kind: HA PostgreSQL and MySQL clusters under operators, an example orders app, k6 load, Prometheus and Grafana, and scripted, logged operations runbooks (failover, zone loss, alerts) | [private/README.md](private/README.md) |
| [`docs/`](docs/) | Repo-wide checks: the pre-commit hook and GitHub Action, and a cheat sheet of the Terraform and security tools | [docs/REPO_CHECKS.md](docs/REPO_CHECKS.md) |
| [`scripts/`](scripts/) | The git hooks the checks use (`git-hooks/pre-commit`) | [docs/REPO_CHECKS.md](docs/REPO_CHECKS.md) |

Each cloud has a rolling record of what changed and what is deployed:
[aws](aws/tfstate/docs/STATUS.md), [gcp](gcp/tfstate/docs/STATUS.md),
[azure](azure/tfstate/docs/STATUS.md), [private](private/docs/STATUS.md).
[NEXT_SESSION.md](NEXT_SESSION.md) says where work stands.

## Repo checks

A pre-commit hook (`scripts/git-hooks/pre-commit`) and a GitHub Action
(`.github/workflows/repo-checks.yml`) block secrets, files that `.gitignore`
excludes, and unformatted Terraform. On a new clone run
`git config core.hooksPath scripts/git-hooks` once.
