
ecommerce-k8s/
├── main.tf
├── variables.tf
├── outputs.tf
├── kubernetes/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml

Commands
1. terraform init
2. terraform plan -out=tfplan
3. terraform apply tfplan
4. aws eks update-kubeconfig --region us-east-1 --name ecommerce-cluster
5. kubectl apply -f kubernetes/deployment.yaml
6. kubectl apply -f kubernetes/service.yaml
7. kubectl apply -f kubernetes/ingress.yaml
8. kubectl get ingress ecommerce-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
9. terraform destroy --auto-approve
