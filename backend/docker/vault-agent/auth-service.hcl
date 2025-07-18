vault {
  address = "http://vault:8200"
  retry {
    num_retries = 5
  }
}

auto_auth {
  method "approle" {
    mount_path = "auth/approle"
    config = {
      role_id_file_path = "/vault/writable-config/role-id"
      secret_id_file_path = "/vault/writable-config/secret-id"
    }
  }

  sink "file" {
    config = {
      path = "/vault/token"
    }
  }
}

template {
  source      = "/vault/templates/database.tpl"
  destination = "/vault/secrets/database.json"
  perms       = 0644
  wait {
    min = "2s"
    max = "10s"
  }
}

template {
  source      = "/vault/templates/auth-service-config.tpl"
  destination = "/vault/secrets/auth-config.json"
  perms       = 0644
  wait {
    min = "2s"
    max = "10s"
  }
}

template {
  source      = "/vault/templates/ssl-cert.tpl"
  destination = "/vault/secrets/cert.pem"
  perms       = 0644
  wait {
    min = "2s"
    max = "10s"
  }
}

template {
  source      = "/vault/templates/ssl-key.tpl"
  destination = "/vault/secrets/key.pem"
  perms       = 0644  # Change from 0600 to 0644
  wait {
    min = "2s"
    max = "10s"
  }
}

template {
  source      = "/vault/templates/ca-cert.tpl"
  destination = "/vault/secrets/ca.pem"
  perms       = 0644
  wait {
    min = "2s"
    max = "10s"
  }
}