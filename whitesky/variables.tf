variable "client_jwt" {
  type        = string
  description = "JWT token for Whitesky Portal API. Set by running: export TF_VAR_client_jwt=[your token]"
}

variable "location" {
  type = string
  description = "Whitesky Cloud location"
  default = "nl-rmd-dc01-001"
}

variable "customer_id" {
    type = string
    description = "Whitesky Cloud customer ID"
    default = "contiamo_1"
}

variable "disksize" {
  type = string
  description = "Disk size in GB"
  default = "60"
}

variable "cpu" {
  type = string
  description = "Number of CPUs"
  default = "1"
}

variable "memory" {
  type = string
  description = "Memory in MB"
  default = "2048"
}

variable "vm_description" {
  type = string
  description = "VM description"
  default = "Contiamo VM"
}

variable "userdata" {
  description = "user data"
  default = "users: [{name: contiamo, shell: /bin/bash, ssh-authorized-keys: [ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAtRJUE/tohBsCph6OKs0IZ4GkWIB7NLoav7ZZ1PODj2]}]"
}