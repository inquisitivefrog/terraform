# tflint config for aws/ (run: cd aws && tflint --init && tflint --recursive --config "$PWD/.tflint.hcl")
config {
  call_module_type = "local"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "aws" {
  enabled = true
  version = "0.49.0" # 0.50.0, pinned in 2025, was never released
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}
