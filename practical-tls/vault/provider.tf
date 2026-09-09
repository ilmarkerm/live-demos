terraform {
    required_version = ">= 1.16"
    required_providers {
        vault = {
            source = "hashicorp/vault"
            version = ">= 5.11.0"
        }
    }
}

provider "vault" {
    address = "http://vault:8200"
    token = "demo123"
}
