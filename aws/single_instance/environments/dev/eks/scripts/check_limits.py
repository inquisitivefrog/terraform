#!/usr/bin/env python3

from kubernetes import client, config

clusters = ["eks-dev1-j4gvw8ee", "eks-dev2-j4gvw8ee", "eks-dev3-j4gvw8ee"]
for cluster in clusters:
    config.load_kube_config(context=f"arn:aws:eks:us-west-2:084375569056:cluster/{cluster}")
    v1 = client.CoreV1Api()
    print(f"Pods in {cluster}/app1:")
    pods = v1.list_namespaced_pod(namespace="app1", label_selector="app=heartbeat")
    for pod in pods.items:
        for container in pod.spec.containers:
            print(f"Pod: {pod.metadata.name}, Container: {container.name}")
            if container.resources.limits:
                print(f"Limits: CPU={container.resources.limits['cpu']}, Memory={container.resources.limits['memory']}")
            if container.resources.requests:
                print(f"Requests: CPU={container.resources.requests['cpu']}, Memory={container.resources.requests['memory']}")
