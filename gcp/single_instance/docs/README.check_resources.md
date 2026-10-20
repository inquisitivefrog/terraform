
tim@Timothys-MacBook-Air terraform % gcp/scripts/check_resources.sh prod
== gcp/single_instance prod (project bluedragon-sre-vuft1e, zone us-west2-a, suffix c3pfltlz) ==

-- State --
  PASS  State object: gs://bluedragon-tfstate-admin-prod/single_instance/default.tfstate

-- Networking --
  PASS  VPC: vpc-main-prod
  PASS  Public subnet: 10.0.3.0/24
  PASS  Private subnet: 10.0.4.0/24
  PASS  Flow logs on private subnet: True
  PASS  Cloud NAT: nat-prod
  PASS  Firewall rules (ours, excl. GKE's): 11

-- Compute --
  PASS  Public VM: RUNNING
  PASS  Public VM external IP: 34.94.48.78
  PASS  Private VM: RUNNING
  PASS  Private VM has no external IP: 
  PASS  Cloud Run nginx ready: True
  PASS  Cloud Run ingress: internal

-- GKE --
  PASS  Cluster: RUNNING
  PASS  Cluster version: 1.36.4-gke.1495002
  PASS  Secrets encryption key: gke-secrets-key
  PASS  Private nodes: True
  PASS  Node pool: RUNNING
  PASS  Nodes RUNNING (autoscaler 1-3): 2

-- Memorystore --
  PASS  Redis: READY
  PASS  Redis AUTH: True
  PASS  Redis TLS: SERVER_AUTHENTICATION

-- KMS (key ring single-instance-prod-c3pfltlz) --
  PASS  gke-secrets-key enabled versions: 1
  PASS  messages-key enabled versions: 1
  PASS  symmetric-key enabled versions: 1
  PASS  asymmetric-key enabled versions: 1

-- Pub/Sub and Storage --
  PASS  Topic example-topic-prod: messages-key
  PASS  Topic custom-topic-prod: messages-key
  PASS  Ordered subscription: True
  PASS  Dev bucket (CMEK): messages-key
  PASS  Log bucket (CMEK): messages-key

-- Service accounts --
  PASS  vm-prod: vm-prod@bluedragon-sre-vuft1e.iam.gserviceaccount.com
  PASS  gke-node-prod: gke-node-prod@bluedragon-sre-vuft1e.iam.gserviceaccount.com
  PASS  cloudrun-prod: cloudrun-prod@bluedragon-sre-vuft1e.iam.gserviceaccount.com
  PASS  developer-prod: developer-prod@bluedragon-sre-vuft1e.iam.gserviceaccount.com
  PASS  admin-prod: admin-prod@bluedragon-sre-vuft1e.iam.gserviceaccount.com
  PASS  sre-prod: sre-prod@bluedragon-sre-vuft1e.iam.gserviceaccount.com
  PASS  dba-prod: dba-prod@bluedragon-sre-vuft1e.iam.gserviceaccount.com

== Summary: 38 passed, 0 failed ==
All expected resources present and healthy.

