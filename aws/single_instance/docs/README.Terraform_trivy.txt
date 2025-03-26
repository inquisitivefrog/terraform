
Docs
----
1. https://trivy.dev/v0.57/docs/references/configuration/config-file/
2. https://trivy.dev/v0.56/tutorials/misconfiguration/terraform/
3. https://github.com/aquasecurity/trivy/blob/v0.57.1/examples/trivy-conf/trivy.yaml
4. https://trivy.dev/v0.43/docs/configuration/filtering/

Installation
------------
tim@Tims-MBP single_instance % brew install trivy
Warning: trivy 0.60.0 is already installed and up-to-date.
To reinstall 0.60.0, run:
  brew reinstall trivy
tim@Tims-MBP single_instance % which trivy
/usr/local/bin/trivy
tim@Tims-MBP single_instance % trivy --version
Version: 0.60.0

Configuration
-------------

Execution
---------
tim@Tims-MBP single_instance % trivy config .

tim@Tims-MBP single_instance % trivy config . --tf-vars terraform.tfvars --config trivy.yaml
2025-03-26T13:16:48-07:00	INFO	Loaded	file_path="trivy.yaml"
2025-03-26T13:16:48-07:00	INFO	[misconfig] Misconfiguration scanning is enabled
2025-03-26T13:16:50-07:00	INFO	[terraform scanner] Scanning root module	file_path="."
2025-03-26T13:16:51-07:00	INFO	[terraform executor] Ignore finding	rule="aws-iam-enforce-group-mfa" range="modules/identity/iam.tf:26-29"
2025-03-26T13:16:51-07:00	INFO	[terraform executor] Ignore finding	rule="aws-iam-filter-passrole-access" range="modules/identity/iam.tf:115-177"
2025-03-26T13:16:51-07:00	INFO	Detected config files	num=2

Report Summary

┌─────────────────────────┬───────────┬───────────────────┐
│         Target          │   Type    │ Misconfigurations │
├─────────────────────────┼───────────┼───────────────────┤
│ .                       │ terraform │         0         │
├─────────────────────────┼───────────┼───────────────────┤
│ modules/identity/iam.tf │ terraform │         0         │
└─────────────────────────┴───────────┴───────────────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)
