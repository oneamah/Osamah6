terraform {
  required_version = ">= 1.14.0"
  cloud {
    organization = "marmil"
    workspaces {
      name = "marmil"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

