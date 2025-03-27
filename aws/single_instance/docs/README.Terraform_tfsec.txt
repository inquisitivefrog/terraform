
Docs
----
1. https://aquasecurity.github.io/tfsec/v1.28.13/checks/aws/api-gateway/enable-access-logging/
2. https://aquasecurity.github.io/tfsec/v1.28.13/guides/trivy/
3. https://aquasecurity.github.io/tfsec/v1.28.13/

Installation
------------
tim@Tims-MBP single_instance % brew install tfsec
==> Downloading https://formulae.brew.sh/api/formula.jws.json
==> Downloading https://formulae.brew.sh/api/cask.jws.json
Warning: tfsec 1.28.13 is already installed and up-to-date.
To reinstall 1.28.13, run:
  brew reinstall tfsec
tim@Tims-MBP single_instance % which tfsec
/usr/local/bin/tfsec
tim@Tims-MBP single_instance % tfsec --version

======================================================
tfsec is joining the Trivy family

tfsec will continue to remain available
for the time being, although our engineering
attention will be directed at Trivy going forward.

You can read more here:
https://github.com/aquasecurity/tfsec/discussions/1994
======================================================
v1.28.13
tim@Tims-MBP single_instance % tfsec --update

======================================================
tfsec is joining the Trivy family

tfsec will continue to remain available
for the time being, although our engineering
attention will be directed at Trivy going forward.

You can read more here:
https://github.com/aquasecurity/tfsec/discussions/1994
======================================================
You are already running the latest version.

Configuration
-------------
tim@Tims-MBP single_instance % vi tfsec.yml
tim@Tims-MBP single_instance % cat tfsec.yml
---
min_required_version: v1.1.2
minimum_severity: CRITICAL
include:
  - CUS002
  - aws-s3-enable-versioning
exclude:
  - CUS002:2022-12-31
  - aws-s3-enable-versioning

Execution
---------
tim@Tims-MBP single_instance % tfsec .
...
  66 passed, 5 potential problem(s) detected.

tim@Tims-MBP single_instance % tfsec . --tfvars-file=terraform.tfvars
...
  66 passed, 5 potential problem(s) detected.

tim@Tims-MBP single_instance % tfsec . --tfvars-file=terraform.tfvars --concise-output
...
  66 passed, 5 potential problem(s) detected.

tim@Tims-MBP single_instance % tfsec . --tfvars-file=terraform.tfvars --concise-output --minimum-severity CRITICAL
...

tim@Tims-MBP single_instance % tfsec . --tfvars-file=terraform.tfvars --concise-output --config-file tfsec.yml

======================================================
tfsec is joining the Trivy family

tfsec will continue to remain available
for the time being, although our engineering
attention will be directed at Trivy going forward.

You can read more here:
https://github.com/aquasecurity/tfsec/discussions/1994
======================================================

No problems detected!

(py3) tim@Tims-MBP single_instance % terraform apply plan
╷
│ Warning: Deprecated Parameter
│
│ The parameter "dynamodb_table" is deprecated. Use parameter "use_lockfile" instead.
╵

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

sns_topic_example_arn = "arn:aws:sns:us-west-1:084375569056:example-topic"
(py3) tim@Tims-MBP single_instance % aws sns publish --topic-arn "$(terraform output -raw sns_topic_example_arn)" --message "Test"
{
    "MessageId": "5a6538fe-51b4-57b7-bd6f-58a3081d7092"
}
(py3) tim@Tims-MBP single_instance % cat tfsec.yml
---
min_required_version: v1.1.2
minimum_severity: LOW
exclude:
  - aws-iam-enforce-group-mfa
(py3) tim@Tims-MBP single_instance % tfsec . --tfvars-file=terraform.tfvars --concise-output --config-file tfsec.yml

======================================================
tfsec is joining the Trivy family

tfsec will continue to remain available
for the time being, although our engineering
attention will be directed at Trivy going forward.

You can read more here:
https://github.com/aquasecurity/tfsec/discussions/1994
======================================================

No problems detected!

(py3) tim@Tims-MBP single_instance %
