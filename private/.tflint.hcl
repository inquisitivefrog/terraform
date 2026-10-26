# tflint config for private/ (run: cd private && tflint --init && tflint --recursive --config "$PWD/.tflint.hcl")
# No cloud ruleset: private/ uses the kind, helm and kubernetes providers only.
config {
  call_module_type = "local"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}
