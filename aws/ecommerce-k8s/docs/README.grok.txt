
kubectl get nodes -o wide

kubectl auth can-i list nodes --as=bluedragon --v=6

aws configure

aws eks update-kubeconfig 

aws sts get-caller-identity

aws eks describe-cluster --name ecommerce-cluster --region us-east-1

export AWS_PROFILE=bluedragon
aws eks update-kubeconfig --name ecommerce-cluster --region us-east-1
aws sts get-caller-identity

export AWS_PROFILE=<other-profile>
aws eks update-kubeconfig --name ecommerce-cluster --region us-east-1
kubectl get clusterrolebinding cluster-admin -o yaml

kubectl create clusterrolebinding cluster-admin --clusterrole=cluster-admin --group=system:masters --dry-run=client -o yaml | kubectl apply -f -

export AWS_PROFILE=bluedragon
aws eks update-kubeconfig --name ecommerce-cluster --region us-east-1
kubectl get nodes -o wide

aws eks update-cluster-config --name ecommerce-cluster --region us-east-1 --access-config authenticationMode=CONFIG_MAP

aws eks update-kubeconfig --name ecommerce-cluster --region us-east-1
kubectl get nodes -o wide

aws eks delete-access-entry --cluster-name ecommerce-cluster --principal-arn arn:aws:iam::084375569056:user/bluedragon --region us-east-1
aws eks create-access-entry --cluster-name ecommerce-cluster --principal-arn arn:aws:iam::084375569056:user/bluedragon --username bluedragon --type STANDARD --region us-east-1
aws eks associate-access-policy --cluster-name ecommerce-cluster --principal-arn arn:aws:iam::084375569056:user/bluedragon --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy --access-scope type=cluster --region us-east-1

kubectl get nodes -o wide

curl ifconfig.me

aws eks update-cluster-config --name ecommerce-cluster --region us-east-1 --resources-vpc-config endpointPublicAccess=true,publicAccessCidrs=<your-current-ip>/32

terraform init -backend-config=backend.hcl
terraform validate
terraform plan -out=tfplan
terraform apply tfplan

aws eks describe-access-entry --cluster-name ecommerce-cluster --principal-arn arn:aws:iam::084375569056:user/bluedragon --region us-east-1

kubectl get configmap -n kube-system aws-auth -o yaml

kubectl get clusterrole bluedragon-admin -o yaml
kubectl get clusterrolebinding bluedragon-admin-binding -o yaml

aws eks update-kubeconfig --name ecommerce-cluster --region us-east-1
kubectl get nodes -o wide

kubectl auth can-i list nodes --as=bluedragon --v=6

aws eks describe-cluster --name ecommerce-cluster --region us-east-1

export AWS_PROFILE=bluedragon
aws eks update-kubeconfig --name ecommerce-cluster --region us-east-1

kubectl apply -f cluster_configmap.yaml

aws eks update-cluster-config --name ecommerce-cluster --region us-east-1 --access-config authenticationMode=CONFIG_MAP

aws eks update-kubeconfig --name ecommerce-cluster --region us-east-1
kubectl get nodes -o wide

aws eks delete-access-entry --cluster-name ecommerce-cluster --principal-arn arn:aws:iam::084375569056:user/bluedragon --region us-east-1
aws eks create-access-entry --cluster-name ecommerce-cluster --principal-arn arn:aws:iam::084375569056:user/bluedragon --username bluedragon --type STANDARD --region us-east-1
aws eks associate-access-policy --cluster-name ecommerce-cluster --principal-arn arn:aws:iam::084375569056:user/bluedragon --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy --access-scope type=cluster --region us-east-1

kubectl get nodes -o wide

curl ifconfig.me

aws sts get-caller-identity

aws eks describe-cluster --name ecommerce-cluster --region us-east-1

export AWS_PROFILE=bluedragon
aws eks update-kubeconfig --name ecommerce-cluster --region us-east-1

