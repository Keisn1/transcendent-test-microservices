# Vault server configuration
storage "file" {
  path = "/vault/data"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}

# API address that Vault will bind to
api_addr = "http://0.0.0.0:8200"

# Cluster address (for HA, not used in this example)
cluster_addr = "http://0.0.0.0:8201"

# UI configuration
ui = true

# Disable mlock (for Docker - not recommended for production)
disable_mlock = true

# Log level
log_level = "Info"

# Default lease time
default_lease_ttl = "168h"    # 7 days
max_lease_ttl = "720h"        # 30 days