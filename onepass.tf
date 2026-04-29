terraform {
  required_providers {
    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 1.0.1"
    }
  }
}

provider "onepassword" {
  url = "https://contiamo.1password.com/"
}

