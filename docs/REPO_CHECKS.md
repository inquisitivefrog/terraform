# Repo checks: what runs, where it lives, and what the tools do

## Where the checks live

| What | Location | When it runs |
|---|---|---|
| Pre-commit hook | `scripts/git-hooks/pre-commit` | On your machine, every `git commit` |
| tflint configs | `aws/.tflint.hcl`, `gcp/.tflint.hcl`, `azure/.tflint.hcl` | Hook and Action (scan job) |
| GitHub Action | `.github/workflows/repo-checks.yml` | On GitHub, every push and pull request |
| Accepted old findings | `.gitleaksignore` | Read by gitleaks in both places |
| Ignore rules | `.gitignore` | Whenever git decides what to track |

Both run the same checks:

1. **No tracked files that `.gitignore` excludes**, such as `terraform.tfvars`,
   state, saved plans, logs or `*.pem`. This is the check that would have
   caught the prod tfvars being committed.
2. **No secrets** in what's being added: private keys, AWS access key IDs, and
   anything else gitleaks recognizes. The hook scans staged changes; the
   Action scans all of history.
3. **`terraform fmt`**: Terraform files are formatted.
4. **Scanners, report only** (print findings, never block yet):
   - pre-commit hook: tflint and trivy, for each cloud (`aws`, `gcp`,
     `azure`) with staged `.tf` changes; skipped if the tool isn't installed.
   - GitHub Action `scan` job: tflint, trivy and checkov for every cloud.
   Make a scanner blocking once its findings are fixed or accepted. Install
   and run them locally: `aws/README.aws.test.md`.

## Setup on a new clone (once)

Hooks in `.git/hooks/` are never pushed, so each clone has to point git at
the hooks stored in the repo:

```sh
git config core.hooksPath scripts/git-hooks
brew install gitleaks          # optional; the hook skips gitleaks if missing
```

Check it's set: `git config --get core.hooksPath` should print
`scripts/git-hooks`.

## Day to day

- A blocked commit prints the reason and the fix. Fix it, `git add`, and
  commit again.
- Skip the hook once with `git commit --no-verify`. The GitHub Action will
  still check the push.
- Check by hand at any time:
  ```sh
  git ls-files -ci --exclude-standard     # tracked files that should be ignored; empty = good
  gitleaks git . --redact                 # secrets anywhere in history
  terraform fmt -check -recursive .       # formatting
  ```
- Results of the Action are on GitHub under the repo's **Actions** tab.

## `.gitleaksignore`

Lists 4 findings in 2025 commits: AWS access key IDs pasted into driftctl
notes, redacted in `05f08e1`. That key was deleted, and neither current
access key appears in history (checked 2026-10-16). Each line is a
fingerprint (`commit:file:rule:line`), so only those exact findings are
ignored. Add a line only for a finding you've confirmed is harmless.

## Cheat sheet: Terraform and security tools

The checks above deliberately use only git, gitleaks and terraform. Your
2025 setup, `aws/single_instance/.pre-commit-config.yaml`, used the tools
below through the `pre-commit` framework. That config is no longer installed
(the old hook pointed at a virtualenv on the Intel MacBook; see
`.git/hooks/pre-commit.old-macbook`). Notes from learning each one are in
`aws/single_instance/docs/README.Terraform_*.txt`.

| Tool | What it does, in one line | Kind | Status (Oct 2026) |
|---|---|---|---|
| **pre-commit** | Framework that downloads and runs other checks before each commit, configured in `.pre-commit-config.yaml` | Runner | Not installed; replaced here by a plain bash hook |
| **terraform fmt** | Rewrites `.tf` files into standard formatting | Formatter | Built into terraform; in these checks |
| **terraform validate** | Checks syntax, types and references without contacting AWS | Correctness | Built in; run it per directory |
| **tflint** | Linter: catches mistakes validate misses, like invalid instance types or unused variables (one `.tflint.hcl` per cloud) | Lint | Installed 0.64.0 (GitHub release; not in Homebrew core); hook + Action, report only |
| **tfsec** | Scans Terraform for insecure settings, like unencrypted buckets or open security groups | Security | Merged into trivy; use trivy |
| **trivy** | Aqua Security scanner: Terraform misconfigurations (tfsec's checks), container images, and dependencies with known vulnerabilities. Accepted findings: inline `# trivy:ignore:<ID> <why>` | Security | Installed 0.76.1; hook + Action, report only |
| **checkov** | Another IaC security scanner (Prisma Cloud) with its own large rule set; overlaps with trivy | Security | Installed 3.3.20; Action only (slow), report only |
| **gitleaks** | Finds secrets (keys, tokens, passwords) in files and git history | Secrets | Installed; in these checks |
| **detect-private-key / detect-aws-credentials** | Small hooks from `pre-commit-hooks` that look for keys in staged files | Secrets | Covered by the bash hook and gitleaks |
| **terraform-docs** | Generates the input/output tables in each module's `README.md` from its variables and outputs | Docs | Not installed; the READMEs predate recent changes |
| **driftctl** | Compared Terraform state with what actually exists in AWS, to find drift | Drift | Archived upstream; use `terraform plan -refresh-only` |
| **tfenv** | Installs and switches between Terraform versions | Version manager | Not used; Homebrew terraform is current |

Rule of thumb: **fmt / validate / tflint** check whether the code is
correct, **trivy / checkov** check whether it's secure, **gitleaks** checks
whether you're leaking secrets, and **terraform plan -refresh-only** checks
whether AWS still matches state.

First scan (2026-10-21) and what's left to fix before making the scanners
blocking: `aws/README.aws.test.md`, "First scan".
