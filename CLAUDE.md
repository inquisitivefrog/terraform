# CLAUDE.md

Guidance for Claude Code in this repo. What the repo is and where things
live: [README.md](README.md). Where work stands: [NEXT_SESSION.md](NEXT_SESSION.md).

## Working rules

- **Record every change.** Each environment has a rolling record, newest
  first: `aws/tfstate/docs/STATUS.md`, `gcp/tfstate/docs/STATUS.md`,
  `azure/tfstate/docs/STATUS.md`, `private/docs/STATUS.md`. Add an entry for
  every change, apply or test run (what, why, result, log file).
- **Commit and push only after the user confirms** an apply or run works.
  Keep the git log clean: one commit per verified change.
- **The user applies Terraform**; write the change, say what the plan should
  show, then check the result.
- **Repo checks** (`scripts/git-hooks/pre-commit`, `docs/REPO_CHECKS.md`)
  block secrets, ignored files and unformatted Terraform. Never bypass them.
  This repo is public: no passwords, keys or tokens in files or commit
  messages.
- **New tools get a doc**: what it is, why it's used, how to look at it
  (for example `private/datastore-clusters/docs/BACKUPS.md`).
- The deployed resources are throwaway demo data; the value is reproducible
  code and notes. Prefer current best practice and explain it.

## Never touch

- The `grid-meter-app-eks` kubeconfig context or anything it manages.
- The live apps (dairyfarm and grid-meter on GCP, grid-meter on Azure and
  on the original AWS account): never change, stop or destroy them.
- `~/.kube/config`'s current context: every script and Terraform tree names
  its own kubeconfig and context.

Lab-specific rules (the kind cluster on this laptop): [private/CLAUDE.md](private/CLAUDE.md).
