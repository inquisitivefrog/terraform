#!/bin/bash

docker start datastore-dev-control-plane
docker start datastore-dev-worker datastore-dev-worker2 datastore-dev-worker3

sleep 60

cd ~/Documents/workspace/sre/terraform/private/datastore-clusters
platform/scripts/check_resources.sh
relational/scripts/check_resources.sh

