variable "vault_name" {
  description = "Name of the 1Password vault"
  type        = string
}

variable "item_name" {
  description = "Title of the 1Password item"
  type        = string
}

variable "field" {
  description = "Field label to extract"
  type        = string
}

variable "section" {
  description = "Section label containing the field (set to null to search all sections)"
  type        = string
  default     = "tf-friendly"
}
