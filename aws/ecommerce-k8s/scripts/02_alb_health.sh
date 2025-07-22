#!/bin/bash

echo aws elbv2 describe-target-groups --names k8s-default-sampleap-3cd7b2bb4d
aws elbv2 describe-target-groups --names k8s-default-sampleap-3cd7b2bb4d
echo aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:us-east-1:084375569056:targetgroup/k8s-default-sampleap-3cd7b2bb4d/02b72e2affc9569c
aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:us-east-1:084375569056:targetgroup/k8s-default-sampleap-3cd7b2bb4d/02b72e2affc9569c
echo curl http://k8s-default-sampleap-e38fe595da-1841585334.us-east-1.elb.amazonaws.com/
curl http://k8s-default-sampleap-e38fe595da-1841585334.us-east-1.elb.amazonaws.com/
