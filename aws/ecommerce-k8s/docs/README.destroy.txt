
 1001  cd Documents/workspace/sre/terraform/aws/ecommerce-k8s/stage2-k8s
 1002  kubectl describe ingress sample-app -n default
 1003  kubectl get serviceaccount aws-load-balancer-controller -n kube-system -o yaml
 1004  aws eks describe-cluster --name ecommerce-cluster --region us-east-1 --query 'cluster.identity.oidc.issuer'
 1005  kubectl logs aws-load-balancer-controller-84bc5796b5-h5dsh -n kube-system
 1006  kubectl get ingress sample-app -n default -o yaml
 1007  kubectl delete ingress sample-app -n default --grace-period=0 --force
 1008  kubectl get ingress -n default
 1009  kubectl delete ingress sample-app -n default --grace-period=0 --force
 1010  kubectl delete ingress sample-app -n default --grace-period=0 --force
 1011  kubectl get ingress -n default
 1012  kubectl logs aws-load-balancer-controller-84bc5796b5-h5dsh -n kube-system
 1013  aws eks describe-cluster --name ecommerce-cluster --region us-east-1 --query 'cluster.identity.oidc.issuer'
 1014  kubectl delete ingress sample-app -n default --grace-period=0 --force
 1015  clear
 1016  kubectl get ingress sample-app -n default -o yaml
 1017  kubectl delete ingress sample-app -n default --grace-period=0 --force
 1018  aws iam get-role --role-name ecommerce-cluster-alb-controller --query 'Role.AssumeRolePolicyDocument' --output json
 1019  aws iam list-open-id-connect-providers --query 'OpenIDConnectProviderList[*].Arn' --output text
 1020  kubectl delete pod -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
 1021  kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
 1022  kubectl logs -n kube-system aws-load-balancer-controller-84bc5796b5-5j9vm 
 1023  aws iam get-policy --policy-arn arn:aws:iam::084375569056:policy/ecommerce-cluster-AWSLoadBalancerControllerPolicy --query 'Policy.DefaultVersionId' --output text
 1024  aws iam get-policy-version --policy-arn arn:aws:iam::084375569056:policy/ecommerce-cluster-AWSLoadBalancerControllerPolicy --version-id <version-id> --query 'PolicyVersion.Document' --output json
 1025  aws iam get-policy-version --policy-arn arn:aws:iam::084375569056:policy/ecommerce-cluster-AWSLoadBalancerControllerPolicy --version-id v1 --query 'PolicyVersion.Document' --output json
 1026  helm uninstall aws-load-balancer-controller -n kube-system
 1027  kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
 1028  kubectl delete serviceaccount aws-load-balancer-controller -n kube-system
 1029  terraform destroy -var-file=terraform.tfvars -auto-approve
 1030  terraform state list
 1031  cd ../stage1-infra
 1032  terraform destroy -var-file=terraform.tfvars -auto-approve
 1033  terraform destroy -auto-approve
 1034  terraform state list
 1035  history
 1042  kubectl get ingress -n default
 1043  kubectl get ingress sample-app -n default -o yaml
 1044  kubectl get deployment,service,ingress -n default
 1045  kubectl get pods,sa,deployments -n kube-system
 1046  aws eks list-clusters --region us-east-1 --profile terraform-admin
 1047  aws ec2 describe-vpcs --region us-east-1
 1048  aws s3 ls
 1049  aws dynamodb list-tables --region us-east-1 --profile default
 1050  aws iam list-roles --query 'Roles[?RoleName==`terraform-admin` || RoleName==`ecommerce-cluster-alb-controller`]'
 1051  aws ec2 describe-network-interfaces --region us-east-1
 1052  aws s3 rb s3://bluedragon-ecommerce-terraform-state --force
 1053  aws dynamodb delete-table --table-name terraform-state-lock --region us-east-1 --profile default
 1054  openssl s_client -connect oidc.eks.us-east-1.amazonaws.com:443 -showcerts < /dev/null | openssl x509 -outform PEM | openssl x509 -fingerprint -noout
 1055  aws eks list-clusters --region us-east-1 --profile terraform-admin
 1056  aws eks list-clusters --region us-east-1
 1057  aws s3 ls
 1058  aws dynamodb describe-table --table-name terraform-state-lock --region us-east-1 --profile default
 1059  cd ..
 1060  clear

