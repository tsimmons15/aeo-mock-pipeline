param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Region,

    [Parameter(Mandatory = $false, Position = 1)]
    [string]$FlexRS = $null,

    [Parameter(Mandatory = $false, Position = 2)]
    [string]$WorkerMachineType = "n4-standard-2"
)

$ErrorActionPreference = "Stop"

# ===== EDIT THESE =====
$ProjectId           = "aeo-demo-dev"
$TemplateFileGcsPath = "gs://aeo-dataflow-staging/templates/aeo-ingestion-template/v2/dataflow_template"
$ServiceAccountEmail = "dataflow-runner@aeo-demo-dev.iam.gserviceaccount.com"
$Image               = "us-east1-docker.pkg.dev/aeo-demo-dev/aeo-demo-ingestion/demo-dataflow-ingestion:latest"

$MaxWorkers          = 20
$NumWorkers          = 1

$StagingLocation     = "gs://aeo-dataflow-staging"
$TempLocation        = "gs://aeo-dataflow-staging/tmp"

# These names must match your Flex Template metadata / pipeline parameters.
$InputLocation       = "gs://aeo-raw-landing-data/*"
$OutputLocation      = "gs://aeo-dataflow-staging/output/"

# Optional network settings. Leave $null if you do not use them.
$Network             = $null
$Subnetwork          = $null

# Optional labels.
$Labels = @(
    "app=aeo-ingestion",
    "env=dev"
)
# ======================

$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$JobName   = "aeo-ingestion-$Region-$Timestamp"

$Parameters = @(
    "input=$InputLocation",
    "output=$OutputLocation",
    "sdk_location=container",
    "sdk_container_image=$Image"
) -join ","

$cmd = @(
    "dataflow", "flex-template", "run", $JobName,
    "--project=$ProjectId",
    "--template-file-gcs-location=$TemplateFileGcsPath",
    "--region=$Region",
    "--service-account-email=$ServiceAccountEmail",
    "--num-workers=$NumWorkers",
    "--max-workers=$MaxWorkers",
    "--launcher-machine-type=$WorkerMachineType",
    "--worker-machine-type=$WorkerMachineType",
    "--staging-location=$StagingLocation",
    "--temp-location=$TempLocation",
    "--parameters=$Parameters",
    "--additional-user-labels=$($Labels -join ',')",
    "--additional-pipeline-options=$additionalPipelineOptions"
)

if ($FlexRS) {
    $cmd += "--flexrs-goal=$FlexRS"
}

if ($Network) {
    $cmd += "--network=$Network"
}

if ($Subnetwork) {
    $cmd += "--subnetwork=$Subnetwork"
}

Write-Host "Launching job: $JobName"
Write-Host "Region: $Region"
Write-Host "Worker machine type: $WorkerMachineType"
if ($FlexRS) {
    Write-Host "Using FlexRS: $FlexRS"
}

& gcloud @cmd
