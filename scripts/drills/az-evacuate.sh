#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <cluster-name> <availability-zone>" >&2
  exit 1
fi

CLUSTER_NAME="$1"
AVAILABILITY_ZONE="$2"

NODEGROUPS=$(aws eks list-nodegroups --cluster-name "$CLUSTER_NAME" --query 'nodegroups[]' --output text)

for NG in $NODEGROUPS; do
  echo "Draining nodes in $NG within $AVAILABILITY_ZONE" >&2
  NODES=$(aws eks describe-nodegroup --cluster-name "$CLUSTER_NAME" --nodegroup-name "$NG" --query 'nodegroup.instances[] | [?availabilityZone==`'"$AVAILABILITY_ZONE"'`].instanceId' --output text)
  for NODE in $NODES; do
    kubectl drain "$NODE" --ignore-daemonsets --delete-emptydir-data --force || true
  done
  aws eks update-nodegroup-config --cluster-name "$CLUSTER_NAME" --nodegroup-name "$NG" --scaling-config minSize=0,desiredSize=0,maxSize=0
  echo "Scaled nodegroup $NG to zero in $AVAILABILITY_ZONE" >&2
done
