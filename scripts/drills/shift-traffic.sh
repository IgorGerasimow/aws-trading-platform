#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <global-accelerator-arn> <from-endpoint-group-region> <to-endpoint-group-region>" >&2
  exit 1
fi

ACCELERATOR_ARN="$1"
FROM_REGION="$2"
TO_REGION="$3"

LISTENER_ARN=$(aws globalaccelerator list-listeners --accelerator-arn "$ACCELERATOR_ARN" --query 'Listeners[0].ListenerArn' --output text)

ENDPOINT_GROUPS=$(aws globalaccelerator list-endpoint-groups --listener-arn "$LISTENER_ARN" --query 'EndpointGroups[*].{Arn:EndpointGroupArn,Region:EndpointGroupRegion}' --output json)

FROM_ARN=$(echo "$ENDPOINT_GROUPS" | jq -r ".[] | select(.Region == \"$FROM_REGION\").Arn")
TO_ARN=$(echo "$ENDPOINT_GROUPS" | jq -r ".[] | select(.Region == \"$TO_REGION\").Arn")

if [[ -z "$FROM_ARN" || -z "$TO_ARN" ]]; then
  echo "Unable to locate endpoint group for regions" >&2
  exit 1
fi

echo "Reducing traffic dial for $FROM_REGION" >&2
aws globalaccelerator update-endpoint-group --endpoint-group-arn "$FROM_ARN" --traffic-dial-percentage 0

echo "Increasing traffic dial for $TO_REGION" >&2
aws globalaccelerator update-endpoint-group --endpoint-group-arn "$TO_ARN" --traffic-dial-percentage 100
