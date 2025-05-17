# Cloudflare Tunnel and Bind Server Deployment

This repository automates the deployment of a Cloudflare Tunnel and a Bind DNS server on a virtual machine (VM) using GitHub Actions. It provides secure internal access with self-signed certificates and local DNS resolution for WARP-connected devices. The setup is designed to be easy to use, flexible for customization, and maintainable through version-controlled configuration files.

## Features

- Deploys Cloudflared and Bind server via Docker Compose.
- Generates self-signed certificates for services dynamically.
- Reads configuration and service details from repository files (`config.json` and `services.json`).
- Triggers automatically on push to the `main` branch.

## Prerequisites

- A VM accessible via SSH with Docker and Docker Compose installed.
- A Cloudflare account with an API token and account ID.
- Git installed locally to clone and manage the repository.

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/cloudflare-tunnel-setup.git
cd cloudflare-tunnel-setup
```

Replace `your-username` with your GitHub username.

### 2. Configure Repository Files

Create the following files in the repository root with your specific settings:

#### `config.json`

Defines the domain, local domain, Bind IP, and server SSH details.

```json
{
  "domain": "example.com",
  "local_domain": "example.local",
  "bind_ip": "192.168.1.2",
  "server_ssh_address": "192.168.1.100",
  "server_ssh_username": "cloud-user"
}
```

- `domain`: Your public domain (e.g., `example.com`).
- `local_domain`: Local domain for internal resolution (e.g., `example.local`).
- `bind_ip`: IP address of the Bind server on your network.
- `server_ssh_address`: IP or hostname of your VM.
- `server_ssh_username`: SSH username for VM access.

#### `services.json`

Lists services with subdomains, local IPs, ports, and types.

```json
[
  {"subdomain": "dev", "local_ip": "192.168.1.10", "port": 8080, "type": "http"},
  {"subdomain": "mqtt", "local_ip": "192.168.1.11", "port": 8883, "type": "tcp"},
  {"subdomain": "ssh", "local_ip": "192.168.1.12", "port": 22, "type": "ssh"}
]
```

- `subdomain`: Subdomain for each service (e.g., `dev` becomes `dev.example.com`).
- `local_ip`: Internal IP of the service.
- `port`: Port the service runs on.
- `type`: Protocol type (e.g., `http`, `tcp`, `ssh`).

### 3. Set Up GitHub Secrets

In your GitHub repository, go to **Settings > Secrets and variables > Actions > Secrets** and add:

- `SSH_PRIVATE_KEY`: Your SSH private key for VM access.
- `CLOUDFLARE_API_TOKEN`: Cloudflare API token with tunnel permissions.
- `CLOUDFLARE_ACCOUNT_ID`: Your Cloudflare account ID.

### 4. Push Changes to Trigger Deployment

```bash
git add .
git commit -m "Initial setup with config and services"
git push origin main
```

The workflow runs automatically on push to the `main` branch, reading `config.json` and `services.json` to deploy the setup.

### 5. Verify Deployment

- Check running containers on the VM:
  ```bash
  ssh cloud-user@192.168.1.100 "docker ps"
  ```
- Test local DNS resolution with WARP enabled:
  ```bash
  nslookup dev.example.local
  ```
- Access a service (after trusting the certificate):
  ```bash
  curl https://dev.example.com
  ```

## Managing Certificates

- Certificates are generated in `certs/certs/` on the VM.
- The root CA certificate (`ca.crt`) must be installed on client devices to trust the services.
  - On macOS: `sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain certs/ca.crt`
  - On Windows: Import `ca.crt` via Certificate Manager.
  - On Linux: Copy `ca.crt` to `/usr/local/share/ca-certificates/` and run `sudo update-ca-certificates`.

- Certificates are only generated if they don’t already exist, making updates efficient.

## Updating Services

1. Modify `services.json` or `config.json` as needed.
2. Commit and push changes:
   ```bash
   git add .
   git commit -m "Update services"
   git push origin main
   ```

The workflow redeploys with the updated configuration.

## Directory Structure

```
cloudflare-tunnel-setup/
├── .github/workflows/deploy.yml      # GitHub Actions workflow
├── certs/generate_certs.sh          # Certificate generation script
├── bind/config/                     # Bind configuration files
├── bind/zones/                      # Bind zone files
├── terraform/                       # Terraform configuration (assumed)
├── config.json                      # General configuration
├── services.json                    # Service definitions
├── docker-compose.yml               # Docker Compose file (assumed)
└── README.md                        # This file
```

## Troubleshooting

- **Tunnel not working**: Check Cloudflared logs on the VM:
  ```bash
  docker logs cloudflared
  ```
- **DNS resolution fails**: Verify Bind configuration and WARP DNS policy.
- **SSL errors**: Ensure `ca.crt` is trusted on client devices.
- **Workflow errors**: Check GitHub Actions logs for missing files or secrets.

## Notes

- The setup uses self-signed certificates; manual trust is required on clients.
- Keep `config.json` and `services.json` in version control for a deployment history.
- Adjust `docker-compose.yml` and Terraform files as needed for your environment (assumed to exist).
