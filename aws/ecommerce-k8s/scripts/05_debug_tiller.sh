#!/bin/bash

echo kubectl describe serviceaccount -n kube-system tiller
kubectl describe serviceaccount -n kube-system tiller
echo kubectl describe clusterrolebinding tiller
kubectl describe clusterrolebinding tiller
echo kubectl get networkpolicies -n kube-system
kubectl get networkpolicies -n kube-system
echo export TILLER_NAMESPACE=kube-system
export TILLER_NAMESPACE=kube-system
echo helm list --namespace kube-system --debug
helm list --namespace kube-system --debug
echo rm -rf ~/.helm
rm -rf ~/.helm
echo helm init --client-only
helm init --client-only
echo helm list --namespace kube-system --debug
helm list --namespace kube-system --debug
echo kubectl delete pod -n kube-system tiller-deploy-6597dcbbc9-prsd8
kubectl delete pod -n kube-system tiller-deploy-6597dcbbc9-prsd8
echo kubectl get pods -n kube-system | grep tiller
kubectl get pods -n kube-system | grep tiller
echo kubectl get configmaps -n kube-system | grep tiller
kubectl get configmaps -n kube-system | grep tiller
