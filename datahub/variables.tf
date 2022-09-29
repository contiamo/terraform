variable "datahub_namespace" {
  description = "Datahub namespace"
  default = "datahub-tf"
}

variable "ui_ingress_host" {
  description = "Datahub frontend ingress host"
  default = "datahub-tf.example.com"
}
variable "api_ingress_host" {
  description = "Datahub API ingress host"
  default = "datahub-tf-api.example.com"
}
variable "ingress_class" {
  description = "Ingress class"
  default = "nginx"
}
