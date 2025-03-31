tflint_output=$(tflint 2>&1); if [ -z "$tflint_output" ]; then echo "No issues found"; else echo "$tflint_output"; fi
