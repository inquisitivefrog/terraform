# Test and scan tools for aws/

How to install the tools that check this repo's Terraform, and how to run
them. Companion to `../docs/REPO_CHECKS.md` (what runs on commit and in the
GitHub Action) and `README.aws.md` (aws CLI commands).

| Tool | What it checks | Installed with |
|---|---|---|
| terraform | `fmt`, `validate`, `plan` | Homebrew |
| tflint | Lint: mistakes `validate` misses (bad instance types, unused variables) | GitHub release (not in Homebrew core) |
| trivy | Security misconfigurations (tfsec's checks live here now) | Homebrew |
| gitleaks | Secrets in files and git history | Homebrew |
| checkov | A second security scanner with its own rules | pip, from the requirements file |
| pre-commit | Runner for the 2025 hook config | pip, from the requirements file |

## 1. Homebrew tools

```sh
brew install terraform trivy gitleaks
terraform version; trivy --version; gitleaks version
```

If any name is unknown, Homebrew installs none of them, so check each one
installed.

**tflint** isn't in Homebrew core any more (2026); install the release
binary from GitHub and verify its checksum:

```sh
cd /tmp
gh release download v0.64.0 --repo terraform-linters/tflint \
  -p 'tflint_darwin_arm64.zip' -p 'checksums.txt'          # latest: gh release view --repo terraform-linters/tflint
grep tflint_darwin_arm64.zip checksums.txt | shasum -a 256 -c -   # must print OK
unzip -o tflint_darwin_arm64.zip -d /opt/homebrew/bin
tflint --version
```

`brew install checkov` also works, but pulls in gcc, OpenBLAS and its own
Python; the virtualenv below is lighter.

## 2. Python tools in a virtualenv

`aws/single_instance/python3/requirements.txt` is a `pip freeze` from the
2025 setup (Python 3.11; checkov 3.2.383, pre-commit 4.2.0, boto3, yamllint,
...). Homebrew's default `python3` is now 3.14, which some of those pinned
versions don't support, so build the virtualenv with Python 3.12:

```sh
brew install python@3.12                     # if `python3.12` isn't found
python3.12 -m venv ~/.venvs/sre-terraform    # outside the repo, so git never sees it
source ~/.venvs/sre-terraform/bin/activate
pip install --upgrade pip
pip install -r aws/single_instance/python3/requirements.txt
checkov --version; pre-commit --version
deactivate                                   # when done
```

Run `source ~/.venvs/sre-terraform/bin/activate` again in each new shell
before using checkov or pre-commit. If a pinned package fails to build,
install just the tools instead: `pip install checkov pre-commit yamllint`.

## 3. Running them

Each cloud has its own tflint config at its top level (`aws/.tflint.hcl`,
`gcp/.tflint.hcl`, `azure/.tflint.hcl`), so run the scanners from there:

```sh
cd aws            # or gcp, azure

# tflint: downloads the ruleset named in .tflint.hcl (once), then lints every root and module
tflint --init --config "$PWD/.tflint.hcl"
tflint --recursive --config "$PWD/.tflint.hcl"

# trivy: Terraform misconfigurations
trivy config --severity MEDIUM,HIGH,CRITICAL .

# checkov
checkov -d . --framework terraform --compact --quiet

# terraform, per root (no backend needed for validate)
cd single_instance/environments/dev && terraform init -backend=false && terraform validate
```

Accepted trivy findings are marked in the code, next to the resource, with
the reason: `# trivy:ignore:<ID> <why>` (for example the EKS public
endpoint, limited to the laptop's /32). Accepted tflint rules are disabled
in the cloud's `.tflint.hcl` with a comment (for example
`azurerm_resources_missing_prevent_destroy`).

The pre-commit hook runs tflint and trivy in report-only mode for each cloud
with staged `.tf` changes; the GitHub Action's `scan` job runs all three for
every cloud, also report only. See `../docs/REPO_CHECKS.md`.

## First scan, 2026-10-21

| Scope | tflint | trivy (MEDIUM+) | checkov failed |
|---|---|---|---|
| aws/single_instance | 0 (was 38) | 10 MEDIUM (was also 2 CRITICAL, accepted) | 24 |
| aws/tfstate | 0 (was 4) | 0 | 0 |
| aws/ecommerce-k8s | 40 | not run | not run |
| gcp | 0 | 0 HIGH (2 accepted) | 29 |
| azure | 0 (16 of a disabled rule) | 16 MEDIUM (6 CRITICAL accepted) | 56 |

## Notes

- `aws/.tflint.hcl` pins `tflint-ruleset-aws` 0.49.0; the 2025 pin, 0.50.0,
  was never released. GCP uses `tflint-ruleset-google` 0.40.0, Azure
  `tflint-ruleset-azurerm` 0.32.0.
- `aws/single_instance/trivy.yaml` used to report MEDIUM only, hiding HIGH
  and CRITICAL; it now reports all three. `aws/single_instance/.trivyignore`
  is trivy's sample file (example CVEs), not real exceptions.
- `.pre-commit-config.yaml` is the 2025 hook setup and points at absolute
  paths on the old Intel MacBook; the repo now uses
  `scripts/git-hooks/pre-commit` instead (see `../docs/REPO_CHECKS.md`).
- Installed on this laptop (2026-10-21): terraform, gitleaks 8.30.1, tflint
  0.64.0, trivy 0.76.1, checkov 3.3.20 (Homebrew; it brought python@3.15,
  which became the default `python3`).
