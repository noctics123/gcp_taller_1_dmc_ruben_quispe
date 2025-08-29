#!/usr/bin/env bash
set -euo pipefail
REGION="${1:?region}"
INSTANCE="${2:?instance}"
PIPELINE_NAME="${3:-Caso2}"
ENDPOINT=$(gcloud beta data-fusion instances describe "$INSTANCE" --location="$REGION" --format="value(apiEndpoint)")
TOKEN="$(gcloud auth print-access-token)"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
  "$ENDPOINT/v3/namespaces/default/apps/${PIPELINE_NAME}/workflows/DataPipelineWorkflow/start" \
  -H "Authorization: Bearer ${TOKEN}" -H "Content-Type: application/json" --data '{}')
echo "Start pipeline HTTP ${HTTP_CODE}"
if [[ "${HTTP_CODE}" != "200" && "${HTTP_CODE}" != "204" ]]; then
  echo "Failed to start pipeline"; exit 1
fi
echo "Pipeline run triggered."

