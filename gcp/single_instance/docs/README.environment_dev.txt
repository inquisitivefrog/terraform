gcp/single_instance/environments/dev: first apply, 2026-10-20.
Reconstructed from the terminal session (the original paste was truncated).
Destroyed later the same day; see ../../tfstate/docs/STATUS.md.

tim@Timothys-MacBook-Air dev % terraform apply plan-dev
random_string.suffix: Creating...
random_string.suffix: Creation complete after 0s [id=oaxxklen]
google_project_service.apis["redis.googleapis.com"]: Creating...
google_project_service.apis["monitoring.googleapis.com"]: Creating...
google_project_service.apis["logging.googleapis.com"]: Creating...
google_project_service.apis["container.googleapis.com"]: Creating...
google_project_service.apis["compute.googleapis.com"]: Creating...
google_project_service.apis["iam.googleapis.com"]: Creating...
google_project_service.apis["run.googleapis.com"]: Creating...
...
google_project_service.apis["compute.googleapis.com"]: Creation complete after 2m14s [id=bluedragon-sre-vuft1e/compute.googleapis.com]
...
module.kms.google_kms_key_ring.main: Creation complete after 0s [id=projects/bluedragon-sre-vuft1e/locations/us-west1/keyRings/single-instance-dev-oaxxklen]
...
module.cache.google_redis_instance.main: Creation complete after 4m27s [id=projects/bluedragon-sre-vuft1e/locations/us-west1/instances/redis-dev]
...
module.gke.google_container_cluster.this: Creation complete after 7m2s [id=projects/bluedragon-sre-vuft1e/locations/us-west1-a/clusters/gke-dev-oaxxklen]
module.gke.google_container_node_pool.this: Creation complete after 1m23s [id=projects/bluedragon-sre-vuft1e/locations/us-west1-a/clusters/gke-dev-oaxxklen/nodePools/np-dev-oaxxklen]
...
module.kubernetes.kubernetes_deployment_v1.app["monitor"]: Creation complete after 2m7s [id=app2/monitor-app]
module.kubernetes.kubernetes_service_v1.app["heartbeat"]: Creation complete after 1s [id=app1/heartbeat-service]
module.kubernetes.kubernetes_ingress_v1.app_ingress[0]: Creation complete after 0s [id=app1/app-ingress]

Apply complete! Resources: 96 added, 0 changed, 0 destroyed.

Outputs:

