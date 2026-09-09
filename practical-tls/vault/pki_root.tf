locals {
    pki_ou = "Database Department"
    pki_org = "Database Company"
    pki_intermediate_validity_2026 = "365d" # 1 year
}

resource "vault_mount" "pki_root" {
    path = "pki_root"
    type = "pki"
    description = "This is the CA anchor"
    default_lease_ttl_seconds = 3600
    max_lease_ttl_seconds = 316224000 # 10 years
}

resource "vault_pki_secret_backend_root_cert" "root2026" {
    depends_on            = [vault_mount.pki_root]
    backend               = vault_mount.pki_root.path
    type                  = "internal"
    common_name           = "PracticalTLS-Root-2026"
    ttl                   = "3650d" # 10 years
    format                = "pem"
    key_type              = "rsa"
    key_bits              = 4096
    exclude_cn_from_sans  = true
    ou                    = local.pki_ou
    organization          = local.pki_org
}

resource "vault_pki_secret_backend_issuer" "root2026" {
    backend     = vault_pki_secret_backend_root_cert.root2026.backend
    issuer_ref  = vault_pki_secret_backend_root_cert.root2026.issuer_id
    issuer_name = "root-issuer-2026"
}
