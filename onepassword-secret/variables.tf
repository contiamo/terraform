variable "vault_name" {
  description = "Name of the 1Password vault (not needed if vault_id is provided)"
  type        = string
  default     = null
}

variable "vault_id" {
  description = "UUID of the 1Password vault (skips vault lookup if provided)"
  type        = string
  default     = null
}

variable "item_name" {
  description = "Title of the 1Password item (not needed if item is provided)"
  type        = string
  default     = null
}

variable "item" {
  description = "Pre-fetched 1Password item data object (skips both vault and item lookups). Pass the entire data.onepassword_item resource."
  type        = any
  default     = null
}

variable "field" {
  description = "Field label to extract for the 'value' output (optional if only using all_fields output)"
  type        = string
  default     = null
}

variable "section" {
  description = "Section label containing the field (set to null to search all sections)"
  type        = string
  default     = "tf-friendly"
}
