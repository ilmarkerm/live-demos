resource "vault_auth_backend" "approle" {
    type = "approle"
    description = "Allow apps to authenticate with Vault-defined roles"
    tune {
        default_lease_ttl = "1h"
        max_lease_ttl = "24h"
    }
}

# Policy for Vault Proxy approle
resource "vault_policy" "proxy" {
    name = "proxy_policy"
    # NB! * and + do not work like regexp!!!!
    policy = <<-EOT
        path "auth/approle/login" {
            capabilities = ["create","read"]
        }
        path "secret/data/*" {
            capabilities = ["read","create","update","patch","list"]
        }
        path "demokv/data/oracle/*" {
            capabilities = ["read","create","update","patch","list"]
        }
        path "database/creds/*" {
            capabilities = ["read"]
        }
        path "ssh-client-signer/sign/oracle" {
            capabilities = ["create","update","patch"]
        }
    EOT
}

# Create a new approle 
resource "vault_approle_auth_backend_role" "proxy" {
    backend = vault_auth_backend.approle.path
    role_name = "demo-proxy"
    secret_id_ttl = 28800 # The number of seconds after which any SecretID expires.
    secret_id_num_uses = 0 # The number of times any particular SecretID can be used to fetch a token from this AppRole, after which the SecretID will expire.
    secret_id_bound_cidrs = [
        # blocks of IP addresses which can perform the login operation.
        "0.0.0.0/0",
    ]
    ### 
    token_bound_cidrs = [
        # From which IP addresses the resulting token can be used from
        "0.0.0.0/0",
    ]
    token_policies = [
        # Policies attached to the generated token
        vault_policy.proxy.name,
    ]
    token_ttl = 3600
    token_max_ttl = 28800
}
