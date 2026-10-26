# PASS/FAIL helpers shared by the private/ check_resources.sh scripts.
#
#   source "$(dirname "$0")/../../../scripts/checks.sh"
#   expect "Nodes Ready" "4" some command ...
#   summary                    # prints totals; exits 1 if anything failed

PASS=0
FAIL=0

pass() {
  echo "  PASS  $1: $2"
  PASS=$((PASS + 1))
}
fail() {
  echo "  FAIL  $1: $2"
  FAIL=$((FAIL + 1))
}

# expect <label> <wanted> <command...>: PASS only if stdout equals <wanted>
expect() {
  local label="$1" want="$2" out
  shift 2
  out="$("$@" 2>/dev/null)"
  if [[ -n "$out" && "$out" == "$want" ]]; then pass "$label" "$out"; else fail "$label" "expected '$want', got '${out:-nothing}'"; fi
}

# match <label> <regex> <command...>: PASS if stdout matches <regex>
match() {
  local label="$1" re="$2" out
  shift 2
  out="$("$@" 2>/dev/null)"
  if [[ -n "$out" && "$out" =~ $re ]]; then pass "$label" "${out//$'\n'/, }"; else fail "$label" "expected /$re/, got '${out:-nothing}'"; fi
}

# refused <label> <command...>: PASS if the command fails (e.g. a connection that must be rejected)
refused() {
  local label="$1" out
  shift
  if out="$("$@" 2>&1)"; then
    fail "$label" "accepted ('${out//$'\n'/ }')"
  else
    pass "$label" "refused ($(echo "$out" | grep -m1 -iE 'reject|insecure|denied|prohibited|error' | cut -c1-90))"
  fi
}

# summary [what]: totals; exit 1 if any check failed
summary() {
  echo
  echo "== Summary: $PASS passed, $FAIL failed =="
  if [[ "$FAIL" -gt 0 ]]; then
    echo "One or more expected resources are missing or misconfigured."
    exit 1
  fi
  echo "All checked ${1:-resources} present and configured."
}