cloud_run_uri = "https://nginx-dev-yez3ct5uaq-uw.a.run.app"
example_topic_id = "projects/bluedragon-sre-vuft1e/topics/example-topic-dev"
gke_cluster_endpoint = "34.53.63.194"
gke_cluster_name = "gke-dev-oaxxklen"
kubeconfig_command = "gcloud container clusters get-credentials gke-dev-oaxxklen --zone us-west1-a --project bluedragon-sre-vuft1e"
private_vm_ip = "10.1.4.2"
public_vm_ip = "34.169.141.119"
redis_auth_string = <sensitive>
redis_host = "10.1.250.3"
redis_port = 6378
tim@Timothys-MacBook-Air dev % terraform state list
data.google_client_config.current
google_project_service.apis["compute.googleapis.com"]
google_project_service.apis["container.googleapis.com"]
google_project_service.apis["iam.googleapis.com"]
google_project_service.apis["logging.googleapis.com"]
google_project_service.apis["monitoring.googleapis.com"]
google_project_service.apis["redis.googleapis.com"]
google_project_service.apis["run.googleapis.com"]
random_string.suffix
module.cache.google_redis_instance.main
module.compute.data.google_compute_image.ubuntu
module.compute.google_cloud_run_v2_service.nginx
module.compute.google_compute_instance.private
module.compute.google_compute_instance.public
module.gke.google_container_cluster.this
module.gke.google_container_node_pool.this
module.identity.google_cloud_run_v2_service_iam_member.admin_run
module.identity.google_compute_instance_iam_member.admin_vms["private-vm-dev"]
module.identity.google_compute_instance_iam_member.admin_vms["public-vm-dev"]
module.identity.google_compute_instance_iam_member.developer_vms["private-vm-dev"]
module.identity.google_compute_instance_iam_member.developer_vms["public-vm-dev"]
module.identity.google_kms_key_ring_iam_member.admin_kms
module.identity.google_project_iam_member.roles["admin_pubsub"]
module.identity.google_project_iam_member.roles["admin_redis"]
module.identity.google_project_iam_member.roles["node_ar"]
module.identity.google_project_iam_member.roles["node_log"]
module.identity.google_project_iam_member.roles["node_meta"]
module.identity.google_project_iam_member.roles["node_metric"]
module.identity.google_project_iam_member.roles["node_viewer"]
module.identity.google_project_iam_member.roles["vm_gke"]
module.identity.google_project_iam_member.roles["vm_log"]
module.identity.google_project_iam_member.roles["vm_metric"]
module.identity.google_service_account.admin
module.identity.google_service_account.cloudrun
module.identity.google_service_account.developer
module.identity.google_service_account.gke_node
module.identity.google_service_account.operators["dba"]
module.identity.google_service_account.operators["sre"]
module.identity.google_service_account.vm
module.identity.google_service_account_iam_member.admin_act_as["cloudrun"]
module.identity.google_service_account_iam_member.admin_act_as["vm"]
module.identity.google_service_account_iam_member.operators_assume_admin["dba"]
module.identity.google_service_account_iam_member.operators_assume_admin["sre"]
module.identity.google_storage_bucket_iam_member.admin_bucket
module.identity.google_storage_bucket_iam_member.developer_bucket
module.kms.data.google_project.this
module.kms.data.google_storage_project_service_account.gcs
module.kms.google_kms_crypto_key.asymmetric_key
module.kms.google_kms_crypto_key.gke_key
module.kms.google_kms_crypto_key.messages_key
module.kms.google_kms_crypto_key.symmetric_key
module.kms.google_kms_crypto_key_iam_binding.messages_key
module.kms.google_kms_crypto_key_iam_member.asymmetric_key_admin
module.kms.google_kms_crypto_key_iam_member.asymmetric_key_signer
module.kms.google_kms_crypto_key_iam_member.gke_key
module.kms.google_kms_crypto_key_iam_member.symmetric_key_admin
module.kms.google_kms_key_ring.main
module.kubernetes.kubernetes_cluster_role_binding_v1.admins["vm"]
module.kubernetes.kubernetes_config_map_v1.app_config["app1"]
module.kubernetes.kubernetes_config_map_v1.app_config["app2"]
module.kubernetes.kubernetes_deployment_v1.app["heartbeat"]
module.kubernetes.kubernetes_deployment_v1.app["monitor"]
module.kubernetes.kubernetes_ingress_v1.app_ingress[0]
module.kubernetes.kubernetes_namespace_v1.namespaces["app1"]
module.kubernetes.kubernetes_namespace_v1.namespaces["app2"]
module.kubernetes.kubernetes_resource_quota_v1.quota["app1"]
module.kubernetes.kubernetes_resource_quota_v1.quota["app2"]
module.kubernetes.kubernetes_role_binding_v1.binding["dba-app2"]
module.kubernetes.kubernetes_role_binding_v1.binding["sre-app1"]
module.kubernetes.kubernetes_role_v1.role["dba-app2"]
module.kubernetes.kubernetes_role_v1.role["sre-app1"]
module.kubernetes.kubernetes_secret_v1.app_secret["app1"]
module.kubernetes.kubernetes_secret_v1.app_secret["app2"]
module.kubernetes.kubernetes_service_v1.app["heartbeat"]
module.kubernetes.kubernetes_service_v1.app["monitor"]
module.messages.google_pubsub_subscription.custom
module.messages.google_pubsub_subscription.example
module.messages.google_pubsub_topic.custom
module.messages.google_pubsub_topic.example
module.messages.google_pubsub_topic_iam_member.example_allow_gcs
module.networking.google_compute_firewall.gke_nodes_from_vpc
module.networking.google_compute_firewall.private_vm_egress
module.networking.google_compute_firewall.private_vm_egress_deny
module.networking.google_compute_firewall.private_vm_egress_redis
module.networking.google_compute_firewall.private_vm_egress_ssh
module.networking.google_compute_firewall.private_vm_from_public
module.networking.google_compute_firewall.public_vm_egress
module.networking.google_compute_firewall.public_vm_egress_deny
module.networking.google_compute_firewall.public_vm_egress_internal
module.networking.google_compute_firewall.public_vm_from_laptop
module.storage.google_storage_bucket.dev_bucket
module.storage.google_storage_bucket.log_bucket
module.storage.google_storage_bucket_iam_member.log_bucket_writer
module.storage.google_storage_notification.dev_bucket
module.storage.google_storage_notification.log_bucket
module.vpc.google_compute_network.main
module.vpc.google_compute_router.router
module.vpc.google_compute_router_nat.nat
module.vpc.google_compute_subnetwork.private
module.vpc.google_compute_subnetwork.public
tim@Timothys-MacBook-Air dev %

Later changes (applied before the destroy):
- private_vm_egress_redis: port 6379 -> 6378 (Memorystore with TLS)
- added module.networking.google_compute_firewall.public_vm_from_iap (SSH via IAP)
- both VMs: added the userinfo-email scope (VMs restarted; public_vm_ip became 8.231.167.48)
- check_resources.sh dev: 45/45 passed
