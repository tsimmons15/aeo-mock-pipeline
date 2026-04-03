param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Timestamp
)

$ErrorActionPreference = "Stop"

$Project  = "aeo-demo-dev"
$Location = "us-east1"
$Repo     = "aeo-demo-ingestion"
<<<<<<< HEAD
$Image    = "demo-dataflow-ingestion"
$Tag      = "v$Timestamp"

$RegistryHost = "$Location-docker.pkg.dev"
$ImagePath    = "$RegistryHost/$Project/$Repo/$Image"
$Versioned    = "${ImagePath}:$Tag"
$Latest       = "${ImagePath}:latest"

gcloud auth configure-docker $RegistryHost --quiet

docker build -t $Versioned .

docker push $Versioned

$NewestTag = gcloud artifacts docker images list $ImagePath `
  --project=$Project `
  --include-tags `
  --filter="tags:*" `
  --sort-by="~UPDATE_TIME" `
  --limit=1 `
  --format="get(tags)" |
  ForEach-Object { $_.Split(',')[0].Trim() }

if (-not $NewestTag) {
    throw "No tagged image versions found for $ImagePath"
}

$LatestImage = "${ImagePath}:latest"

Write-Host "Promoting $Versioned -> $LatestImage"

gcloud artifacts docker tags add `
  $Versioned `
  $LatestImage `
  --project=$Project
=======
$Tag      = "v$Timestamp"

$RegistryHost = "$Location-docker.pkg.dev"
$RepoPath     = "$RegistryHost/$Project/$Repo"

gcloud auth configure-docker $RegistryHost --quiet

foreach ($PipelineType in @("batch", "streaming")) {
    $ImageName = "demo-dataflow-$PipelineType"
    $ImagePath = "$RepoPath/$ImageName"
    $Versioned = "${ImagePath}:$Tag"

    Write-Host "Building $PipelineType image: $Versioned"

    docker build --build-arg PIPELINE_TYPE=$PipelineType -t $Versioned .

    docker push $Versioned

    $NewestTag = gcloud artifacts docker images list $ImagePath `
      --project=$Project `
      --include-tags `
      --filter="tags:*" `
      --sort-by="~UPDATE_TIME" `
      --limit=1 `
      --format="get(tags)" |
      ForEach-Object { $_.Split(',')[0].Trim() }

    if (-not $NewestTag) {
        throw "No tagged image versions found for $ImagePath"
    }

    $LatestImage = "${ImagePath}:latest"
    Write-Host "Promoting $Versioned -> $LatestImage"

    gcloud artifacts docker tags add `
      $Versioned `
      $LatestImage `
      --project=$Project
}
>>>>>>> release/terraform
