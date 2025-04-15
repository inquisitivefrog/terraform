export KUBECONFIG=~/.kube/config:cluster2_kubeconfig
kubectl config view --flatten > ~/.kube/config_merged
mv ~/.kube/config_merged ~/.kube/config
