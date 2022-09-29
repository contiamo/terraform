variable "datahub_namespace" {
  description = "Datahub namespace"
}

variable "ui_ingress_host" {
  description = "Datahub frontend ingress host"
}
variable "api_ingress_host" {
  description = "Datahub API ingress host"
}
variable "ingress_class" {
  description = "Ingress class"
  default = "nginx"
}
