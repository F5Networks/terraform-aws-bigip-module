terraform {
  required_version = ">= 0.13"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">4.26.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">2.3.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">2.1.2"
    }
  }
}