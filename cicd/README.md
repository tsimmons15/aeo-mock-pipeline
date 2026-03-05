# Terraform runner wrappers

Probably useless wrappers, but I decided to add them because why not?

## Usage

Powershell:
```powershell
.\run-terra.ps1 init
.\run-terra.ps1 plan -var-file="terraform.tfvars"
.\run-terra.ps1 apply -auto-approve
```

Batch:
```batch
run-terra.bat init
run-terra.bat plan -var-file="terraform.tfvars"
run-terra.bat apply -auto-approve
```

```bash
./run-terra.sh init
./run-terra.sh plan -var-file="terraform.tfvars"
./run-terra.sh apply -auto-approve
```