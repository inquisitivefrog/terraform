#!/bin/bash

echo kubectl get pods -n default -l app=sample-app -o wide
kubectl get pods -n default -l app=sample-app -o wide
echo kubectl get replicasets -n default -l app=sample-app
kubectl get replicasets -n default -l app=sample-app
echo kubectl describe deployment -n default sample-app
kubectl describe deployment -n default sample-app
echo kubectl describe pod -n default -l app=sample-app
kubectl describe pod -n default -l app=sample-app
echo kubectl logs -n default -l app=sample-app
kubectl logs -n default -l app=sample-app
echo kubectl get services -n default -l app=sample-app
kubectl get services -n default -l app=sample-app
echo kubectl describe service sample-app -n default
kubectl describe service sample-app -n default
