pid_file = "/home/oracle/vault/vault.pid"

vault {
    address = "http://vault:8200"
}

auto_auth {
    method {
        type = "approle"
        mount_path  = "auth/approle"
        config = {
            role_id_file_path                   = "/home/oracle/vault/.roleid"
            secret_id_file_path                 = "/home/oracle/vault/.secretid"
            #secret_id_response_wrapping_path    = "{{ vault_proxy_secretid_path }}"
            remove_secret_id_file_after_reading = false
        }
    }

    sink {
       type = "file"
       config = {
           path = "/home/oracle/vault/.vault_token"
           mode = 0600
       }
    }
}

listener "tcp" {
    address = "127.0.0.1:8200"
    tls_disable = true
}

listener "unix" {
    address = "/home/oracle/vault/vault.sock"
    socket_mode = "0660"
    socket_user = "oracle"
    socket_group = "oinstall"
    tls_disable = true
}

api_proxy {
    # This always uses the auto_auth token when communicating with Vault server, even if client does not send a token
    use_auto_auth_token = true
}
