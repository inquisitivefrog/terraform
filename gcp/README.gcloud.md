# gcloud commands used in this repo

The gcloud commands used to set up and check `gcp/tfstate` and
`gcp/single_instance`, grouped by service. The examples use:

```sh
P=bluedragon-sre-vuft1e   # this repo's project
Z=us-west1-a              # dev zone (prod: us-west2-a)
```

Names follow `<thing>-<env>` (`public-vm-prod`, `redis-dev`, `vpc-main-prod`);
the GKE cluster, key ring and buckets also carry a random suffix
(`terraform output gke_cluster_name`).

Don't change the gcloud default project: it's `project-4c5a8821-da4c-4c68-97f`,
which runs the dairyfarm and grid-meter demos used for interviews. Pass
`--project $P` instead.

Tips:

- `--format=…` shapes the output of any command: `value(field)`,
  `table(a,b)`, `json`, `yaml`.
- `--filter=…` narrows lists, e.g. `--filter='network~vpc-main-dev'`.
- `gcloud help <command>` shows the manual, e.g. `gcloud help compute ssh`.
- `--quiet` answers prompts with their defaults, for use in scripts.

## Helper scripts (`gcp/scripts/`)

All read Terraform outputs for the project and zone, and pass `--project`
explicitly. Run from anywhere.

| Script | What it does |
|---|---|
| `check_resources.sh dev\|prod` | Confirms every single_instance resource exists and is healthy via the GCP APIs (45 checks on dev, including Kubernetes, RBAC and the ingress; 38 on prod). Exit 1 on any failure |
| `estimate_costs.sh dev\|prod\|all` | List-price estimate of what's running now. Not billing data; excludes usage-based charges |
| `kube_use.sh dev\|prod` | Points kubectl at the GKE cluster using `~/.kube/gcp-<env>` |
| `ssh_vm.sh dev\|prod [public\|private]` | SSH through IAP; private through public (see SSH below) |

## Accounts and configuration

| Command | What it does |
|---|---|
| `gcloud config list` | Shows the active account and default project |
| `gcloud auth login` | Signs the gcloud CLI in as you |
| `gcloud auth application-default login` | Saves credentials for Terraform and other client libraries (ADC) |
| `gcloud projects list` | Lists the projects you can see |
| `gcloud organizations list` | Shows your organization and its ID |

ADC's "quota project" is the gcloud default project (dairyfarm). The Terraform
providers here set `billing_project` and `user_project_override` so API quota
is charged to `$P` instead.

## Projects, billing and APIs

| Command | What it does |
|---|---|
| `gcloud projects create $P --name="bluedragon sre" --organization=986782208561` | Creates a project |
| `gcloud billing projects link $P --billing-account=011D61-08EF93-5C70B6` | Links billing (nothing can be created without it) |
| `gcloud billing projects describe $P` | Shows whether billing is on |
| `gcloud billing projects list --billing-account=011D61-08EF93-5C70B6` | Lists projects on a billing account (`estimate_costs.sh` uses it to see who else might take the free GKE credit) |
| `gcloud services enable storage.googleapis.com cloudkms.googleapis.com pubsub.googleapis.com --project $P` | Turns on APIs (each GCP service must be enabled per project) |
| `gcloud services list --enabled --project $P` | Lists the APIs turned on |
| `gcloud projects describe $P --format='value(projectNumber)'` | Gets the project number (used in service agent emails) |

## IAM and policy

| Command | What it does |
|---|---|
| `gcloud projects get-iam-policy $P --format=json` | Shows who has which role (used to find the Pub/Sub service agent) |
| `gcloud resource-manager org-policies describe iam.allowedPolicyMemberDomains --project $P --effective` | Checks an organization policy limit; also `gcp.resourceLocations` |
| `gcloud iam service-accounts list --project $P` | Lists service accounts (`vm-<env>`, `gke-node-<env>`, `admin-<env>`, ...) |
| `gcloud iam service-accounts describe vm-prod@$P.iam.gserviceaccount.com --project $P` | Shows one service account |

