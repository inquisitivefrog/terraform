tim@Timothys-MacBook-Air prod % terraform apply plan-prod 
random_string.suffix: Creating...
random_string.suffix: Creation complete after 0s [id=c3pfltlz]
google_project_service.apis["compute.googleapis.com"]: Creating...
google_project_service.apis["run.googleapis.com"]: Creating...
google_project_service.apis["monitoring.googleapis.com"]: Creating...
google_project_service.apis["redis.googleapis.com"]: Creating...
google_project_service.apis["iam.googleapis.com"]: Creating...
google_project_service.apis["logging.googleapis.com"]: Creating...
google_project_service.apis["container.googleapis.com"]: Creating...
google_project_service.apis["compute.googleapis.com"]: Creation complete after 4s [id=bluedragon-sre-vuft1e/compute.googleapis.com]
google_project_service.apis["iam.googleapis.com"]: Creation complete after 4s [id=bluedragon-sre-vuft1e/iam.googleapis.com]
google_project_service.apis["run.googleapis.com"]: Creation complete after 4s [id=bluedragon-sre-vuft1e/run.googleapis.com]
google_project_service.apis["monitoring.googleapis.com"]: Creation complete after 4s [id=bluedragon-sre-vuft1e/monitoring.googleapis.com]
google_project_service.apis["logging.googleapis.com"]: Creation complete after 4s [id=bluedragon-sre-vuft1e/logging.googleapis.com]
google_project_service.apis["redis.googleapis.com"]: Creation complete after 4s [id=bluedragon-sre-vuft1e/redis.googleapis.com]
google_project_service.apis["container.googleapis.com"]: Creation complete after 4s [id=bluedragon-sre-vuft1e/container.googleapis.com]
module.kms.data.google_storage_project_service_account.gcs: Reading...
module.kms.data.google_project.this: Reading...
module.identity.google_service_account.admin: Creating...
module.kms.google_kms_key_ring.main: Creating...
module.identity.google_service_account.developer: Creating...
module.identity.google_service_account.gke_node: Creating...
module.identity.google_service_account.vm: Creating...
module.identity.google_service_account.cloudrun: Creating...
module.vpc.google_compute_network.main: Creating...
module.identity.google_service_account.operators["dba"]: Creating...
module.kms.data.google_storage_project_service_account.gcs: Read complete after 1s [id=service-581958729900@gs-project-accounts.iam.gserviceaccount.com]
module.identity.google_service_account.operators["sre"]: Creating...
module.kms.google_kms_key_ring.main: Creation complete after 1s [id=projects/bluedragon-sre-vuft1e/locations/us-west2/keyRings/single-instance-prod-c3pfltlz]
module.kms.google_kms_crypto_key.messages_key: Creating...
module.kms.data.google_project.this: Read complete after 1s [id=projects/bluedragon-sre-vuft1e]
module.kms.google_kms_crypto_key.asymmetric_key: Creating...
module.kms.google_kms_crypto_key.messages_key: Creation complete after 0s [id=projects/bluedragon-sre-vuft1e/locations/us-west2/keyRings/single-instance-prod-c3pfltlz/cryptoKeys/messages-key]
module.kms.google_kms_crypto_key.gke_key: Creating...
module.kms.google_kms_crypto_key.asymmetric_key: Creation complete after 0s [id=projects/bluedragon-sre-vuft1e/locations/us-west2/keyRings/single-instance-prod-c3pfltlz/cryptoKeys/asymmetric-key]
module.kms.google_kms_crypto_key.symmetric_key: Creating...
module.kms.google_kms_crypto_key.gke_key: Creation complete after 0s [id=projects/bluedragon-sre-vuft1e/locations/us-west2/keyRings/single-instance-prod-c3pfltlz/cryptoKeys/gke-secrets-key]
module.kms.google_kms_crypto_key_iam_binding.messages_key: Creating...
module.kms.google_kms_crypto_key.symmetric_key: Creation complete after 0s [id=projects/bluedragon-sre-vuft1e/locations/us-west2/keyRings/single-instance-prod-c3pfltlz/cryptoKeys/symmetric-key]
module.kms.google_kms_crypto_key_iam_member.gke_key: Creating...
module.kms.google_kms_crypto_key_iam_binding.messages_key: Creation complete after 5s [id=projects/bluedragon-sre-vuft1e/locations/us-west2/keyRings/single-instance-prod-c3pfltlz/cryptoKeys/messages-key/roles/cloudkms.cryptoKeyEncrypterDecrypter]
module.messages.google_pubsub_topic.custom: Creating...
module.kms.google_kms_crypto_key_iam_member.gke_key: Creation complete after 5s [id=projects/bluedragon-sre-vuft1e/locations/us-west2/keyRings/single-instance-prod-c3pfltlz/cryptoKeys/gke-secrets-key/roles/cloudkms.cryptoKeyEncrypterDecrypter/serviceAccount:service-581958729900@container-engine-robot.iam.gserviceaccount.com]
module.messages.google_pubsub_topic.example: Creating...
module.messages.google_pubsub_topic.custom: Creation complete after 3s [id=projects/bluedragon-sre-vuft1e/topics/custom-topic-prod]
module.storage.google_storage_bucket.log_bucket: Creating...
module.messages.google_pubsub_topic.example: Creation complete after 3s [id=projects/bluedragon-sre-vuft1e/topics/example-topic-prod]
module.messages.google_pubsub_subscription.custom: Creating...
module.storage.google_storage_bucket.log_bucket: Creation complete after 1s [id=bluedragon-log-bucket-c3pfltlz]
module.messages.google_pubsub_topic_iam_member.example_allow_gcs: Creating...
module.identity.google_service_account.admin: Still creating... [00m10s elapsed]
module.identity.google_service_account.gke_node: Still creating... [00m10s elapsed]
module.identity.google_service_account.developer: Still creating... [00m10s elapsed]
module.identity.google_service_account.vm: Still creating... [00m10s elapsed]
module.vpc.google_compute_network.main: Still creating... [00m10s elapsed]
module.identity.google_service_account.cloudrun: Still creating... [00m10s elapsed]
module.identity.google_service_account.operators["dba"]: Still creating... [00m10s elapsed]
module.identity.google_service_account.operators["sre"]: Still creating... [00m10s elapsed]
module.messages.google_pubsub_subscription.custom: Creation complete after 3s [id=projects/bluedragon-sre-vuft1e/subscriptions/custom-ordered-prod]
module.messages.google_pubsub_subscription.example: Creating...
module.identity.google_service_account.cloudrun: Creation complete after 13s [id=projects/bluedragon-sre-vuft1e/serviceAccounts/cloudrun-prod@bluedragon-sre-vuft1e.iam.gserviceaccount.com]
module.storage.google_storage_bucket_iam_member.log_bucket_writer: Creating...
module.identity.google_service_account.developer: Creation complete after 13s [id=projects/bluedragon-sre-vuft1e/serviceAccounts/developer-prod@bluedragon-sre-vuft1e.iam.gserviceaccount.com]
module.kms.google_kms_crypto_key_iam_member.asymmetric_key_signer: Creating...
module.identity.google_service_account.operators["dba"]: Creation complete after 14s [id=projects/bluedragon-sre-vuft1e/serviceAccounts/dba-prod@bluedragon-sre-vuft1e.iam.gserviceaccount.com]
module.identity.google_service_account.admin: Creation complete after 14s [id=projects/bluedragon-sre-vuft1e/serviceAccounts/admin-prod@bluedragon-sre-vuft1e.iam.gserviceaccount.com]
module.identity.google_kms_key_ring_iam_member.admin_kms: Creating...
module.kms.google_kms_crypto_key_iam_member.asymmetric_key_admin: Creating...
module.messages.google_pubsub_subscription.example: Creation complete after 2s [id=projects/bluedragon-sre-vuft1e/subscriptions/example-push-prod]
module.kms.google_kms_crypto_key_iam_member.symmetric_key_admin: Creating...
module.messages.google_pubsub_topic_iam_member.example_allow_gcs: Creation complete after 5s [id=projects/bluedragon-sre-vuft1e/topics/example-topic-prod/roles/pubsub.publisher/serviceAccount:service-581958729900@gs-project-accounts.iam.gserviceaccount.com]
module.storage.google_storage_notification.log_bucket: Creating...
module.storage.google_storage_notification.log_bucket: Creation complete after 0s [id=bluedragon-log-bucket-c3pfltlz/notificationConfigs/2]
module.storage.google_storage_bucket_iam_member.log_bucket_writer: Creation complete after 4s [id=b/bluedragon-log-bucket-c3pfltlz/roles/storage.objectCreator/group:cloud-storage-analytics@google.com]
module.storage.google_storage_bucket.dev_bucket: Creating...
module.identity.google_kms_key_ring_iam_member.admin_kms: Creation complete after 4s [id=projects/bluedragon-sre-vuft1e/locations/us-west2/keyRings/single-instance-prod-c3pfltlz/roles/cloudkms.admin/serviceAccount:admin-prod@bluedragon-sre-vuft1e.iam.gserviceaccount.com]
module.kms.google_kms_crypto_key_iam_member.symmetric_key_admin: Creation complete after 4s [id=projects/bluedragon-sre-vuft1e/locations/us-west2/keyRings/single-instance-prod-c3pfltlz/cryptoKeys/symmetric-key/roles/cloudkms.admin/serviceAccount:admin-prod@bluedragon-sre-vuft1e.iam.gserviceaccount.com]
module.storage.google_storage_bucket.dev_bucket: Creation complete after 1s [id=bluedragon-dev-bucket-c3pfltlz]
module.identity.google_storage_bucket_iam_member.developer_bucket: Creating...
module.identity.google_storage_bucket_iam_member.admin_bucket: Creating...
module.storage.google_storage_notification.dev_bucket: Creating...
module.storage.google_storage_notification.dev_bucket: Creation complete after 1s [id=bluedragon-dev-bucket-c3pfltlz/notificationConfigs/1]
module.identity.google_service_account.vm: Still creating... [00m20s elapsed]
module.identity.google_service_account.gke_node: Still creating... [00m20s elapsed]
module.vpc.google_compute_network.main: Still creating... [00m20s elapsed]
module.identity.google_service_account.operators["sre"]: Still creating... [00m20s elapsed]
module.kms.google_kms_crypto_key_iam_member.asymmetric_key_signer: Creation complete after 8s [id=projects/bluedragon-sre-vuft1e/locations/us-west2/keyRings/single-instance-prod-c3pfltlz/cryptoKeys/asymmetric-key/roles/cloudkms.signerVerifier/serviceAccount:developer-prod@bluedragon-sre-vuft1e.iam.gserviceaccount.com]
module.kms.google_kms_crypto_key_iam_member.asymmetric_key_admin: Creation complete after 8s [id=projects/bluedragon-sre-vuft1e/locations/us-west2/keyRings/single-instance-prod-c3pfltlz/cryptoKeys/asymmetric-key/roles/cloudkms.admin/serviceAccount:admin-prod@bluedragon-sre-vuft1e.iam.gserviceaccount.com]
module.vpc.google_compute_network.main: Creation complete after 23s [id=projects/bluedragon-sre-vuft1e/global/networks/vpc-main-prod]
module.vpc.google_compute_router.router: Creating...
module.networking.google_compute_firewall.private_vm_egress_ssh: Creating...
module.vpc.google_compute_subnetwork.public: Creating...
module.vpc.google_compute_subnetwork.private: Creating...
module.networking.google_compute_firewall.public_vm_from_laptop: Creating...
module.identity.google_service_account.operators["sre"]: Creation complete after 22s [id=projects/bluedragon-sre-vuft1e/serviceAccounts/sre-prod@bluedragon-sre-vuft1e.iam.gserviceaccount.com]
module.networking.google_compute_firewall.gke_nodes_from_vpc: Creating...
module.identity.google_storage_bucket_iam_member.developer_bucket: Creation complete after 10s [id=b/bluedragon-dev-bucket-c3pfltlz/roles/storage.objectViewer/serviceAccount:developer-prod@bluedragon-sre-vuft1e.iam.gserviceaccount.com]
module.networking.google_compute_firewall.private_vm_egress_deny: Creating...
module.identity.google_storage_bucket_iam_member.admin_bucket: Creation complete after 10s [id=b/bluedragon-dev-bucket-c3pfltlz/roles/storage.admin/serviceAccount:admin-prod@bluedragon-sre-vuft1e.iam.gserviceaccount.com]
module.networking.google_compute_firewall.public_vm_from_iap: Creating...
module.identity.google_service_account.gke_node: Creation complete after 29s [id=projects/bluedragon-sre-vuft1e/serviceAccounts/gke-node-prod@bluedragon-sre-vuft1e.iam.gserviceaccount.com]
module.networking.google_compute_firewall.private_vm_egress: Creating...
module.identity.google_service_account.vm: Still creating... [00m30s elapsed]
module.vpc.google_compute_router.router: Still creating... [00m10s elapsed]
module.vpc.google_compute_subnetwork.private: Still creating... [00m10s elapsed]
module.vpc.google_compute_subnetwork.public: Still creating... [00m10s elapsed]
module.networking.google_compute_firewall.private_vm_egress_ssh: Still creating... [00m10s elapsed]
module.networking.google_compute_firewall.public_vm_from_laptop: Still creating... [00m10s elapsed]
module.networking.google_compute_firewall.gke_nodes_from_vpc: Still creating... [00m10s elapsed]
module.vpc.google_compute_subnetwork.public: Creation complete after 11s [id=projects/bluedragon-sre-vuft1e/regions/us-west2/subnetworks/public-prod]
module.networking.google_compute_firewall.public_vm_egress: Creating...
module.networking.google_compute_firewall.gke_nodes_from_vpc: Creation complete after 11s [id=projects/bluedragon-sre-vuft1e/global/firewalls/gke-nodes-from-vpc-prod]
module.cache.google_redis_instance.main: Creating...
module.networking.google_compute_firewall.public_vm_from_laptop: Creation complete after 11s [id=projects/bluedragon-sre-vuft1e/global/firewalls/public-vm-from-laptop-prod]
module.networking.google_compute_firewall.private_vm_egress_ssh: Creation complete after 11s [id=projects/bluedragon-sre-vuft1e/global/firewalls/private-vm-egress-ssh-prod]
module.networking.google_compute_firewall.public_vm_egress_deny: Creating...
module.identity.google_service_account_iam_member.operators_assume_admin["dba"]: Creating...
module.vpc.google_compute_router.router: Creation complete after 13s [id=projects/bluedragon-sre-vuft1e/regions/us-west2/routers/router-prod]
module.identity.google_service_account_iam_member.operators_assume_admin["sre"]: Creating...
module.networking.google_compute_firewall.private_vm_egress_deny: Still creating... [00m10s elapsed]
module.networking.google_compute_firewall.public_vm_from_iap: Still creating... [00m10s elapsed]
module.networking.google_compute_firewall.private_vm_egress: Still creating... [00m10s elapsed]
module.networking.google_compute_firewall.private_vm_egress_deny: Creation complete after 12s [id=projects/bluedragon-sre-vuft1e/global/firewalls/private-vm-egress-deny-prod]
module.networking.google_compute_firewall.public_vm_from_iap: Creation complete after 12s [id=projects/bluedragon-sre-vuft1e/global/firewalls/public-vm-from-iap-prod]
module.networking.google_compute_firewall.private_vm_from_public: Creating...
module.identity.google_service_account.vm: Still creating... [00m40s elapsed]
module.networking.google_compute_firewall.private_vm_egress: Creation complete after 13s [id=projects/bluedragon-sre-vuft1e/global/firewalls/private-vm-egress-prod]
module.vpc.google_compute_subnetwork.private: Still creating... [00m20s elapsed]
module.identity.google_service_account_iam_member.operators_assume_admin["dba"]: Creation complete after 9s [id=projects/bluedragon-sre-vuft1e/serviceAccounts/admin-prod@bluedragon-sre-vuft1e.iam.gserviceaccount.com/roles/iam.serviceAccountTokenCreator/serviceAccount:dba-prod@bluedragon-sre-vuft1e.iam.gserviceaccount.com]
module.identity.google_service_account_iam_member.operators_assume_admin["sre"]: Creation complete after 7s [id=projects/bluedragon-sre-vuft1e/serviceAccounts/admin-prod@bluedragon-sre-vuft1e.iam.gserviceaccount.com/roles/iam.serviceAccountTokenCreator/serviceAccount:sre-prod@bluedragon-sre-vuft1e.iam.gserviceaccount.com]
module.networking.google_compute_firewall.public_vm_egress: Still creating... [00m10s elapsed]
module.vpc.google_compute_subnetwork.private: Creation complete after 21s [id=projects/bluedragon-sre-vuft1e/regions/us-west2/subnetworks/private-prod]
module.networking.google_compute_firewall.public_vm_egress_internal: Creating...
module.vpc.google_compute_router_nat.nat: Creating...
module.compute.google_cloud_run_v2_service.nginx: Creating...
module.cache.google_redis_instance.main: Still creating... [00m10s elapsed]
module.gke.google_container_cluster.this: Creating...
module.networking.google_compute_firewall.public_vm_egress_deny: Still creating... [00m10s elapsed]
module.networking.google_compute_firewall.public_vm_egress: Creation complete after 11s [id=projects/bluedragon-sre-vuft1e/global/firewalls/public-vm-egress-prod]
module.networking.google_compute_firewall.public_vm_egress_deny: Creation complete after 11s [id=projects/bluedragon-sre-vuft1e/global/firewalls/public-vm-egress-deny-prod]
module.networking.google_compute_firewall.private_vm_from_public: Still creating... [00m10s elapsed]
module.identity.google_service_account.vm: Still creating... [00m50s elapsed]
module.networking.google_compute_firewall.private_vm_from_public: Creation complete after 13s [id=projects/bluedragon-sre-vuft1e/global/firewalls/private-vm-from-public-prod]
module.networking.google_compute_firewall.public_vm_egress_internal: Still creating... [00m10s elapsed]
module.vpc.google_compute_router_nat.nat: Still creating... [00m10s elapsed]
module.compute.google_cloud_run_v2_service.nginx: Still creating... [00m10s elapsed]
module.cache.google_redis_instance.main: Still creating... [00m20s elapsed]
module.gke.google_container_cluster.this: Still creating... [00m10s elapsed]
module.vpc.google_compute_router_nat.nat: Creation complete after 11s [id=bluedragon-sre-vuft1e/us-west2/router-prod/nat-prod]
module.networking.google_compute_firewall.public_vm_egress_internal: Creation complete after 11s [id=projects/bluedragon-sre-vuft1e/global/firewalls/public-vm-egress-internal-prod]
module.identity.google_service_account.vm: Still creating... [01m00s elapsed]
module.compute.google_cloud_run_v2_service.nginx: Still creating... [00m20s elapsed]
module.cache.google_redis_instance.main: Still creating... [00m30s elapsed]
module.gke.google_container_cluster.this: Still creating... [00m20s elapsed]
module.compute.google_cloud_run_v2_service.nginx: Creation complete after 22s [id=projects/bluedragon-sre-vuft1e/locations/us-west2/services/nginx-prod]
module.identity.google_cloud_run_v2_service_iam_member.admin_run: Creating...
module.identity.google_service_account.vm: Still creating... [01m10s elapsed]
module.identity.google_cloud_run_v2_service_iam_member.admin_run: Creation complete after 4s [id=projects/bluedragon-sre-vuft1e/locations/us-west2/services/nginx-prod/roles/run.admin/serviceAccount:admin-prod@bluedragon-sre-vuft1e.iam.gserviceaccount.com]
module.cache.google_redis_instance.main: Still creating... [00m40s elapsed]
module.gke.google_container_cluster.this: Still creating... [00m30s elapsed]
module.identity.google_service_account.vm: Still creating... [01m20s elapsed]
module.cache.google_redis_instance.main: Still creating... [00m50s elapsed]
module.gke.google_container_cluster.this: Still creating... [00m40s elapsed]
module.identity.google_service_account.vm: Still creating... [01m30s elapsed]
module.cache.google_redis_instance.main: Still creating... [01m00s elapsed]
module.gke.google_container_cluster.this: Still creating... [00m50s elapsed]
module.identity.google_service_account.vm: Still creating... [01m40s elapsed]
module.identity.google_service_account.vm: Creation complete after 1m43s [id=projects/bluedragon-sre-vuft1e/serviceAccounts/vm-prod@bluedragon-sre-vuft1e.iam.gserviceaccount.com]
module.identity.google_project_iam_member.roles["vm_gke"]: Creating...
module.identity.google_project_iam_member.roles["node_ar"]: Creating...
module.identity.google_service_account_iam_member.admin_act_as["cloudrun"]: Creating...
module.identity.google_project_iam_member.roles["node_log"]: Creating...
module.identity.google_service_account_iam_member.admin_act_as["vm"]: Creating...
module.identity.google_project_iam_member.roles["admin_redis"]: Creating...
module.compute.google_compute_instance.private: Creating...
module.compute.google_compute_instance.public: Creating...
module.cache.google_redis_instance.main: Still creating... [01m10s elapsed]
module.gke.google_container_cluster.this: Still creating... [01m00s elapsed]
module.identity.google_service_account_iam_member.admin_act_as["cloudrun"]: Creation complete after 4s [id=projects/bluedragon-sre-vuft1e/serviceAccounts/cloudrun-prod@bluedragon-sre-vuft1e.iam.gserviceaccount.com/roles/iam.serviceAccountUser/serviceAccount:admin-prod@bluedragon-sre-vuft1e.iam.gserviceaccount.com]
module.identity.google_service_account_iam_member.admin_act_as["vm"]: Creation complete after 4s [id=projects/bluedragon-sre-vuft1e/serviceAccounts/vm-prod@bluedragon-sre-vuft1e.iam.gserviceaccount.com/roles/iam.serviceAccountUser/serviceAccount:admin-prod@bluedragon-sre-vuft1e.iam.gserviceaccount.com]
module.identity.google_project_iam_member.roles["vm_metric"]: Creating...
module.identity.google_project_iam_member.roles["admin_pubsub"]: Creating...
module.identity.google_project_iam_member.roles["vm_gke"]: Still creating... [00m10s elapsed]
module.identity.google_project_iam_member.roles["node_ar"]: Still creating... [00m10s elapsed]
module.identity.google_project_iam_member.roles["node_log"]: Still creating... [00m10s elapsed]
module.identity.google_project_iam_member.roles["admin_redis"]: Still creating... [00m10s elapsed]
module.compute.google_compute_instance.private: Still creating... [00m10s elapsed]
module.compute.google_compute_instance.public: Still creating... [00m10s elapsed]
module.cache.google_redis_instance.main: Still creating... [01m20s elapsed]
module.gke.google_container_cluster.this: Still creating... [01m10s elapsed]
module.identity.google_project_iam_member.roles["admin_redis"]: Creation complete after 12s [id=bluedragon-sre-vuft1e/roles/redis.admin/serviceAccount:admin-prod@bluedragon-sre-vuft1e.iam.gserviceaccount.com]
module.identity.google_project_iam_member.roles["node_meta"]: Creating...
module.identity.google_project_iam_member.roles["vm_gke"]: Creation complete after 12s [id=bluedragon-sre-vuft1e/roles/container.clusterViewer/serviceAccount:vm-prod@bluedragon-sre-vuft1e.iam.gserviceaccount.com]
module.identity.google_project_iam_member.roles["node_metric"]: Creating...
module.identity.google_project_iam_member.roles["node_ar"]: Creation complete after 12s [id=bluedragon-sre-vuft1e/roles/artifactregistry.reader/serviceAccount:gke-node-prod@bluedragon-sre-vuft1e.iam.gserviceaccount.com]
module.identity.google_project_iam_member.roles["vm_log"]: Creating...
module.identity.google_project_iam_member.roles["node_log"]: Creation complete after 13s [id=bluedragon-sre-vuft1e/roles/logging.logWriter/serviceAccount:gke-node-prod@bluedragon-sre-vuft1e.iam.gserviceaccount.com]
module.identity.google_project_iam_member.roles["node_viewer"]: Creating...
module.identity.google_project_iam_member.roles["admin_pubsub"]: Creation complete after 9s [id=bluedragon-sre-vuft1e/roles/pubsub.editor/serviceAccount:admin-prod@bluedragon-sre-vuft1e.iam.gserviceaccount.com]
module.identity.google_project_iam_member.roles["vm_metric"]: Creation complete after 10s [id=bluedragon-sre-vuft1e/roles/monitoring.metricWriter/serviceAccount:vm-prod@bluedragon-sre-vuft1e.iam.gserviceaccount.com]
module.compute.google_compute_instance.private: Creation complete after 16s [id=projects/bluedragon-sre-vuft1e/zones/us-west2-a/instances/private-vm-prod]
module.compute.google_compute_instance.public: Creation complete after 16s [id=projects/bluedragon-sre-vuft1e/zones/us-west2-a/instances/public-vm-prod]
module.identity.google_compute_instance_iam_member.developer_vms["public-vm-prod"]: Creating...
module.identity.google_compute_instance_iam_member.admin_vms["public-vm-prod"]: Creating...
module.identity.google_compute_instance_iam_member.developer_vms["private-vm-prod"]: Creating...
module.identity.google_compute_instance_iam_member.admin_vms["private-vm-prod"]: Creating...
module.identity.google_project_iam_member.roles["node_metric"]: Creation complete after 8s [id=bluedragon-sre-vuft1e/roles/monitoring.metricWriter/serviceAccount:gke-node-prod@bluedragon-sre-vuft1e.iam.gserviceaccount.com]
module.identity.google_project_iam_member.roles["node_meta"]: Creation complete after 8s [id=bluedragon-sre-vuft1e/roles/stackdriver.resourceMetadata.writer/serviceAccount:gke-node-prod@bluedragon-sre-vuft1e.iam.gserviceaccount.com]
module.identity.google_project_iam_member.roles["node_viewer"]: Creation complete after 7s [id=bluedragon-sre-vuft1e/roles/monitoring.viewer/serviceAccount:gke-node-prod@bluedragon-sre-vuft1e.iam.gserviceaccount.com]
module.identity.google_project_iam_member.roles["vm_log"]: Creation complete after 8s [id=bluedragon-sre-vuft1e/roles/logging.logWriter/serviceAccount:vm-prod@bluedragon-sre-vuft1e.iam.gserviceaccount.com]
module.cache.google_redis_instance.main: Still creating... [01m30s elapsed]
module.gke.google_container_cluster.this: Still creating... [01m20s elapsed]
module.identity.google_compute_instance_iam_member.developer_vms["private-vm-prod"]: Creation complete after 9s [id=projects/bluedragon-sre-vuft1e/zones/us-west2-a/instances/private-vm-prod/roles/compute.viewer/serviceAccount:developer-prod@bluedragon-sre-vuft1e.iam.gserviceaccount.com]
module.identity.google_compute_instance_iam_member.admin_vms["public-vm-prod"]: Creation complete after 9s [id=projects/bluedragon-sre-vuft1e/zones/us-west2-a/instances/public-vm-prod/roles/compute.instanceAdmin.v1/serviceAccount:admin-prod@bluedragon-sre-vuft1e.iam.gserviceaccount.com]
module.identity.google_compute_instance_iam_member.admin_vms["private-vm-prod"]: Creation complete after 9s [id=projects/bluedragon-sre-vuft1e/zones/us-west2-a/instances/private-vm-prod/roles/compute.instanceAdmin.v1/serviceAccount:admin-prod@bluedragon-sre-vuft1e.iam.gserviceaccount.com]
module.identity.google_compute_instance_iam_member.developer_vms["public-vm-prod"]: Creation complete after 9s [id=projects/bluedragon-sre-vuft1e/zones/us-west2-a/instances/public-vm-prod/roles/compute.viewer/serviceAccount:developer-prod@bluedragon-sre-vuft1e.iam.gserviceaccount.com]
module.gke.google_container_cluster.this: Still creating... [01m30s elapsed]
module.cache.google_redis_instance.main: Still creating... [01m40s elapsed]
module.gke.google_container_cluster.this: Still creating... [01m40s elapsed]
module.cache.google_redis_instance.main: Still creating... [01m50s elapsed]
module.cache.google_redis_instance.main: Still creating... [02m00s elapsed]
module.gke.google_container_cluster.this: Still creating... [01m50s elapsed]
module.gke.google_container_cluster.this: Still creating... [02m00s elapsed]
module.cache.google_redis_instance.main: Still creating... [02m10s elapsed]
module.cache.google_redis_instance.main: Still creating... [02m20s elapsed]
module.gke.google_container_cluster.this: Still creating... [02m10s elapsed]
module.gke.google_container_cluster.this: Still creating... [02m20s elapsed]
module.cache.google_redis_instance.main: Still creating... [02m30s elapsed]
module.cache.google_redis_instance.main: Still creating... [02m40s elapsed]
module.gke.google_container_cluster.this: Still creating... [02m30s elapsed]
module.gke.google_container_cluster.this: Still creating... [02m40s elapsed]
module.cache.google_redis_instance.main: Still creating... [02m50s elapsed]
module.cache.google_redis_instance.main: Still creating... [03m00s elapsed]
module.gke.google_container_cluster.this: Still creating... [02m50s elapsed]
module.cache.google_redis_instance.main: Still creating... [03m10s elapsed]
module.gke.google_container_cluster.this: Still creating... [03m00s elapsed]
module.gke.google_container_cluster.this: Still creating... [03m10s elapsed]
module.cache.google_redis_instance.main: Still creating... [03m20s elapsed]
module.cache.google_redis_instance.main: Still creating... [03m30s elapsed]
module.gke.google_container_cluster.this: Still creating... [03m20s elapsed]
module.gke.google_container_cluster.this: Still creating... [03m30s elapsed]
module.cache.google_redis_instance.main: Still creating... [03m40s elapsed]
module.cache.google_redis_instance.main: Still creating... [03m50s elapsed]
module.gke.google_container_cluster.this: Still creating... [03m40s elapsed]
module.gke.google_container_cluster.this: Still creating... [03m50s elapsed]
module.cache.google_redis_instance.main: Still creating... [04m00s elapsed]
module.gke.google_container_cluster.this: Still creating... [04m00s elapsed]
module.cache.google_redis_instance.main: Still creating... [04m10s elapsed]
module.cache.google_redis_instance.main: Still creating... [04m20s elapsed]
module.gke.google_container_cluster.this: Still creating... [04m10s elapsed]
module.cache.google_redis_instance.main: Creation complete after 4m24s [id=projects/bluedragon-sre-vuft1e/locations/us-west2/instances/redis-prod]
module.networking.google_compute_firewall.private_vm_egress_redis: Creating...
module.gke.google_container_cluster.this: Still creating... [04m20s elapsed]
module.networking.google_compute_firewall.private_vm_egress_redis: Still creating... [00m10s elapsed]
module.networking.google_compute_firewall.private_vm_egress_redis: Creation complete after 11s [id=projects/bluedragon-sre-vuft1e/global/firewalls/private-vm-egress-redis-prod]
module.gke.google_container_cluster.this: Still creating... [04m30s elapsed]
module.gke.google_container_cluster.this: Still creating... [04m40s elapsed]
module.gke.google_container_cluster.this: Still creating... [04m50s elapsed]
module.gke.google_container_cluster.this: Still creating... [05m00s elapsed]
module.gke.google_container_cluster.this: Still creating... [05m10s elapsed]
module.gke.google_container_cluster.this: Still creating... [05m20s elapsed]
module.gke.google_container_cluster.this: Still creating... [05m30s elapsed]
module.gke.google_container_cluster.this: Still creating... [05m40s elapsed]
module.gke.google_container_cluster.this: Still creating... [05m50s elapsed]
module.gke.google_container_cluster.this: Still creating... [06m00s elapsed]
module.gke.google_container_cluster.this: Still creating... [06m10s elapsed]
module.gke.google_container_cluster.this: Still creating... [06m20s elapsed]
module.gke.google_container_cluster.this: Still creating... [06m30s elapsed]
module.gke.google_container_cluster.this: Still creating... [06m40s elapsed]
module.gke.google_container_cluster.this: Still creating... [06m50s elapsed]
module.gke.google_container_cluster.this: Still creating... [07m00s elapsed]
module.gke.google_container_cluster.this: Still creating... [07m10s elapsed]
module.gke.google_container_cluster.this: Still creating... [07m20s elapsed]
module.gke.google_container_cluster.this: Still creating... [07m30s elapsed]
module.gke.google_container_cluster.this: Still creating... [07m40s elapsed]
module.gke.google_container_cluster.this: Still creating... [07m50s elapsed]
module.gke.google_container_cluster.this: Still creating... [08m00s elapsed]
module.gke.google_container_cluster.this: Still creating... [08m10s elapsed]
module.gke.google_container_cluster.this: Still creating... [08m20s elapsed]
module.gke.google_container_cluster.this: Still creating... [08m30s elapsed]
module.gke.google_container_cluster.this: Still creating... [08m40s elapsed]
module.gke.google_container_cluster.this: Still creating... [08m50s elapsed]
module.gke.google_container_cluster.this: Still creating... [09m00s elapsed]
module.gke.google_container_cluster.this: Still creating... [09m10s elapsed]
module.gke.google_container_cluster.this: Still creating... [09m20s elapsed]
module.gke.google_container_cluster.this: Still creating... [09m30s elapsed]
module.gke.google_container_cluster.this: Still creating... [09m40s elapsed]
module.gke.google_container_cluster.this: Still creating... [09m50s elapsed]
module.gke.google_container_cluster.this: Creation complete after 10m0s [id=projects/bluedragon-sre-vuft1e/locations/us-west2-a/clusters/gke-prod-c3pfltlz]
module.gke.google_container_node_pool.this: Creating...
module.gke.google_container_node_pool.this: Still creating... [00m10s elapsed]
module.gke.google_container_node_pool.this: Still creating... [00m20s elapsed]
module.gke.google_container_node_pool.this: Still creating... [00m30s elapsed]
module.gke.google_container_node_pool.this: Still creating... [00m40s elapsed]
module.gke.google_container_node_pool.this: Still creating... [00m50s elapsed]
module.gke.google_container_node_pool.this: Still creating... [01m00s elapsed]
module.gke.google_container_node_pool.this: Still creating... [01m10s elapsed]
module.gke.google_container_node_pool.this: Creation complete after 1m13s [id=projects/bluedragon-sre-vuft1e/locations/us-west2-a/clusters/gke-prod-c3pfltlz/nodePools/np-prod-c3pfltlz]

