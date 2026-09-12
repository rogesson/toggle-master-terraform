# Terraform

The default `academy_mode = true` reads the existing `LabRole` and does not create IAM roles or policies. For a personal AWS account set it to `false`; Terraform then creates the EKS and node roles.

The state backend is S3 with encryption and native lockfile support. Replace `REPLACE_WITH_TERRAFORM_STATE_BUCKET` in `versions.tf` before `terraform init` and create that bucket first. Never commit `terraform.tfvars` or secret values.

```bash
export TF_VAR_database_password='use-a-secret-manager-value'
terraform -chdir=terraform init
terraform -chdir=terraform plan -var-file=terraform.tfvars
terraform -chdir=terraform apply -var-file=terraform.tfvars
```

The EKS and PostgreSQL versions are intentionally not hardcoded. AWS Academy retires versions by region; omitting them makes AWS select a currently supported default in the configured region.
