param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Region,

    [Parameter(Mandatory = $true, Position = 1)]
    [ValidateSet("batch", "streaming")]
    [string]$PipelineType,

    [Parameter(Mandatory = $false, Position = 2)]
    [string]$FlexRS = $null,

    [Parameter(Mandatory = $false, Position = 3)]
    [string]$WorkerMachineType = "n4-standard-2"
)

$ErrorActionPreference = "Stop"

# ===== EDIT THESE =====
$ProjectId           = "aeo-demo-dev"
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
)
# ======================

$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$JobName   = "aeo-$PipelineType-ingestion-$Region-$Timestamp"

$Parameters = @(
    "input=$InputLocation",
    "output=$OutputLocation"
) -join ","

$cmd = @(
    "dataflow", "flex-template", "run", $JobName,
    "--project=$ProjectId",
    "--template-file-gcs-location=$($TemplateFilePath[$PipelineType])",
    "--region=$Region",
    "--service-account-email=$ServiceAccountEmail",
    "--num-workers=$($NumWorkers[$PipelineType])",
    "--max-workers=$($MaxWorkers[$PipelineType])",
    "--worker-machine-type=$WorkerMachineType",
    "--staging-location=$StagingLocation",
    "--temp-location=$TempLocation",
    "--parameters=$Parameters",
    "--additional-user-labels=$($Labels -join ',')"
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

Write-Host "Launching $PipelineType job: $JobName"
Write-Host "Region: $Region"
Write-Host "Template: $($TemplateFilePath[$PipelineType])"
Write-Host "Workers: $($NumWorkers[$PipelineType]) initial / $($MaxWorkers[$PipelineType]) max"
Write-Host "Machine type: $WorkerMachineType"
if ($FlexRS) { Write-Host "FlexRS: $FlexRS" }

& gcloud @cmd