Apply complete! Resources: 79 added, 0 changed, 0 destroyed.

Outputs:

cloud_run_uri = "https://nginx-prod-yez3ct5uaq-wl.a.run.app"
example_topic_id = "projects/bluedragon-sre-vuft1e/topics/example-topic-prod"
gke_cluster_endpoint = "34.102.75.91"
gke_cluster_name = "gke-prod-c3pfltlz"
kubeconfig_command = "gcloud container clusters get-credentials gke-prod-c3pfltlz --zone us-west2-a --project bluedragon-sre-vuft1e"
private_vm_ip = "10.0.4.3"
project_id = "bluedragon-sre-vuft1e"
public_vm_ip = "34.94.48.78"
redis_auth_string = <sensitive>
redis_host = "10.0.250.3"
redis_port = 6378
zone = "us-west2-a"
tim@Timothys-MacBook-Air prod % terraform state list 
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
module.identity.google_compute_instance_iam_member.admin_vms["private-vm-prod"]
module.identity.google_compute_instance_iam_member.admin_vms["public-vm-prod"]
module.identity.google_compute_instance_iam_member.developer_vms["private-vm-prod"]
module.identity.google_compute_instance_iam_member.developer_vms["public-vm-prod"]
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
module.networking.google_compute_firewall.public_vm_from_iap
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
tim@Timothys-MacBook-Air prod % 

