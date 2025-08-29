#!/usr/bin/env bash
set -euo pipefail
PROJECT_ID="${PROJECT_ID:-$(gcloud config get-value project)}"
REGION="${REGION:-us-central1}"
CDF_INSTANCE="${CDF_INSTANCE:-taller1-cdf}"
BUCKET="${BUCKET:-${USER}-taller1-raw}"
BQ_DATASET="${BQ_DATASET:-retail_curated}"
gcloud config set project "${PROJECT_ID}" >/dev/null
gcloud beta data-fusion instances delete "${CDF_INSTANCE}" --location "${REGION}" --quiet || true
gsutil -m rm -r "gs://${BUCKET}" || true
bq rm -r -f -d "${BQ_DATASET}" || true
echo "Cleanup done."

