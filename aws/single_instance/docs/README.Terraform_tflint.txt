
Docs
----
1. https://github.com/terraform-linters/tflint/blob/master/docs/user-guide/README.md
2. https://github.com/terraform-linters/tflint/blob/master/docs/developer-guide/README.md

Installation
------------
tim@Tims-MBP single_instance % brew install tflint
==> Downloading https://formulae.brew.sh/api/formula.jws.json
==> Downloading https://formulae.brew.sh/api/cask.jws.json
Warning: tflint 0.55.1 is already installed and up-to-date.
To reinstall 0.55.1, run:
  brew reinstall tflint
tim@Tims-MBP single_instance % which tflint
/usr/local/bin/tflint
tim@Tims-MBP single_instance % tflint --version
TFLint version 0.55.1
+ ruleset.terraform (0.10.0-bundled)

Configure
---------
tim@Tims-MBP single_instance % cat <<EOF > .tflint.hcl
plugin "aws" {
  enabled = true
  version = "0.33.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}
EOF
tim@Tims-MBP single_instance % cat .tflint.hcl 
plugin "aws" {
  enabled = true
  version = "0.33.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}
tim@Tims-MBP single_instance % tflint --init
Installing "aws" plugin...
Installed "aws" (source: github.com/terraform-linters/tflint-ruleset-aws, version: 0.33.0)

tim@Tims-MBP single_instance % vi tflint-wrapper.sh
tim@Tims-MBP single_instance % chmod 755 tflint-wrapper.sh 
tim@Tims-MBP single_instance % cat tflint-wrapper.sh 
tflint_output=$(tflint 2>&1); if [ -z "$tflint_output" ]; then echo "No issues found"; else echo "$tflint_output"; fi
tim@Tims-MBP single_instance % echo 'alias tflint="$HOME/Documents/workspace/sre/terraform/aws/single_instance/tflint-wrapper.sh"' >> ~/.zshrc
tim@Tims-MBP single_instance % source ~/.zshrc


Execution
---------
tim@Tims-MBP single_instance % tflint
No issues found
tim@Tims-MBP single_instance % tflint
4 issue(s) found:

Warning: Missing version constraint for provider "random" in `required_providers` (terraform_required_providers)

  on main.tf line 26:
  26: resource "random_string" "suffix" {

Reference: https://github.com/terraform-linters/tflint-ruleset-terraform/blob/v0.10.0/docs/rules/terraform_required_providers.md

Warning: [Fixable] variable "ami" is declared but not used (terraform_unused_declarations)

  on variables.tf line 4:
   4: variable "ami" {

tim@Tims-MBP single_instance % tflint --init --force
All plugins are already installed

tim@Tims-MBP single_instance % tflint --format=compact
4 issue(s) found:

main.tf:26:1: Warning - Missing version constraint for provider "random" in `required_providers` (terraform_required_providers)
variables.tf:4:1: Warning - variable "ami" is declared but not used (terraform_unused_declarations)
variables.tf:22:1: Warning - variable "employer" is declared but not used (terraform_unused_declarations)
variables.tf:58:1: Warning - variable "tfstate_bucket" is declared but not used (terraform_unused_declarations)

tim@Tims-MBP single_instance % tflint --loglevel=debug
Failed to parse CLI options; --loglevel option was removed in v0.40.0. Please set TFLINT_LOG environment variables instead

tim@Tims-MBP single_instance % TFLINT_LOG=debug tflint
15:07:43 config.go:177: [INFO] Load config: .tflint.hcl
15:07:43 config.go:334: [DEBUG] Config loaded
15:07:43 config.go:335: [DEBUG]   CallModuleType: local
15:07:43 config.go:336: [DEBUG]   CallModuleTypeSet: false
15:07:43 config.go:337: [DEBUG]   Force: false
15:07:43 config.go:338: [DEBUG]   ForceSet: false
15:07:43 config.go:339: [DEBUG]   DisabledByDefault: false
15:07:43 config.go:340: [DEBUG]   DisabledByDefaultSet: false
15:07:43 config.go:341: [DEBUG]   PluginDir: 
15:07:43 config.go:342: [DEBUG]   PluginDirSet: false
15:07:43 config.go:343: [DEBUG]   Format: 
15:07:43 config.go:344: [DEBUG]   FormatSet: false
15:07:43 config.go:345: [DEBUG]   Varfiles: 
15:07:43 config.go:346: [DEBUG]   Variables: 
15:07:43 config.go:347: [DEBUG]   Only: 
15:07:43 config.go:348: [DEBUG]   IgnoreModules:
15:07:43 config.go:352: [DEBUG]   Rules:
15:07:43 config.go:356: [DEBUG]   Plugins:
15:07:43 config.go:358: [DEBUG]     aws: enabled=true, version=0.33.0, source=github.com/terraform-linters/tflint-ruleset-aws
15:07:43 config.go:463: [INFO] The "terraform" plugin block is not found. Enable the plugin "terraform" automatically
...

