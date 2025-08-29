#!/usr/bin/env bash
set -euo pipefail

REGION="${1:?region}"
INSTANCE="${2:?instance}"
PIPELINE_NAME="${3:-Caso2}"
PIPELINE_FILE="${4:-datafusion/pipeline.json}"

# 1) Endpoint de CDAP y token
ENDPOINT=$(gcloud beta data-fusion instances describe "$INSTANCE" --location="$REGION" --format="value(apiEndpoint)")
TOKEN="$(gcloud auth print-access-token)"

# 2) Archivo con el bucket resuelto (lo crea el step del Cloud Build)
RESOLVED="/workspace/pipeline_resolved.json"
if [[ ! -f "$RESOLVED" ]]; then
  if [[ -f "$PIPELINE_FILE" ]]; then
    RESOLVED="$PIPELINE_FILE"
  else
    echo "Pipeline file not found: $PIPELINE_FILE"; exit 1
  fi
fi

# 3) Usar la versión de la instancia como artifact.version (robusto y compatible)
ARTIFACT_VER="$(gcloud beta data-fusion instances describe "$INSTANCE" --location="$REGION" --format="value(version)")"
if [[ -z "$ARTIFACT_VER" ]]; then
  echo "Could not resolve Data Fusion instance version."; exit 1
fi
echo "Using artifact cdap-data-pipeline version: ${ARTIFACT_VER}"

# 4) Construir AppRequest
APPREQ="/workspace/appreq.json"
if grep -q '"artifact"' "$RESOLVED" && grep -q '"config"' "$RESOLVED"; then
  # Ya es AppRequest → úsalo tal cual (no intentar reescribir artifact; evita romper si hay slashes)
  cp "$RESOLVED" "$APPREQ"
else
  # No es AppRequest → envolver como AppRequest estándar
  {
    echo -n '{"name":"'"${PIPELINE_NAME}"'","artifact":{"name":"cdap-data-pipeline","version":"'"${ARTIFACT_VER}"'","scope":"SYSTEM"},"config":'
    cat "$RESOLVED"
    echo '}'
  } > "$APPREQ"
fi

# 5) Deploy y mostrar cuerpo en caso de error
RESP_FILE="/workspace/appresp.txt"
HTTP_CODE=$(curl -s -o "$RESP_FILE" -w "%{http_code}" -X PUT \
  "${ENDPOINT}/v3/namespaces/default/apps/${PIPELINE_NAME}" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  --data-binary @"${APPREQ}")

echo "Deploy pipeline HTTP ${HTTP_CODE}"
if [[ "${HTTP_CODE}" != "200" && "${HTTP_CODE}" != "204" ]]; then
  echo "---- Response Body ----"
  head -c 4000 "$RESP_FILE" || true
  echo
  exit 1
fi

echo "Pipeline deployed."