# Github Workflows
This directory contains several pieces

## GitFlow Guard
Contains the logic for protecting repository branches
### Branch Rules
- Protected branch names:
    - dev/*
    - release/*
    - main
    - dev/* can be merged into release/*
    - release/* can be merged into main
    - Other branches in any other format can be created, worked with as normal.

The rules are enforced on pull request and are enforced in Github via Branch rules (via the Settings -> Branches -> Rules, not Settings -> Rules -> Branch rule).

## Terraform
Contains the logic for deployment via terraform
terraform-plan.yml will only execute on pushes as a test for validity.

terraform.yml actually applies the changes.