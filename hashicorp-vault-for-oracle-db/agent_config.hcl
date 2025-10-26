vault {
    address = "http://vault:8200"
}

# If false, will keep running in the background and renewing secrets when needed
exit_after_auth = true

template_config {
    static_secret_render_interval = "10m"
    exit_on_retry_failure = true
    max_connections_per_host = 10
}

template {
    source      = "/live-demos/hashicorp-vault-for-oracle-db/agent_app1.ctmpl"
    destination = "/tmp/agent_app1.config"
    error_on_missing_key = true
    exec {
        command = ["touch", "/tmp/restart_app1"]
        timeout = "30s"
    }
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
}
