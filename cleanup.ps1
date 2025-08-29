
param(
  [string]$ProjectId = "$(gcloud config get-value project)",
  [string]$Region = "us-central1",
  [string]$CdfInstance = "taller1-cdf",
  [string]$Bucket = "$env:USERNAME-taller1-raw",
  [string]$BqDataset = "retail_curated"
)
$ErrorActionPreference = "SilentlyContinue"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $here
gcloud config set project $ProjectId | Out-Null
Write-Host "Deleting Data Fusion instance if exists..." -ForegroundColor Yellow
gcloud beta data-fusion instances delete $CdfInstance --location $Region --quiet
Write-Host "Deleting GCS bucket if exists..." -ForegroundColor Yellow
gsutil -m rm -r "gs://$Bucket"
Write-Host "Deleting BigQuery dataset if exists..." -ForegroundColor Yellow
bq rm -r -f -d $BqDataset
Write-Host "Cleanup done."

