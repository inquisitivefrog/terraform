
Docs
----
1. https://github.com/tfutils/tfenv
2. 

Installation
------------
tim@Tims-MBP ~ % brew list tfenv
/usr/local/Cellar/tfenv/3.0.0/bin/terraform
/usr/local/Cellar/tfenv/3.0.0/bin/tfenv
/usr/local/Cellar/tfenv/3.0.0/lib/ (6 files)
/usr/local/Cellar/tfenv/3.0.0/libexec/ (14 files)
/usr/local/Cellar/tfenv/3.0.0/sbom.spdx.json
/usr/local/Cellar/tfenv/3.0.0/share/hashicorp-keys.pgp
tim@Tims-MBP ~ % tfenv list-remote | head -5
1.12.0-beta1
1.12.0-alpha20250319
1.12.0-alpha20250312
1.12.0-alpha20250213
1.11.4
tim@Tims-MBP ~ % tfenv install 1.11.4
Installing Terraform v1.11.4
Downloading release tarball from https://releases.hashicorp.com/terraform/1.11.4/terraform_1.11.4_darwin_amd64.zip
######################################################################### 100.0%
Downloading SHA hash file from https://releases.hashicorp.com/terraform/1.11.4/terraform_1.11.4_SHA256SUMS
Not instructed to use Local PGP (/Users/tim/.tfenv/use-{gpgv,gnupg}) & No keybase install found, skipping OpenPGP signature verification
Archive:  /var/folders/r2/9j83566d31v356lqk1q64jk40000gn/T/tfenv_download.XXXXXX.RfZubodj/terraform_1.11.4_darwin_amd64.zip
  inflating: /Users/tim/.tfenv/versions/1.11.4/LICENSE.txt  
  inflating: /Users/tim/.tfenv/versions/1.11.4/terraform  
Installation of terraform v1.11.4 successful. To make this your default version, run 'tfenv use 1.11.4'


Configuration
-------------
tim@Tims-MBP ~ % ls -l ~/.terraform-version
ls: /Users/tim/.terraform-version: No such file or directory
tim@Tims-MBP ~ % tfenv list
  1.11.4
* 1.9.5 (set by /Users/tim/.tfenv/version)
  1.8.5
  1.5.7
tim@Tims-MBP ~ % tfenv use 1.11.4
Switching default version to v1.11.4
Default version (when not overridden by .terraform-version or TFENV_TERRAFORM_VERSION) is now: 1.11.4
tim@Tims-MBP ~ % tfenv version-name
1.11.4
tim@Tims-MBP eks-deployment % ls ~/.tfenv/versions
1.11.4	1.5.7	1.8.5	1.9.5
tim@Tims-MBP eks-deployment % cat ~/.tfenv/version
1.11.4

Execution
---------
tim@Tims-MBP eks-deployment % terraform version 
Terraform v1.11.3
on darwin_amd64
+ provider registry.terraform.io/hashicorp/aws v5.94.1
+ provider registry.terraform.io/hashicorp/cloudinit v2.3.6
+ provider registry.terraform.io/hashicorp/kubernetes v2.36.0
+ provider registry.terraform.io/hashicorp/null v3.2.3
+ provider registry.terraform.io/hashicorp/time v0.13.0
+ provider registry.terraform.io/hashicorp/tls v4.0.6

