#!/bin/sh
# RunPod worker status for an LB endpoint. Id from $1 or $ENDPOINT_ID.
set -eu
ID=${1:-${ENDPOINT_ID:-zbvtollsf5emjd}}
runpodctl serverless get "$ID"
echo "==== health ===="
runpodctl serverless health "$ID"
if [ "${LOGS:-}" = "1" ]; then
  echo "==== logs ===="
  runpodctl serverless logs "$ID"
fi
