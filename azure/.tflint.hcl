# tflint config for azure/ (run: cd azure && tflint --init && tflint --recursive --config "$PWD/.tflint.hcl")
config {
  call_module_type = "local"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "azurerm" {
  enabled = true
  version = "0.32.0"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

# These environments are built and destroyed routinely; prevent_destroy would
# block every terraform destroy. Data is protected by soft delete and purge
# protection (Key Vault) and versioning (storage) instead.
rule "azurerm_resources_missing_prevent_destroy" {
  enabled = false
}
