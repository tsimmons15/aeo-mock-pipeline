@echo off
REM Hardcoded root for this env
set TF_DIR=terraform/envs/dev

if "%~1"=="" (
  echo Usage: %~nx0 ^<action^> [extra terraform args...]
  exit /b 1
)

set ACTION=%1
shift

terraform -chdir=%TF_DIR% %ACTION% %*
