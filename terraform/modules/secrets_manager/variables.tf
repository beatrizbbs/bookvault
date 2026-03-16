variable "name" {
  description = "Secrets Manager secret name."
  type        = string
}

variable "description" {
  description = "Description for the secret."
  type        = string
  default     = "BookVault application secret"
}

variable "secret_value" {
  description = "Optional secret value. If null, only the secret metadata is created."
  type        = string
  default     = null
  sensitive   = true
  nullable    = true
}

variable "recovery_window_in_days" {
  description = "Recovery window before permanent deletion."
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags applied to secret resources."
  type        = map(string)
  default     = {}
}