kubectl apply -f cluster_configmap.yaml

aws eks update-cluster-config --name ecommerce-cluster --region us-east-1 --access-config authenticationMode=CONFIG_MAP

aws eks update-kubeconfig --name ecommerce-cluster --region us-east-1
kubectl get nodes -o wide

kubectl apply -f impersonation-rbac.yaml

aws eks delete-access-entry --cluster-name ecommerce-cluster --principal-arn arn:aws:iam::084375569056:user/bluedragon --region us-east-1
aws eks create-access-entry --cluster-name ecommerce-cluster --principal-arn arn:aws:iam::084375569056:user/bluedragon --username bluedragon --type STANDARD --region us-east-1
aws eks associate-access-policy --cluster-name ecommerce-cluster --principal-arn arn:aws:iam::084375569056:user/bluedragon --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy --access-scope type=cluster --region us-east-1

kubectl get nodes -o wide

curl ifconfig.me

aws eks update-cluster-config --name ecommerce-cluster --region us-east-1 --resources-vpc-config endpointPublicAccess=true,publicAccessCidrs=<your-current-ip>/32

terraform init -backend-config=backend.hcl
terraform validate
terraform plan -out=tfplan
terraform apply tfplan

aws eks describe-access-entry --cluster-name ecommerce-cluster --principal-arn arn:aws:iam::084375569056:user/bluedragon --region us-east-1

kubectl get configmap -n kube-system aws-auth -o yaml

kubectl get clusterrole bluedragon-admin -o yaml
kubectl get clusterrolebinding bluedragon-admin-binding -o yaml

aws eks update-kubeconfig --name ecommerce-cluster --region us-east-1
kubectl get nodes -o wide
kubectl auth can-i list nodes --as=bluedragon --v=6

kubectl auth can-i list nodes --as=bluedragon --v=6

aws eks describe-cluster --name ecommerce-cluster --region us-east-1 --query 'cluster.accessConfig.authenticationMode'

aws configure

kubectl apply -f cluster_configmap.yaml

kubectl create clusterrolebinding cluster-admin --clusterrole=cluster-admin --group=system:masters --dry-run=client -o yaml | kubectl apply -f -

aws eks update-cluster-config --name ecommerce-cluster --region us-east-1 --resources-vpc-config endpointPublicAccess=true,publicAccessCidrs=<your-current-ip>/32

aws eks update-cluster-config --name ecommerce-cluster --region us-east-1 --resources-vpc-config endpointPublicAccess=true,publicAccessCidrs=203.0.113.1/32

aws eks update-kubeconfig --name ecommerce-cluster --region us-east-1
kubectl get nodes -o wide

curl -k https://DA6FBE027FF88220640EA4E8F838702B.gr7.us-east-1.eks.amazonaws.com

kubectl get nodes -o wide
kubectl auth can-i list nodes --as=bluedragon --v=6

aws eks update-cluster-config --name ecommerce-cluster --region us-east-1 --access-config authenticationMode=CONFIG_MAP

aws eks update-kubeconfig --name ecommerce-cluster --region us-east-1
kubectl get nodes -o wide

kubectl apply -f cluster_configmap.yaml

kubectl get configmap -n kube-system aws-auth -o yaml

kubectl apply -f impersonation-rbac.yaml

aws eks delete-access-entry --cluster-name ecommerce-cluster --principal-arn arn:aws:iam::084375569056:user/bluedragon --region us-east-1
aws eks create-access-entry --cluster-name ecommerce-cluster --principal-arn arn:aws:iam::084375569056:user/bluedragon --username bluedragon --type STANDARD --region us-east-1
aws eks associate-access-policy --cluster-name ecommerce-cluster --principal-arn arn:aws:iam::084375569056:user/bluedragon --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy --access-scope type=cluster --region us-east-1
aws eks associate-access-policy --cluster-name ecommerce-cluster --principal-arn arn:aws:iam::084375569056:user/bluedragon --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy --access-scope type=cluster --region us-east-1
aws eks associate-access-policy --cluster-name ecommerce-cluster --principal-arn arn:aws:iam::084375569056:user/bluedragon --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminViewPolicy --access-scope type=cluster --region us-east-1

