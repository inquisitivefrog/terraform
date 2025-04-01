#!/bin/bash

tflint_output=$(tflint 2>&1); if [ -z "$tflint_output" ]; then echo "No issues found"; else echo "$tflint_output"; fi

tfsec_output=$(tfsec --config-file tfsec.yml --concise-output 2>&1)
[ -z "$tfsec_output" ] && echo "TFSec: No issues found" || echo "$tfsec_output"
