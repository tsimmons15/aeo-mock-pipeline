param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Action,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args
)

# Hardcoded root for this env
$tfDir = "terraform/envs/dev"

terraform -chdir=$tfDir $Action @Args