AWS Console
1. Elastic Kubernetes Service
2. select existing cluster
3. select Access tab
4. create user access
   AmazonEKSAdminPolicy
   AmazonEKSClusterAdminPolicy 
   AmazonEKSAdminViewPolicy

NOTE:
The AmazonEKSAdminPolicy, combined with AmazonEKSClusterAdminPolicy and AmazonEKSAdminViewPolicy, provided sufficient IAM permissions for bluedragon. The system:masters mapping in aws-auth and the custom bluedragon-admin RBAC role ensured Kubernetes admin access. The primary issue was the network restriction (publicAccessCidrs), not missing policies. In rare cases, additional policies like AmazonEKSVPCResourceController or AmazonEC2FullAccess might be needed for specific operations (e.g., managing VPCs or node groups), but your current setup covers most scenarios.

kubectl get pods -A
kubectl get deployments -n kube-system
kubectl get clusterrole bluedragon-admin -o yaml
kubectl get clusterrolebinding bluedragon-admin-binding -o yaml
kubectl auth can-i '*' '*' --as=bluedragon --v=6

kubectl get configmap -n kube-system aws-auth -o yaml

aws eks describe-access-entry --cluster-name ecommerce-cluster --principal-arn arn:aws:iam::084375569056:user/bluedragon --region us-east-1
aws eks list-access-policies --cluster-name ecommerce-cluster --principal-arn arn:aws:iam::084375569056:user/bluedragon --region us-east-1

kubectl create namespace test
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
  namespace: test
spec:
  containers:
  - name: nginx
    image: nginx
EOF
kubectl get pods -n test

export AWS_PROFILE=terraform-role
terraform apply

kubectl get configmap -n kube-system aws-auth -o yaml > aws-auth-backup.yaml

aws elbv2 describe-load-balancers --region us-east-1
aws elbv2 delete-load-balancer --load-balancer-arn <alb-arn> --region us-east-1
aws ec2 describe-network-interfaces --region us-east-1
kubectl get pods -A
kubectl delete pod --all -A --force

terraform state rm module.eks.module.eks.module.eks_managed_node_group["default"].aws_eks_node_group.this[0]
aws eks delete-nodegroup --cluster-name ecommerce-cluster --nodegroup-name default --region us-east-1
terraform state rm module.vpc.module.vpc.aws_nat_gateway.this[0]
aws ec2 delete-nat-gateway --nat-gateway-id nat-0069d51e4ba6622ad --region us-east-1

aws eks describe-cluster --name ecommerce-cluster --region us-east-1
aws ec2 describe-vpcs --region us-east-1
aws ec2 describe-subnets --region us-east-1
aws s3 ls s3://blued-ecommerce-app-us-east-1-prod
aws s3 rm s3://blued-ecommerce-app-us-east-1-prod --recursive
aws s3api delete-bucket --bucket blued-ecommerce-app-us-east-1-prod --region us-east-1
aws iam list-roles --region us-east-1
aws iam list-policies --scope Local --region us-east-1
aws iam delete-role --role-name ecommerce-cluster-alb-controller
aws iam delete-policy --policy-arn arn:aws:iam::084375569056:policy/ecommerce-cluster-EKSNodeGroupELBPolicy

rm -rf .terraform terraform.tfstate terraform.tfstate.backup

aws eks list-nodegroups --cluster-name ecommerce-cluster --region us-east-1
aws ec2 describe-internet-gateways --region us-east-1
aws ec2 describe-nat-gateways --region us-east-1

aws --version
aws eks get-token --cluster-name ecommerce-cluster --region us-east-1
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /

