#!/bin/bash

terraform state list
kubectl get pods -n default -l app=sample-app -o wide
kubectl get replicasets -n default -l app=sample-app
kubectl describe deployment -n default sample-app
kubectl describe pod -n default -l app=sample-app
kubectl logs -n default -l app=sample-app
kubectl get services -n default -l app=sample-app
kubectl describe service sample-app -n default
curl http://k8s-default-sampleap-e38fe595da-1841585334.us-east-1.elb.amazonaws.com/
kubectl get clusterroles bluedragon-admin bluedragon_impersonator terraform-admin
kubectl get clusterrolebindings bluedragon-admin-binding bluedragon-impersonator terraform-admin
kubectl get pods -n kube-system | grep tiller
helm list --namespace kube-system
aws elbv2 describe-target-groups --names k8s-default-sampleap-3cd7b2bb4d
aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:us-east-1:084375569056:targetgroup/k8s-default-sampleap-3cd7b2bb4d/02b72e2affc9569c
kubectl logs -n kube-system tiller-deploy-<new-pod-name>
kubectl describe serviceaccount -n kube-system tiller
kubectl describe clusterrolebinding tiller
kubectl get networkpolicies -n kube-system
kubectl get configmaps -n kube-system | grep tiller
