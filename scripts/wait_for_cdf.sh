#!/usr/bin/env bash
set -euo pipefail
REGION="${1:?region}"
INSTANCE="${2:?instance}"
echo "Waiting for Data Fusion instance '$INSTANCE' in region '$REGION' to be RUNNING..."
for i in {1..60}; do
  STATE=$(gcloud beta data-fusion instances describe "$INSTANCE" --location="$REGION" --format="value(state)" || true)
  echo "  Attempt $i: state=$STATE"
  if [[ "$STATE" == "RUNNING" ]]; then
    echo "Instance is RUNNING."; exit 0
  fi
  sleep 20
done
echo "ERROR: Data Fusion instance did not reach RUNNING state in time."; exit 1

