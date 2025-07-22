#!/bin/bash

echo kubectl get clusterroles bluedragon-admin bluedragon-impersonator terraform-admin
kubectl get clusterroles bluedragon-admin bluedragon-impersonator terraform-admin
echo kubectl get clusterrolebindings bluedragon-admin-binding bluedragon-impersonator terraform-admin
kubectl get clusterrolebindings bluedragon-admin-binding bluedragon-impersonator terraform-admin
