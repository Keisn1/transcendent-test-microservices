# Policy for auth service
# Allow reading database credentials
path "secret/data/database" {
  capabilities = ["read"]
}

# Allow reading auth service specific secrets
path "secret/data/auth-service/*" {
  capabilities = ["read"]
}

# Allow creating certificates for auth service
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