## Cloud Storage

| Command | What it does |
|---|---|
| `gcloud storage ls --project $P` | Lists buckets |
| `gcloud storage ls -r gs://bluedragon-tfstate-admin-dev` | Lists objects (state lives under `tfstate/` and `single_instance/`) |
| `gcloud storage buckets describe gs://BUCKET` | Shows bucket settings, including its default KMS key |
| `gcloud storage buckets notifications list gs://BUCKET` | Shows the bucket's Pub/Sub notifications |
| `echo test \| gcloud storage cp - gs://BUCKET/verify/test.txt` | Uploads from stdin |
| `gcloud storage rm --all-versions "gs://BUCKET/verify/**"` | Deletes objects, including old versions (versioned buckets keep them otherwise) |

## Pub/Sub

| Command | What it does |
|---|---|
| `gcloud pubsub topics list --project $P` | Lists topics and their KMS keys |
| `gcloud pubsub subscriptions create S --topic T --project $P` | Creates a subscription |
| `gcloud pubsub subscriptions pull S --auto-ack --limit 5 --project $P` | Reads messages (used to test bucket notifications) |
| `gcloud pubsub subscriptions delete S --project $P` | Deletes a subscription |

## Compute Engine

| Command | What it does |
|---|---|
| `gcloud compute instances list --project $P` | Lists VMs |
| `gcloud compute images describe-from-family ubuntu-2404-lts-amd64 --project ubuntu-os-cloud` | Shows the newest Ubuntu 24.04 image |
| `gcloud compute instances describe public-vm-dev --zone $Z --project $P` | Shows a VM's tags, status and IP |
| `gcloud compute instances get-serial-port-output public-vm-dev --zone $Z --project $P` | Shows the boot and startup-script log, without SSH |
| `gcloud compute firewall-rules list --project $P --filter='network~vpc-main-dev'` | Lists firewall rules |
| `gcloud compute os-login describe-profile` | Shows your OS Login username |
| `gcloud compute disks list --project $P` | Lists disks (VM and GKE node boot disks) |
| `gcloud compute networks list --project $P` | Lists VPCs |
| `gcloud compute networks subnets describe private-prod --region us-west2 --project $P` | Shows a subnet, its secondary ranges and flow-log setting |
| `gcloud compute routers nats describe nat-prod --router router-prod --region us-west2 --project $P` | Shows Cloud NAT |
| `gcloud compute addresses list --project $P` | Lists reserved IPs, including Cloud Run's `serverless-ipv4-*` |
| `gcloud compute forwarding-rules list --project $P --global` | Lists load balancer frontends (GKE ingress makes `k8s2-fr-*`) |
| `gcloud compute network-endpoint-groups list --project $P` | Lists NEGs (GKE ingress backends) |

## Memorystore, Cloud Run and KMS

| Command | What it does |
|---|---|
| `gcloud redis instances list --region us-west2 --project $P` | Lists Redis instances |
| `gcloud redis instances describe redis-prod --region us-west2 --project $P --format='value(state,authEnabled,transitEncryptionMode,port)'` | Shows state, AUTH, TLS and port (6378 with TLS) |
| `gcloud redis instances get-auth-string redis-prod --region us-west2 --project $P` | Prints the Redis password (or `terraform output -raw redis_auth_string`) |
| `gcloud run services list --project $P` | Lists Cloud Run services |
| `gcloud run services describe nginx-prod --region us-west2 --project $P` | Shows a service, its ingress setting and readiness |
| `gcloud kms keyrings list --location us-west2 --project $P` | Lists key rings (destroyed ones stay listed forever) |
| `gcloud kms keys list --keyring single-instance-prod-<suffix> --location us-west2 --project $P` | Lists keys in a ring |
| `gcloud kms keys versions list --key gke-secrets-key --keyring … --location us-west2 --project $P` | Lists key versions and their state (billed per enabled version) |

## SSH

Easiest: `gcp/scripts/ssh_vm.sh prod` (public VM) or
`gcp/scripts/ssh_vm.sh prod private`. The commands below are what it runs.

