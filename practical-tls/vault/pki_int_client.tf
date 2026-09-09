locals {
  max_client_cert_validity = 86400 # 1d
}

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

resource "vault_pki_secret_backend_role" "database_user" {
  backend = vault_mount.pki_int.path
  issuer_ref = vault_pki_secret_backend_issuer.intermediate-client-2026.issuer_ref
  name    = "database_user"
  ttl = local.max_client_cert_validity
  max_ttl = local.max_client_cert_validity
  key_type = "rsa"
  key_bits = 4096

  # Certificate usage
  server_flag = false
  client_flag = true
  email_protection_flag = false
  code_signing_flag = false

  # CN validations
  allowed_domains = [
      # Allow only OIDC email in CN field
      #"{{identity.entity.aliases.${data.vault_auth_backend.oidc.accessor}.name}}",
      # DEMO only: allow only specific value for common name
      "demouser1",
  ]
  allowed_domains_template = true
  allow_localhost = false
  allow_bare_domains = true
  allow_glob_domains = false
  allow_any_name = false
  allow_wildcard_certificates = false
  allow_subdomains = false
  enforce_hostnames = false
  require_cn = true
}
