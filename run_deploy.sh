#!/usr/bin/env bash
set -euo pipefail
PROJECT_ID="${PROJECT_ID:-$(gcloud config get-value project)}"
REGION="${REGION:-us-central1}"
BQ_LOCATION="${BQ_LOCATION:-US}"
CDF_INSTANCE="${CDF_INSTANCE:-taller1-cdf}"
BQ_DATASET="${BQ_DATASET:-retail_curated}"
BUCKET="${BUCKET:-${USER}-taller1-raw}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
gcloud config set project "${PROJECT_ID}" >/dev/null
gcloud services enable cloudbuild.googleapis.com >/dev/null
PN="$(gcloud projects describe "${PROJECT_ID}" --format="value(projectNumber)")"
SA="${PN}@cloudbuild.gserviceaccount.com"
for role in roles/datafusion.admin roles/dataproc.editor roles/storage.admin roles/bigquery.admin roles/serviceusage.serviceUsageAdmin; do
  gcloud projects add-iam-policy-binding "${PROJECT_ID}" --member="ServiceAccount:${SA}" --role="${role}" >/dev/null || true
done
gcloud builds submit "${here}" --config "${here}/cloudbuild.yaml" \
  --substitutions "_REGION=${REGION},_BQ_LOCATION=${BQ_LOCATION},_CDF_INSTANCE=${CDF_INSTANCE},_BQ_DATASET=${BQ_DATASET},_BUCKET=${BUCKET}"

