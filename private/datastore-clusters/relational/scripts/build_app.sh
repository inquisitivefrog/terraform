#!/bin/bash
# Build the orders image and load it into the kind cluster's nodes (no
# registry: kind nodes take images straight from the laptop's Docker).
# The tag is the pom version: bump it for every change, or the Deployment
# (imagePullPolicy IfNotPresent) keeps running the old image.
#
# Usage: build_app.sh [--test]   (--test: run the Testcontainers tests first)

set -euo pipefail
CLUSTER="datastore-dev"
APP="$(cd "$(dirname "$0")/../app/orders" && pwd)"

if [[ "${1:-}" == "--test" ]]; then
  (cd "$APP" && mvn -q test)
  echo "Tests passed."
fi

VERSION="$(sed -n 's:^  <version>\(.*\)</version>:\1:p' "$APP/pom.xml" | head -1)"
IMAGE="orders:$VERSION"
docker build -q -t "$IMAGE" "$APP"
kind load docker-image "$IMAGE" --name "$CLUSTER"
echo "Loaded $IMAGE into every node of $CLUSTER"
