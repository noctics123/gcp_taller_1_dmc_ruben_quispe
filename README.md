# Taller 1 – GCP para Ingeniería de Datos

> **Marca de agua**: **Ruben Dario Quispe Vilca**

---

## 📇 Metadatos
- **Nombre**: Ruben Quispe  
- **Centro de Estudios**: DMC  
- **Curso**: GCP para ingeniería de datos - Brangovich Ordoñez  
- **Versión**: 1.0  
- **Fecha**: 29/08/2025

---

## 🧾 Resumen
Este repositorio despliega de forma **automática** una instancia de **Cloud Data Fusion (Basic)**, crea un **bucket** en GCS, un **dataset** en **BigQuery** y **despliega/ejecuta** el pipeline *Caso2*.  
El despliegue se realiza con **Cloud Build** usando `cloudbuild.yaml` y scripts auxiliares.

---

## 🗂️ Estructura del repositorio
```
.
├─ cloudbuild.yaml               # Pipeline de Cloud Build (idempotente)
├─ data/                         # Archivos de datos de ejemplo
│  ├─ customers.txt
│  ├─ orders.csv
│  ├─ products.csv
│  └─ promotions.json
├─ datafusion/
│  └─ pipeline.json             # Pipeline en formato AppRequest (CDAP)
├─ scripts/
│  ├─ wait_for_cdf.sh           # Espera a que CDF esté RUNNING
│  ├─ deploy_pipeline.sh        # Despliega el pipeline vía REST
│  └─ start_pipeline.sh         # Dispara una ejecución del pipeline
├─ bq/
│  └─ curated_sales_schema.json # (Opcional) esquema explícito para la tabla
├─ run_deploy.ps1               # *One-click* deploy (Windows/PowerShell)
├─ cleanup.ps1                  # Limpieza total (Windows/PowerShell)
├─ run_deploy.sh                # *One-click* deploy (Linux/macOS)
└─ cleanup.sh                   # Limpieza total (Linux/macOS)
```

---

## ✅ Prerrequisitos
- **Proyecto GCP** con **facturación** habilitada.
- **gcloud CLI** autenticado: `gcloud auth login`
- Permisos para: *Cloud Build, Data Fusion, BigQuery, Storage, Service Usage.*
- (Opcional) **VS Code** como entorno de trabajo.

---

## 🚀 Despliegue (Windows / VS Code)
En una terminal PowerShell ubicada en la carpeta del repo:

```powershell
# Reemplaza el ProjectId por el tuyo si aplica
powershell -ExecutionPolicy Bypass -File .\run_deploy.ps1 -ProjectId taller-1-gcp-ruben
```

El script:
1. Establece el proyecto y habilita **Cloud Build**.
2. Concede roles necesarios a la SA de Cloud Build.
3. Ejecuta `gcloud builds submit` con sustituciones por defecto:
   - `_REGION=us-central1`
   - `_BQ_LOCATION=US`
   - `_CDF_INSTANCE=taller1-cdf`
   - `_BQ_DATASET=retail_curated`
   - `_BUCKET=$Env:USERNAME-taller1-raw`

> Los pasos son idempotentes: si el bucket/dataset/instancia existe, continúa sin fallar.

---

## ▶️ Volver a ejecutar el pipeline (sin redeploy)
```powershell
$REGION   = "us-central1"
$INSTANCE = "taller1-cdf"
$ENDPOINT = (gcloud beta data-fusion instances describe $INSTANCE --location $REGION --format "value(apiEndpoint)")
$TOKEN    = (gcloud auth print-access-token)

# Dispara la ejecución
Invoke-WebRequest -Method Post `
  -Uri "$ENDPOINT/v3/namespaces/default/apps/Caso2/workflows/DataPipelineWorkflow/start" `
  -Headers @{Authorization="Bearer $TOKEN"} `
  -Body "{{}}" -ContentType "application/json"
```

---

## 🔎 Verificación en BigQuery
```powershell
bq ls retail_curated
bq query --use_legacy_sql=false "SELECT COUNT(*) AS rows FROM `retail_curated.curated_sales`"
bq query --use_legacy_sql=false "SELECT * FROM `retail_curated.curated_sales` LIMIT 10"
```

---

## 🧹 Limpiar recursos (empezar de cero)
> **¡Cuidado!** borra la instancia CDF, el bucket y el dataset.

```powershell
powershell -ExecutionPolicy Bypass -File .\cleanup.ps1 -ProjectId taller-1-gcp-ruben
```

---

## 🧠 Notas técnicas
- Data Fusion se maneja con **`gcloud beta data-fusion`** y `--edition=basic`.
- El deploy a CDAP usa **AppRequest** (artifact `cdap-data-pipeline` con versión de la instancia).
- `cloudbuild.yaml` añade un paso `chmod` para evitar `Permission denied` en scripts.
- Rutas GCS de las fuentes se parametrizan con `$\{{_BUCKET}}` y se resuelven en build.

---

## 🛠️ Solución de problemas comunes
- **409 Bucket exists**: es esperado; el paso continúa.
- **Instancia CDF se queda en CREATING**: verificar APIs habilitadas y billing.
- **HTTP 400 en deploy (schema)**: asegurar que `BigQuerySink.properties.schema` sea JSON Avro válido. Este repo ya lo incluye correcto.
- **Permisos**: confirmar que la SA de Cloud Build tenga *datafusion.admin, bigquery.admin, storage.admin, serviceusage.serviceUsageAdmin, dataproc.editor*.

---

## © Autor
**Ruben Quispe** — *DMC*  
*Marca de agua*: **Ruben Dario Quispe Vilca**

> Este README fue generado para el curso **“GCP para ingeniería de datos - Brangovich Ordoñez”**.  
> Versión **1.0** – 29/08/2025
