#!/usr/bin/env python3

from kubernetes import client, config

clusters = ["eks-dev1-j4gvw8ee", "eks-dev2-j4gvw8ee", "eks-dev3-j4gvw8ee"]
for cluster in clusters:
    config.load_kube_config(context=f"arn:aws:eks:us-west-2:084375569056:cluster/{cluster}")
    v1 = client.CoreV1Api()
    print(f"ConfigMaps in {cluster}/app1:")
    configmaps = v1.list_namespaced_config_map(namespace="app1")
    for cm in configmaps.items:
        print(f"ConfigMap: {cm.metadata.name}, Data: {cm.data}")
    print(f"Secrets in {cluster}/app1:")
    secrets = v1.list_namespaced_secret(namespace="app1")
    for secret in secrets.items:
        print(f"Secret: {secret.metadata.name}")
