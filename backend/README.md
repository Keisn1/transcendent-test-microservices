# Microservices with HashiCorp Vault Example

This repository demonstrates a complete microservices setup using:
- **HashiCorp Vault** for secret management and PKI
- **Nginx** as a reverse proxy
- **Docker Compose** for orchestration
- **Vault Agent** as sidecars for secret injection
- **Fastify** microservices with HTTPS

## Architecture

```
Internet -> Nginx (HTTPS) -> Microservices (HTTPS)
                            ↓
                        Vault Agent (sidecar)
                            ↓
                        Vault Server
```

## Quick Start

1. **Clone and setup**:
   ```bash
   git clone <repo-url>
   cd microservices-vault-example
   ```

2. **Start Vault**:
   ```bash
   docker-compose up vault vault-init
   ```

3. **Verify Vault is working**:
   ```bash
   # Check Vault status
   curl -s http://localhost:8200/v1/sys/health | jq

   # Access Vault UI
   open http://localhost:8200
   # Token: dev-root-token-change-me
   ```

## What's Included

- **Vault Server**: Configured with PKI and KV secrets engines
- **Vault Agent**: Sidecar containers for secret injection
- **Policies**: Least-privilege access for each service
- **AppRole Auth**: Secure service-to-service authentication
- **SSL/TLS**: Automatic certificate generation and rotation

## Next Steps

- Add microservices (auth, user)
- Add nginx reverse proxy
- Add database
- Add monitoring

## Development

See individual service README files for development instructions.