Private Internet Access (the VPN on this Mac) drops port 22 to GCP, so SSH
goes through Identity-Aware Proxy (IAP), which carries it over HTTPS. The
firewall lets IAP (`35.235.240.0/20`) reach port 22 on the public VM only.
You log in with OS Login as your Google identity; no key is stored on the
VMs. The first `gcloud compute ssh` creates `~/.ssh/google_compute_engine`
and registers it with OS Login, so run the public form once on a new laptop.

| Command | What it does |
|---|---|
| `gcloud compute ssh public-vm-dev --zone $Z --project $P --tunnel-through-iap` | SSHes to the public VM through IAP |
| `gcloud compute ssh public-vm-dev … --command 'hostname'` | Runs one command over SSH |
| `gcloud compute start-iap-tunnel public-vm-dev 22 --listen-on-stdin --zone $Z --project $P` | Opens a raw IAP tunnel, for use as an SSH `ProxyCommand` |

The private VM has no public IP and only accepts SSH from the public subnet,
so hop through the public VM:

```sh
U=$(gcloud compute os-login describe-profile --format='value(posixAccounts[0].username)')
K=~/.ssh/google_compute_engine   # key gcloud compute ssh created
OUTER="gcloud compute start-iap-tunnel public-vm-dev 22 --listen-on-stdin --zone $Z --project $P"
ssh -i $K -o ProxyCommand="ssh -i $K -o ProxyCommand='$OUTER' -W %h:%p $U@public-vm-dev" \
  $U@$(terraform output -raw private_vm_ip)
```

## GKE

| Command | What it does |
|---|---|
| `gcloud container get-server-config --zone $Z --project $P` | Shows the GKE versions available |
| `gcloud container clusters list --project $P` | Lists clusters and their status |
| `gcloud container clusters describe gke-prod-<suffix> --zone us-west2-a --project $P` | Shows version, encryption, private-node and authorized-network settings |
| `gcloud container node-pools describe np-prod-<suffix> --cluster gke-prod-<suffix> --zone us-west2-a --project $P` | Shows the node pool |
| `gcloud container clusters get-credentials gke-dev-<suffix> --zone $Z --project $P` | Writes a kubeconfig entry for kubectl (`terraform output kubeconfig_command`) |
| `gcloud container clusters get-credentials … --internal-ip` | Same, through the private endpoint (from the public VM) |

GKE matches a Google identity to RBAC by email only if its token carries the
`userinfo.email` scope; otherwise it sees a numeric ID. The VMs have that
scope. If kubectl on a VM reports a numeric user, delete the auth plugin's
cache: `rm ~/.kube/gke_gcloud_auth_plugin_cache`.

`get-credentials` also switches kubectl's current context. To keep
`~/.kube/config` (and the grid-meter context) untouched, point `KUBECONFIG`
at a separate file first:

```sh
export KUBECONFIG=~/.kube/gcp-dev
$(terraform output -raw kubeconfig_command)
kubectl get nodes
```

`gcp/scripts/kube_use.sh dev|prod` does this for you.

## Teardown

Two things GCP cleans up on its own schedule, which can block
`terraform destroy`:

1. **GKE ingress (dev):** the ingress controller creates a load balancer,
   NEGs and `k8s-*` firewall rules outside Terraform. Destroy the Kubernetes
   layer first and wait for them to go before destroying the rest:

   ```sh
   terraform destroy -target=module.kubernetes
   gcloud compute forwarding-rules list --project $P --global      # until empty
   gcloud compute network-endpoint-groups list --project $P        # until empty
   terraform destroy
   ```

2. **Cloud Run's serverless IP:** the private subnet keeps a
   `serverless-ipv4-cloudrun-*` address for 1-2 hours after the service is
   deleted, so the first destroy fails on the subnet. When this is empty, run
   `terraform destroy` again:

   ```sh
   gcloud compute addresses list --project $P --filter=purpose=SERVERLESS
   ```
