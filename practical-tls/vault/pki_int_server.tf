locals {
  max_server_cert_validity = 5184000 # 60d
  server_domain = "practical-tls_demo-net"
}

resource "vault_pki_secret_backend_intermediate_cert_request" "intermediate-server-2026" {
  backend     = vault_mount.pki_int.path
  type        = "internal"
  common_name = "PracticalTLS-SERVER-2026"
  key_type    = "rsa"
  key_bits    = 4096
  key_name    = "intermediateserver2026"
}

resource "vault_pki_secret_backend_root_sign_intermediate" "intermediate-server-2026" {
  backend               = vault_mount.pki_root.path
  csr                   = vault_pki_secret_backend_intermediate_cert_request.intermediate-server-2026.csr
  common_name           = vault_pki_secret_backend_intermediate_cert_request.intermediate-server-2026.common_name
  issuer_ref            = vault_pki_secret_backend_issuer.root2026.issuer_ref
  exclude_cn_from_sans  = true
  ou                    = local.pki_ou
  organization          = local.pki_org
  ttl                   = local.pki_intermediate_validity_2026
  permitted_dns_domains = [local.server_domain]
}

resource "vault_pki_secret_backend_intermediate_set_signed" "intermediate-server-2026" {
  backend     = vault_mount.pki_int.path
  certificate = vault_pki_secret_backend_root_sign_intermediate.intermediate-server-2026.certificate
}

resource "vault_pki_secret_backend_issuer" "intermediate-server-2026" {
  backend     = vault_mount.pki_int.path
  issuer_ref  = vault_pki_secret_backend_intermediate_set_signed.intermediate-server-2026.imported_issuers[0]
  issuer_name = "intermediate-server-issuer-2026"
}

resource "vault_pki_secret_backend_role" "database_server" {
  backend = vault_mount.pki_int.path
  name    = "database_server"
  allowed_domains = [local.server_domain]
  ttl = local.max_server_cert_validity
  max_ttl = local.max_server_cert_validity
  allow_ip_sans = true
  key_type = "rsa"
  key_bits = 4096
  allow_localhost = false
  allow_bare_domains = false
  allow_glob_domains = false
  allow_wildcard_certificates = false
  allow_subdomains = true
  # enforce_hostnames should be set to true beyond this demo
  enforce_hostnames = false
  server_flag = true
  client_flag = true
  email_protection_flag = false
  code_signing_flag = false
  require_cn = true
  issuer_ref = vault_pki_secret_backend_issuer.intermediate-server-2026.issuer_ref
}
