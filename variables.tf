variable channel_name {
    type = string
    description = "Name of the Slack channel to create."
}
variable channel_topic {
    type = string
    description = "Topic of the Slack channel to create."
}

variable channel_members {
  type = list(string)
  description = "List of Slack usernames that should be added to the new Slack channel."
}
locals {
    channel_member_set = toset(var.channel_members)
}
