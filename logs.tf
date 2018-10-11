# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE LOGS GROUP
# ---------------------------------------------------------------------------------------------------------------------

module "logs" {
  source = "./modules/monitoring/aws/logs"

  name              = "log_group"
  environment       = "production"
  retention_in_days = 30
}
