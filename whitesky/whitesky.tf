terraform {
  required_providers {
    portal-whitesky-cloud = {
      source  = "portal-whitesky-cloud/portal-whitesky-cloud"
      version = "~> 2.0"
    }
  }
}

provider "portal-whitesky-cloud" {
  client_jwt = var.client_jwt
}


# data "portal-whitesky-cloud_cloudspace" "cs" {
#   customer_id   = var.customer_id
#   cloudspace_id = var.cs_id
# }

# Get network ID:
data "portal-whitesky-cloud_external_network" "external_network"{
   customer_id = var.customer_id
   location    = var.location
   name        = "Internet"
}

resource "portal-whitesky-cloud_cloudspace" "cloudspace" {
  customer_id         = var.customer_id
  location            = var.location
  name                = "contiamo-cloudspace"
  private_network     = "192.168.100.0/24"
  external_network_id = data.portal-whitesky-cloud_external_network.external_network.id
  private             = false
}
# Get image name:
data "portal-whitesky-cloud_image" "image"{
  most_recent = true
  name_regex  = "(?i).*\\.?ubuntu.*20.04$"
  customer_id = var.customer_id
  location    = var.location
}

# Definition of the vm to be created with the settings defined in variables:
resource "portal-whitesky-cloud_machine" "mymachine" {
  customer_id   = var.customer_id
  cloudspace_id = portal-whitesky-cloud_cloudspace.cloudspace.id
  image_id      = data.portal-whitesky-cloud_image.image.image_id
  disk_size     = var.disksize
  name          = "contiamo-tf-test"
  description   = var.vm_description
  userdata      = var.userdata
  vcpus         = var.cpu
  memory        = var.memory
}

resource "portal-whitesky-cloud_port_forwarding" "ssh" {
  customer_id   = var.customer_id
  cloudspace_id = portal-whitesky-cloud_cloudspace.cloudspace.id
  public_port   = 22
  vm_id         = portal-whitesky-cloud_machine.mymachine.id
  local_port    = 22
  protocol      = "tcp"
}
# output "public_ip" {
#   value = portal-whitesky-cloud_machine.mymachine.public_ips
# }
