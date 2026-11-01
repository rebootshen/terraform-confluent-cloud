terraform {
  /*
  cloud {
    workspaces {
      name = "learn-terraform-confluent-provider"
    }
  }
  */
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "~> 2.0"
    }
  }
  required_version = ">=1.2"
}