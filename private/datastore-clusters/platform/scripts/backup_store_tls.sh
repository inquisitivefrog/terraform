#!/usr/bin/env bash
# Make the backup store's TLS certificate, so backups cross to it encrypted
# (https). A private certificate authority (CA) of our own signs it: the
# store is reached by names no public CA will certify (host.docker.internal,
# localhost). Clients trust that CA only (the clusters get its certificate;
# the laptop's scripts pass it to curl).
#   ~/.config/datastore-dev/backup-store-ca/ca.key   the CA's private key:
#        signs certificates; never mounted anywhere, never in the repo
#   ~/.config/datastore-dev/backup-store/ca.crt      the CA's certificate
#        (public): what clients trust
#   ~/.config/datastore-dev/backup-store/tls.{crt,key}   the store's
#        certificate and private key, mounted read-only into the store
# The certificate names host.docker.internal (pods), localhost and 127.0.0.1
# (the laptop), and lasts 397 days; the CA 10 years. Keeps existing files;
# --renew issues the store a new certificate and key from the same CA
# (clients need nothing new) and restarts the store if it runs.
# Usage: private/datastore-clusters/platform/scripts/backup_store_tls.sh [--renew]
# docs/BACKUPS.md, "Where the keys are".

set -euo pipefail
DIR="$HOME/.config/datastore-dev/backup-store"
CA_DIR="$HOME/.config/datastore-dev/backup-store-ca"
STORE=datastore-backups
umask 077
mkdir -p "$DIR" "$CA_DIR"
chmod 700 "$DIR" "$CA_DIR"

if [[ ! -f "$CA_DIR/ca.key" ]]; then
  openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes -days 3650 \
    -subj "/CN=datastore-dev backup store CA" \
    -addext "basicConstraints=critical,CA:TRUE" -addext "keyUsage=critical,keyCertSign,cRLSign" \
    -keyout "$CA_DIR/ca.key" -out "$CA_DIR/ca.crt" 2>/dev/null
  echo "Made the CA: $CA_DIR/ca.key (private), ca.crt"
fi
install -m 644 "$CA_DIR/ca.crt" "$DIR/ca.crt"

if [[ -f "$DIR/tls.crt" && "${1:-}" != --renew ]]; then
  echo "Certificate exists: $DIR/tls.crt, $(openssl x509 -in "$DIR/tls.crt" -noout -enddate) (--renew to replace it)"
  exit 0
fi

tmp="$(mktemp -d "$DIR/.tls.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
openssl req -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes -subj "/CN=datastore-backups" \
  -keyout "$tmp/tls.key" -out "$tmp/tls.csr" 2>/dev/null
printf '%s\n' "subjectAltName=DNS:host.docker.internal,DNS:localhost,IP:127.0.0.1" \
  "keyUsage=critical,digitalSignature" "extendedKeyUsage=serverAuth" "basicConstraints=critical,CA:FALSE" >"$tmp/ext"
openssl x509 -req -in "$tmp/tls.csr" -CA "$CA_DIR/ca.crt" -CAkey "$CA_DIR/ca.key" -CAcreateserial \
  -CAserial "$CA_DIR/ca.srl" -days 397 -extfile "$tmp/ext" -out "$tmp/tls.crt" 2>/dev/null
openssl verify -CAfile "$CA_DIR/ca.crt" "$tmp/tls.crt" >/dev/null
mv "$tmp/tls.key" "$DIR/tls.key"
mv "$tmp/tls.crt" "$DIR/tls.crt"
echo "Issued $DIR/tls.crt: $(openssl x509 -in "$DIR/tls.crt" -noout -enddate), for host.docker.internal, localhost, 127.0.0.1"

if [[ "$(docker inspect -f '{{.State.Running}}' "$STORE" 2>/dev/null)" == true ]]; then
  docker restart "$STORE" >/dev/null
  echo "Restarted $STORE with the new certificate"
fi
