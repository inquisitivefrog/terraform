
tim@Tims-MBP ~ % source ~/Desktop/Work/Python_Practice/py3/bin/activate
(py3) tim@Tims-MBP ~ % pip freeze | wc -l
      93
(py3) tim@Tims-MBP ~ % pip freeze | grep checkov
checkov===3.2.383
(py3) tim@Tims-MBP ~ % which checkov
/Users/tim/Desktop/Work/Python_Practice/py3/bin/checkov
(py3) tim@Tims-MBP ~ % checkov --version
3.2.383

(py3) tim@Tims-MBP single_instance % checkov -d . --soft-fail > checkov_current.txt
(py3) tim@Tims-MBP single_instance % grep Fail checkov_current.txt 
Passed checks: 185, Failed checks: 0, Skipped checks: 8

(py3) tim@Tims-MBP single_instance % grep -A 5 CKV2_AWS_40 checkov_current.txt 
Check: CKV2_AWS_40: "Ensure AWS IAM policy does not allow full IAM privileges"
    PASSED for resource: module.identity.aws_iam_policy.assume_admin_role_policy
    File: /modules/identity/iam.tf:93-106
    Guide: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-iam-policies/bc-aws-2-40

(py3) tim@Tims-MBP single_instance % grep -A 5 CKV_AWS_273 checkov_current.txt
Check: CKV_AWS_273: "Ensure access is controlled through SSO and not AWS IAM defined users"
	SKIPPED for resource: module.identity.aws_iam_user.sre
	Suppress comment: SSO not implemented yet, using IAM users temporarily
	File: /modules/identity/iam.tf:10-15
	Calling File: /main.tf:98-108
	Guide: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-iam-policies/bc-aws-273
Check: CKV_AWS_273: "Ensure access is controlled through SSO and not AWS IAM defined users"
	SKIPPED for resource: module.identity.aws_iam_user.dba
	Suppress comment: SSO not implemented yet, using IAM users temporarily
	File: /modules/identity/iam.tf:17-22
	Calling File: /main.tf:98-108


