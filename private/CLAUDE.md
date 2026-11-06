# CLAUDE.md: private cloud (kind on this laptop)

The repo-wide rules in [../CLAUDE.md](../CLAUDE.md) apply too. Status and
the resume steps: [docs/STATUS.md](docs/STATUS.md).

## Running the lab

- Kubernetes calls go through `scripts/private_env.sh` (`use_cluster
  datastore-dev`, then `k`), which uses `~/.kube/kind-datastore-dev` and
  context `kind-datastore-dev`.
- After a reboot: start Docker Desktop, then
  `datastore-clusters/platform/scripts/docker_restart.sh` (expect every
  platform and relational check to pass).
- Runbooks live in `datastore-clusters/relational/scripts/runbook_*.sh`,
  share `runbook_lib.sh`, log to `datastore-clusters/relational/logs/`, and
  are judged against `datastore-clusters/test_plans/`. Commit a run's log
  only when it passed; `-FAILED` logs stay uncommitted.
- A paste from the user may be missing: read the newest file in
  `relational/logs/` before asking whether a run happened.

## Safety

- **Never edit a script while the user is running it**: bash reads a
  script as it goes. Check `pgrep -fl runbook_` first.
- **No load, backup or runbook while the Mac is busy**: HandBrake, ffmpeg,
  yt-dlp, torrents or a busy VPN starve the Docker VM and skew every
  number (2026-11-02 crash loops; 2026-11-05 +35% CPU per row).
- Never run `docker volume prune` or `docker system prune --volumes`:
  the cluster's data and the backup store live in Docker volumes.
- The backup store's encryption key
  (`~/.config/datastore-dev/backup-store/security.toml`) must never be
  replaced: every stored backup would become unreadable.
- Object lock on the backup buckets is COMPLIANCE mode: a locked version
  cannot be deleted early by anyone. Confirm before locking anything.
- Never print the Grafana admin password or any generated database
  password in chat or logs.
