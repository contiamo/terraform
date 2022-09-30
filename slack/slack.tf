terraform {
  required_providers {
    slack = {
      source  = "pablovarela/slack"
      version = "~> 1.0"
    }
  }
  required_version = ">= 0.13"
}

data "slack_user" "user" {
  for_each = local.channel_member_set
  email = each.key
}

resource "slack_conversation" "terraform-channel" {
  name = var.channel_name
  topic             = var.channel_topic
  permanent_members = [for user in data.slack_user.user : user.id]
  is_private        = false
}

output "channel_name" {
  value = var.channel_name
}