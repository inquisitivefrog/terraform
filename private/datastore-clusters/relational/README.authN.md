kubectl --context kind-datastore-dev -n monitoring get secret kube-prometheus-stack-grafana -o jsonpath='{.data.admin-password}' | base64 -d | pbcopy
