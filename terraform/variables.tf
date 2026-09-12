variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "environment" {
  type    = string
  default = "staging"
}
variable "cluster_name" {
  type    = string
  default = "toggle-master"
}
variable "academy_mode" {
  type        = bool
  default     = true
  description = "Use the pre-existing AWS Academy LabRole instead of creating IAM roles."
}
variable "lab_role_name" {
  type    = string
  default = "LabRole"
}
variable "vpc_cidr" {
  type    = string
  default = "10.42.0.0/16"
}
variable "database_username" {
  type    = string
  default = "togglemaster"
}
variable "database_password" {
  type        = string
  sensitive   = true
  description = "Use TF_VAR_database_password or a secret manager, never commit this value."
  validation {
    condition     = length(var.database_password) >= 8 && var.database_password != "set-with-TF_VAR_database_password" && !strcontains(var.database_password, "/") && !strcontains(var.database_password, "@") && !strcontains(var.database_password, "\"") && !strcontains(var.database_password, " ") && can(regex("^[[:print:]]+$", var.database_password))
    error_message = "database_password must contain at least 8 printable characters and cannot contain /, @, double quotes, or spaces."
  }
}
variable "secret_values" {
  type        = map(string)
  sensitive   = true
  default     = {}
  description = "Application secrets written to Secrets Manager. Keys: AUTH_DB_URL, FLAGS_DB_URL, REDIS_URL, MASTER_KEY, SERVICE_API_KEY."
}
