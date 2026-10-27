#!/bin/bash

export KUBECONFIG=~/.kube/kind-datastore-dev

kubectl --kubeconfig ~/.kube/kind-datastore-dev --context kind-datastore-dev \
  -n monitoring get secret kube-prometheus-stack-grafana \
  -o jsonpath='{.data.admin-password}' | base64 -d | pbcopy

echo "Copied to Mac Clipboard"

kubectl --kubeconfig ~/.kube/kind-datastore-dev --context kind-datastore-dev \
  -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
