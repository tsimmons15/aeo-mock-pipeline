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

$TemplateBasePath = "gs://aeo-dataflow-staging/templates"

$TemplateFilePath = @{
    batch     = "$TemplateBasePath/aeo-batch-ingestion/v2/dataflow_template"
    streaming = "$TemplateBasePath/aeo-streaming-ingestion/v2/dataflow_template"
}

$MaxWorkers = @{ batch = 20; streaming = 10 }
$NumWorkers = @{ batch = 4;  streaming = 2  }

$StagingLocation = "gs://aeo-dataflow-staging"
$TempLocation    = "gs://aeo-dataflow-staging/tmp"

$InputPrefix     = "gs://aeo-raw-landing-data/raw/aeo"
$BqStagingDataset = "retail_staging"
$DeadletterTable  = "retail_staging.deadletter"

$PubSubProject      = $ProjectId
$StreamingBqDataset = "retail_staging"

$AeoTransformsVersion = "1.0.0"

$Network    = $null
$Subnetwork = $null
# ======================

# Per-job routing tables — must match pipeline code
$BatchDatasets = @("orders", "returns", "inventory_snapshots", "product_dim")

$StreamingGroups = @("browse", "cart", "commerce", "returns", "inventory")

# Subscription name per event group — must match Terraform google_pubsub_subscription resource names
$StreamingSubscriptions = @{
    browse    = "aeo-events-browse-sub"
    cart      = "aeo-events-cart-sub"
    commerce  = "aeo-events-commerce-sub"
    returns   = "aeo-events-returns-sub"
    inventory = "aeo-events-inventory-sub"
}

$BaseLabels = @(
    "app=aeo-ingestion",
    "pipeline-type=$PipelineType",
    "env=dev",
    "aeo-transforms-version=$AeoTransformsVersion"
)

function Invoke-DataflowJob {
    param(
        [string]$JobName,
        [string]$ParameterString,
        [string[]]$ExtraLabels
    )

    $Labels = ($BaseLabels + $ExtraLabels) -join ","

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
        "--parameters=$ParameterString",
        "--additional-user-labels=$Labels"
    )

    if ($FlexRS)      { $cmd += "--flexrs-goal=$FlexRS" }
    if ($Network)     { $cmd += "--network=$Network" }
    if ($Subnetwork)  { $cmd += "--subnetwork=$Subnetwork" }

    Write-Host ""
    Write-Host "Launching: $JobName"
    Write-Host "  Parameters: $ParameterString"

    & gcloud @cmd
}

#####################################################################
# Script start
#####################################################################

$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

if ($PipelineType -eq "batch") {

    foreach ($Dataset in $BatchDatasets) {
        $JobName = "aeo-batch-ingest-$($Dataset.Replace('_','-'))-$Timestamp"

        $Params = @(
            "project=$ProjectId",
            "input_prefix=$InputPrefix",
            "dataset=$Dataset",
            "bq_dataset=$BqStagingDataset",
            "deadletter_table=$DeadletterTable"
        ) -join ","

        Invoke-DataflowJob `
            -JobName        $JobName `
            -ParameterString $Params `
            -ExtraLabels    @("dataset=$($Dataset.Replace('_','-'))")
    }

} elseif ($PipelineType -eq "streaming") {

    foreach ($Group in $StreamingGroups) {
        $Subscription = $StreamingSubscriptions[$Group]
        $JobName = "aeo-stream-ingest-$Group-$Timestamp"

        $Params = @(
            "project=$ProjectId",
            "subscription=$Subscription",
            "event_group=$Group",
            "bq_dataset=$StreamingBqDataset",
            "deadletter_table=$DeadletterTable"
        ) -join ","

        Invoke-DataflowJob `
            -JobName         $JobName `
            -ParameterString $Params `
            -ExtraLabels     @("event-group=$Group")
    }
}