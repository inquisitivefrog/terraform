#!/usr/bin/env python3

from kubernetes import client, config

clusters = ["eks-dev1-j4gvw8ee", "eks-dev2-j4gvw8ee", "eks-dev3-j4gvw8ee"]
for cluster in clusters:
    config.load_kube_config(context=f"arn:aws:eks:us-west-2:084375569056:cluster/{cluster}")
    v1 = client.CoreV1Api()
    print(f"Pods in {cluster}/app1:")
    try:
        for pod in v1.list_namespaced_pod(namespace="app1").items:
            print(pod.metadata.name)
    except Exception as e:
        print(f"Error: {e}")
    print(f"Pods in {cluster}/app2:")
    try:
        for pod in v1.list_namespaced_pod(namespace="app2").items:
            print(pod.metadata.name)
    except Exception as e:
        print(f"Error: {e}")
