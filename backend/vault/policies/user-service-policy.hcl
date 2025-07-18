# Policy for user service
# Allow reading database credentials
path "secret/data/database" {
  capabilities = ["read"]
}

# Allow reading user service specific secrets
path "secret/data/user-service/*" {
  capabilities = ["read"]
}

# Allow creating certificates for user service
path "pki_int/issue/microservice-role" {
  capabilities = ["create", "update"]
}

# Allow reading CA certificate
path "pki_int/ca/pem" {
  capabilities = ["read"]
}

# Allow reading root CA certificate
path "pki/ca/pem" {
  capabilities = ["read"]
}

# Allow token renewal
path "auth/token/renew-self" {
  capabilities = ["update"]
}

# Allow looking up own token
path "auth/token/lookup-self" {
  capabilities = ["read"]
}
