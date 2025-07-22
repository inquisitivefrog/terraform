#!/bin/bash

echo kubectl get pods -n kube-system | grep tiller
kubectl get pods -n kube-system | grep tiller
echo helm list --namespace kube-system
helm list --namespace kube-system
echo kubectl logs -n kube-system tiller-deploy-6597dcbbc9-prsd8
kubectl logs -n kube-system tiller-deploy-6597dcbbc9-prsd8
echo kubectl describe serviceaccount -n kube-system tiller
kubectl describe serviceaccount -n kube-system tiller
echo kubectl describe clusterrolebinding tiller
kubectl describe clusterrolebinding tiller
echo kubectl get networkpolicies -n kube-system
kubectl get networkpolicies -n kube-system
echo kubectl get configmaps -n kube-system | grep tiller
kubectl get configmaps -n kube-system | grep tiller
