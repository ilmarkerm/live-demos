resource "vault_mount" "pki_int" {
    path = "pki_int"
    type = "pki"
    description = "This is the intermediary PKI"
    default_lease_ttl_seconds = 3600
    max_lease_ttl_seconds = 31622400 # 366 days
}

resource "vault_pki_secret_backend_intermediate_cert_request" "intermediate-client-2026" {
  backend     = vault_mount.pki_int.path
  type        = "internal"
  common_name = "PracticalTLS-CLIENT-2026"
  key_type    = "rsa"
  key_bits    = 4096
  key_name    = "intermediateclient2026"
}

resource "vault_pki_secret_backend_root_sign_intermediate" "intermediate-client-2026" {
  backend               = vault_mount.pki_root.path
  csr                   = vault_pki_secret_backend_intermediate_cert_request.intermediate-client-2026.csr
  common_name           = vault_pki_secret_backend_intermediate_cert_request.intermediate-client-2026.common_name
  issuer_ref            = vault_pki_secret_backend_issuer.root2026.issuer_ref
  exclude_cn_from_sans  = true
  ou                    = local.pki_ou
  organization          = local.pki_org
  ttl                   = local.pki_intermediate_validity_2026
  #permitted_dns_domains = ["*"]
}

resource "vault_pki_secret_backend_intermediate_set_signed" "intermediate-client-2026" {
  backend     = vault_mount.pki_int.path
  certificate = vault_pki_secret_backend_root_sign_intermediate.intermediate-client-2026.certificate
}

resource "vault_pki_secret_backend_issuer" "intermediate-client-2026" {
  backend     = vault_mount.pki_int.path
  issuer_ref  = vault_pki_secret_backend_intermediate_set_signed.intermediate-client-2026.imported_issuers[0]
  issuer_name = "intermediate-client-issuer-2026"
}
