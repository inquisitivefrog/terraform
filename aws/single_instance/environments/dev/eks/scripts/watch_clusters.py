#!/usr/bin/env python3

from kubernetes import client, config, watch

# Contexts for both clusters
contexts = ["cluster1-context", "cluster2-context"]  # Adjust context names

for ctx in contexts:
    config.load_kube_config(context=ctx)
    v1 = client.CoreV1Api()
    w = watch.Watch()
    print(f"Watching pods in {ctx}")
    for event in w.stream(v1.list_pod_for_all_namespaces, timeout_seconds=30):
        print(f"Event: {event['type']} Pod: {event['object'].metadata.name}")
    w.stop()
