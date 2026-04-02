param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Region,

<<<<<<< HEAD
    [Parameter(Mandatory = $false, Position = 1)]
    [string]$FlexRS = $null,

    [Parameter(Mandatory = $false, Position = 2)]
=======
    [Parameter(Mandatory = $true, Position = 1)]
    [ValidateSet("batch", "streaming")]
    [string]$PipelineType,

    [Parameter(Mandatory = $false, Position = 2)]
    [string]$FlexRS = $null,

    [Parameter(Mandatory = $false, Position = 3)]
>>>>>>> release/terraform
    [string]$WorkerMachineType = "n4-standard-2"
)

$ErrorActionPreference = "Stop"

# ===== EDIT THESE =====
$ProjectId           = "aeo-demo-dev"
<<<<<<< HEAD
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
=======
$ServiceAccountEmail = "dataflow-runner@aeo-demo-dev.iam.gserviceaccount.com"

$TemplateBasePath    = "gs://aeo-dataflow-staging/templates"

# Separate template GCS paths per job type — each pipeline builds its own Flex Template spec
$TemplateFilePath = @{
    batch     = "$TemplateBasePath/aeo-batch-ingestion/v2/dataflow_template"
    streaming = "$TemplateBasePath/aeo-streaming-ingestion/v2/dataflow_template"
}

$MaxWorkers = @{ batch = 20; streaming = 10 }
$NumWorkers = @{ batch = 4;  streaming = 2  }

$StagingLocation = "gs://aeo-dataflow-staging"
$TempLocation    = "gs://aeo-dataflow-staging/tmp"

$InputLocation  = "gs://aeo-raw-landing-data/*"
$OutputLocation = "gs://aeo-dataflow-staging/output/"

# Shared library version — used as a label for traceability, not passed to pip (that's in the image)
$AeoTransformsVersion = "1.0.0"

$Network    = $null
$Subnetwork = $null

$Labels = @(
    "app=aeo-ingestion",
    "pipeline-type=$PipelineType",
    "env=dev",
    "aeo-transforms-version=$AeoTransformsVersion"
>>>>>>> release/terraform
)
# ======================

$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
<<<<<<< HEAD
$JobName   = "aeo-ingestion-$Region-$Timestamp"

$Parameters = @(
    "input=$InputLocation",
    "output=$OutputLocation",
    "sdk_location=container",
    "sdk_container_image=$Image"
=======
$JobName   = "aeo-$PipelineType-ingestion-$Region-$Timestamp"

$Parameters = @(
    "input=$InputLocation",
    "output=$OutputLocation"
>>>>>>> release/terraform
) -join ","

$cmd = @(
    "dataflow", "flex-template", "run", $JobName,
    "--project=$ProjectId",
<<<<<<< HEAD
    "--template-file-gcs-location=$TemplateFileGcsPath",
    "--region=$Region",
    "--service-account-email=$ServiceAccountEmail",
    "--num-workers=$NumWorkers",
    "--max-workers=$MaxWorkers",
    "--launcher-machine-type=$WorkerMachineType",
=======
    "--template-file-gcs-location=$($TemplateFilePath[$PipelineType])",
    "--region=$Region",
    "--service-account-email=$ServiceAccountEmail",
    "--num-workers=$($NumWorkers[$PipelineType])",
    "--max-workers=$($MaxWorkers[$PipelineType])",
>>>>>>> release/terraform
    "--worker-machine-type=$WorkerMachineType",
    "--staging-location=$StagingLocation",
    "--temp-location=$TempLocation",
    "--parameters=$Parameters",
<<<<<<< HEAD
    "--additional-user-labels=$($Labels -join ',')",
    "--additional-pipeline-options=$additionalPipelineOptions"
=======
    "--additional-user-labels=$($Labels -join ',')"
>>>>>>> release/terraform
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

<<<<<<< HEAD
Write-Host "Launching job: $JobName"
Write-Host "Region: $Region"
Write-Host "Worker machine type: $WorkerMachineType"
if ($FlexRS) {
    Write-Host "Using FlexRS: $FlexRS"
}
=======
Write-Host "Launching $PipelineType job: $JobName"
Write-Host "Region: $Region"
Write-Host "Template: $($TemplateFilePath[$PipelineType])"
Write-Host "Workers: $($NumWorkers[$PipelineType]) initial / $($MaxWorkers[$PipelineType]) max"
Write-Host "Machine type: $WorkerMachineType"
if ($FlexRS) { Write-Host "FlexRS: $FlexRS" }
>>>>>>> release/terraform

& gcloud @cmd
