
param(
  [string]$ProjectId = "$(gcloud config get-value project)",
  [string]$Account = "",
  [string]$Region = "us-central1",
  [string]$BqLocation = "US",
  [string]$CdfInstance = "taller1-cdf",
  [string]$BqDataset = "retail_curated",
  [string]$Bucket = "$env:USERNAME-taller1-raw"
)
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $here
if ($Account -ne "") { gcloud config set account $Account | Out-Null }
if ($ProjectId -eq "") { throw "ProjectId is empty" }
gcloud config set project $ProjectId | Out-Null
gcloud services enable cloudbuild.googleapis.com | Out-Null
$pn = (gcloud projects describe $ProjectId --format="value(projectNumber)").Trim()
$sa = "$pn@cloudbuild.gserviceaccount.com"
foreach ($role in @("roles/datafusion.admin","roles/dataproc.editor","roles/storage.admin","roles/bigquery.admin","roles/serviceusage.serviceUsageAdmin")) {
  gcloud projects add-iam-policy-binding $ProjectId --member "serviceAccount:$sa" --role $role | Out-Null
}
$subs = "_REGION=$Region,_BQ_LOCATION=$BqLocation,_CDF_INSTANCE=$CdfInstance,_BQ_DATASET=$BqDataset,_BUCKET=$Bucket"
gcloud builds submit "$here" --config "$here\cloudbuild.yaml" --substitutions $subs

