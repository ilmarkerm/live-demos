terraform {
    required_version = ">= 1.13"
    required_providers {
        vault = {
            source = "hashicorp/vault"
            version = ">= 5.3.0"
        }
    }
}

provider "vault" {
    address = "http://localhost:8200"
    # Set VAULT_TOKEN environment variable
    # Set VAULT_ADDR environment variable
}
