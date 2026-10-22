# Using kubectl with the single_instance EKS clusters

Each environment has one EKS cluster. Its API endpoint is public but accepts
connections only from `my_laptop_cidr_block` in that environment's
`terraform.tfvars`; worker nodes reach it privately inside the VPC.

| Env | Region | kubectl context |
|---|---|---|
| dev | us-east-2 | `eks-multi` (dev tfvars sets `env = "multi"`) |
| prod | us-east-2 | `eks-prod` |

Both are in account `650836812595`. On your laptop, `export AWS_PROFILE=blue-elephant`
first (the scripts and `kubeconfig_command` set it for you).

## Who can use the cluster

- The IAM identity that ran `terraform apply` (user `blue-elephant`) is a
  cluster admin; EKS grants this when it creates the cluster. It does not
  appear in the `aws-auth` ConfigMap.
- dev only: role `EC2Role` (the EC2 instances' profile) is mapped to
  `system:masters` as `ec2-admin`, so the public EC2 host can run kubectl.
- dev only: users `sre` (namespace `app1`) and `dba` (`app2`) have RBAC
  roles, but no IAM identity is mapped to them; test them with `--as`.

## From your laptop

Prerequisites: `brew install awscli kubectl` (Apple silicon builds), and
`aws sts get-caller-identity` shows `user/blue-elephant`.

1. Check your public IP still matches `my_laptop_cidr_block`:

   ```sh
   curl -4 ifconfig.me
   ```

   If it changed, update `terraform.tfvars` and re-run `terraform apply`. The
   cluster is updated in place, which takes a few minutes; the SSH security
   group rules use the same value.

2. Add the cluster to `~/.kube/config` (run in `environments/dev` or `environments/prod`):

   ```sh
   eval "$(terraform output -raw kubeconfig_command)"
   ```

   This runs `aws eks update-kubeconfig --region <region> --name eks-<env>-<suffix> --alias eks-<env>`
   and switches to that context.

3. Use it:

   ```sh
   kubectl config use-context eks-multi   # dev; eks-prod for prod
   kubectl get nodes -o wide
   kubectl get pods -A
   ```

### Things to try in dev

```sh
kubectl -n app1 get deploy,svc,pods        # heartbeat
kubectl -n app2 get deploy,svc,pods        # monitor
kubectl -n app1 describe resourcequota
kubectl -n kube-system get deploy aws-load-balancer-controller
kubectl get ingress -A

# RBAC: sre may manage pods in app1 but not app2
kubectl auth can-i create pods -n app1 --as sre    # yes
kubectl auth can-i create pods -n app2 --as sre    # no
kubectl auth can-i list pods   -n app2 --as dba    # yes
```

The Python scripts in `environments/dev/eks/` (`test_rbac.py`,
`monitor_heartbeat.py`, ...) use the current kubectl context.

## From the public EC2 host (dev)

The host already has `aws`, `kubectl` and the Python Kubernetes client. Its
`EC2Role` credentials are mapped to cluster admin in dev.

```sh
IP=$(aws ec2 describe-instances --region us-east-2 \
  --filters Name=instance-state-name,Values=running \
  --query 'Reservations[].Instances[?PublicIpAddress].PublicIpAddress' --output text)
ssh -i ~/.ssh/aws_ssh ubuntu@$IP

# on the host
aws eks update-kubeconfig --region us-east-2 --name <cluster name> --alias eks-multi
kubectl get nodes
```

Get the cluster name from `terraform output -raw eks_cluster_name`. Prod does
not map `EC2Role`, so in prod use your laptop.

## Shortcuts

Two scripts in `aws/scripts` do the steps in this file for you. Run them
from anywhere:

```sh
aws/scripts/kube_use.sh dev|prod                    # point kubectl at the cluster, show nodes and pods
aws/scripts/ssh_ec2.sh  dev|prod [public|private]   # SSH in; private hops through public
```

They read the cluster name and instance IPs from Terraform, so they keep
working after a rebuild changes them.

## Reaching the EC2 instances

The private key stays on your laptop. Nothing copies it onto an instance (the
public instance's user data used to, until 2026-10-16). To reach the private
instance, SSH hops through the public one with `-J` (ProxyJump):

```sh
ssh-add ~/.ssh/aws_ssh                   # dev and prod
PUB=<public instance IP>
PRIV=<private instance IP, 10.1.4.x in dev>
ssh -J ubuntu@$PUB ubuntu@$PRIV
```

Find both IPs:

```sh
aws ec2 describe-instances --region us-east-2 \
  --filters Name=instance-state-name,Values=running Name=tag:Name,Values=ubuntu-24.04 \
  --query 'Reservations[].Instances[].[PrivateIpAddress,PublicIpAddress]' --output text
```

To skip typing `-J`, add this to `~/.ssh/config`:

```
Host si-public
  HostName <public IP>
  User ubuntu
  IdentityFile ~/.ssh/aws_ssh
Host si-private
  HostName <private IP>
  User ubuntu
  IdentityFile ~/.ssh/aws_ssh
  ProxyJump si-public
```

Then `ssh si-private`. The public instance's IP changes whenever it's
re-created.

## Capacity: t3.micro nodes

With the VPC CNI, a `t3.micro` node holds at most 4 pods, and 2 of them are
always `aws-node` and `kube-proxy`. That leaves 2 pods per node:

| Env | Nodes | Free pod slots | Already used |
|---|---|---|---|
| dev | 4 (max 5) | 8 | coredns 2, heartbeat 2, monitor 2, ALB controller 2 |
| prod | 3 (max 4) | 6 | coredns 2 |

Dev is full once it's deployed. A pod stuck in `Pending` with
`Too many pods` means there's no free slot: raise `eks_node_desired_size` /
`eks_node_max_size` or `eks_node_instance_type` (`t3.small` = 11 pods).

## Troubleshooting

| Symptom | Cause |
|---|---|
| `dial tcp ...:443: i/o timeout` | Your IP is not in `my_laptop_cidr_block` (step 1) |
| `the server has asked for the client to provide credentials` | Wrong AWS identity; check `aws sts get-caller-identity` |
| `exec plugin: invalid apiVersion` | Old kubectl or awscli; `brew upgrade awscli kubectl` |
| Pods `Pending`, `Too many pods` | See "Capacity" above |
