#!/bin/bash
set -e

# Wait for Vault to be ready
echo "Waiting for Vault to be ready..."
max_attempts=30
attempt=0

while [ $attempt -lt $max_attempts ]; do
    if curl -s http://vault:8200/v1/sys/health >/dev/null 2>&1; then
        echo "Vault is ready!"
        break
    fi
    echo "Vault not ready yet, attempt $((attempt + 1))/$max_attempts"
    sleep 5
    attempt=$((attempt + 1))
done

if [ $attempt -eq $max_attempts ]; then
    echo "Vault failed to become ready after $max_attempts attempts"
    exit 1
fi

# Set Vault address and token
export VAULT_ADDR=http://vault:8200
export VAULT_TOKEN=${VAULT_DEV_ROOT_TOKEN_ID}

echo "Vault Token: $VAULT_TOKEN"

# Verify we can connect
echo "Testing Vault connection..."
if ! vault status; then
    echo "Failed to connect to Vault"
    exit 1
fi

# Enable secret engines
echo "Enabling secret engines..."
vault secrets enable -path=secret kv-v2 || echo "kv-v2 already enabled"
vault secrets enable pki || echo "pki already enabled"

# Configure PKI
echo "Configuring PKI..."
vault secrets tune -max-lease-ttl=87600h pki

# Generate root CA
echo "Generating root CA..."
vault write pki/root/generate/internal \
    common_name="Internal Root CA" \
    ttl=87600h

# Create intermediate CA
echo "Creating intermediate CA..."
vault secrets enable -path=pki_int pki || echo "pki_int already enabled"
vault secrets tune -max-lease-ttl=43800h pki_int

# Generate intermediate CSR
echo "Generating intermediate CSR..."
vault write -format=json pki_int/intermediate/generate/internal \
    common_name="Internal Intermediate CA" |
    jq -r '.data.csr' >/tmp/pki_intermediate.csr

# Sign intermediate certificate
echo "Signing intermediate certificate..."
vault write -format=json pki/root/sign-intermediate \
    csr=@/tmp/pki_intermediate.csr \
    format=pem_bundle \
    ttl="43800h" |
    jq -r '.data.certificate' >/tmp/intermediate.cert.pem

# Set signed certificate
echo "Setting signed certificate..."
vault write pki_int/intermediate/set-signed \
    certificate=@/tmp/intermediate.cert.pem

# Create role for microservices
echo "Creating PKI role for microservices..."
vault write pki_int/roles/microservice-role \
    allowed_domains="my-microservices.local" \
    allow_subdomains=true \
    max_ttl="720h" \
    generate_lease=true

# Test the PKI role
echo "Testing PKI role..."
vault write pki_int/issue/microservice-role \
    common_name="test.my-microservices.local" \
    ttl="1h" >/tmp/test-cert.json

if [ $? -eq 0 ]; then
    echo "PKI role test successful!"
else
    echo "PKI role test failed!"
    exit 1
fi

# Set up AppRole authentication
echo "Setting up AppRole authentication..."
vault auth enable approle || echo "approle already enabled"

# Create policies
echo "Creating policies..."
vault policy write auth-service-policy /vault/policies/auth-service-policy.hcl
vault policy write user-service-policy /vault/policies/user-service-policy.hcl

# Create AppRoles
echo "Creating AppRoles..."
vault write auth/approle/role/auth-service \
    token_policies="auth-service-policy" \
    token_ttl=1h \
    token_max_ttl=4h \
    bind_secret_id=true

vault write auth/approle/role/user-service \
    token_policies="user-service-policy" \
    token_ttl=1h \
    token_max_ttl=4h \
    bind_secret_id=true

# Store sample secrets
echo "Storing sample secrets..."
vault kv put secret/database \
    username="postgres" \
    password="postgres123" \
    host="postgres" \
    port="5432" \
    database="microservices"

vault kv put secret/auth-service/config \
    jwt_secret="super-secret-jwt-key" \
    session_secret="super-secret-session-key"

vault kv put secret/user-service/config \
    encryption_key="super-secret-encryption-key" \
    api_key="user-service-api-key"

# Create directory for role IDs and secret IDs
mkdir -p /vault/config

# Generate role-id and secret-id for services
echo "Generating AppRole credentials..."
vault read -format=json auth/approle/role/auth-service/role-id | jq -r '.data.role_id' >/vault/config/auth-service-role-id
vault write -format=json -f auth/approle/role/auth-service/secret-id | jq -r '.data.secret_id' >/vault/config/auth-service-secret-id

vault read -format=json auth/approle/role/user-service/role-id | jq -r '.data.role_id' >/vault/config/user-service-role-id
vault write -format=json -f auth/approle/role/user-service/secret-id | jq -r '.data.secret_id' >/vault/config/user-service-secret-id

echo "Vault initialization complete!"
echo "Auth Service Role ID: $(cat /vault/config/auth-service-role-id)"
echo "User Service Role ID: $(cat /vault/config/user-service-role-id)"

# Test final setup
echo "Testing final setup..."
vault kv get secret/database
vault write pki_int/issue/microservice-role \
    common_name="auth-service.my-microservices.local" \
    ttl="24h" \
    -format=json | jq -r '.data.certificate' | head -5

echo "All tests passed! Vault is ready."
