# Cloudflare Tunnel and Bind Server Deployment with Ngrok SSH Access

This repository automates the deployment of a Cloudflare Tunnel and a Bind DNS server on a virtual machine (VM) using GitHub Actions, enabling secure internal access with self-signed certificates and local DNS resolution for WARP-connected devices. It supports SSH access to VMs behind a NAT using Ngrok, leveraging the VM’s existing SSH port configuration for flexibility.

## Features

- Deploys Cloudflared and Bind server via Docker Compose for secure tunneling and local DNS.
- Generates self-signed certificates for internal services dynamically.
- Reads configuration from `config.json` and `services.json` for easy customization.
- Supports Ngrok for SSH access through NAT, using Workflow Dispatch inputs for SSH details.
- Organizes deployment artifacts in `~/.cf-deploy` on the VM with a clean directory structure.
- Triggers via Workflow Dispatch, using Ngrok-provided SSH address and port.

## Repository Structure

```
cloudflare-tunnel-setup/
├── .github/workflows/deploy.yml      # GitHub Actions workflow
├── bind/config/                     # Bind configuration files (generated)
├── bind/zones/                      # Bind zone files (generated)
├── certs/generate_certs.sh          # Certificate generation script
├── scripts/ngrok_setup.sh           # Ngrok setup script for SSH
├── terraform/                       # Terraform scripts for Cloudflare Zero Trust
├── config.json                      # General configuration (domain, Bind IP)
├── services.json                    # Service definitions (subdomains, IPs, ports)
├── docker-compose.yml               # Docker Compose file
├── README.md                        # This file
```

## VM Directory Structure

The GitHub workflow deploys artifacts to `~/.cf-deploy` (e.g., `/home/cloud-user/.cf-deploy`) on the VM, with the following subdirectories:

```
/home/cloud-user/.cf-deploy/
├── config/                     # Configuration files (config.json, services.json)
├── certs/                      # Self-signed certificates (ca.crt, service certs)
├── bind/                       # Bind server configurations
│   ├── config/                 # named.conf.local
│   └── zones/                  # db.<local_domain>
├── logs/                       # Log files (e.g., ngrok.log)
├── docker-compose.yml          # Docker Compose file
```

## Prerequisites

- Ubuntu-based VM with SSH access (existing port configuration, e.g., 22 or custom), Docker, and Docker Compose installed.
- Cloudflare account with API token (permissions: Tunnel, DNS, Zero Trust).
- Ngrok account with an authtoken for SSH tunneling (free or paid plan).
- Git installed locally to clone and manage the repository.
- SSH key pair for secure VM access (password-based authentication disabled).

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/cloudflare-tunnel-setup.git
cd cloudflare-tunnel-setup
```

Replace `your-username` with your GitHub username.

### 2. Set Up Ngrok on the VM

Ngrok must be manually installed and configured on the VM to expose the SSH service, allowing the GitHub workflow to connect through a NAT.

1. **Copy and Run `ngrok_setup.sh`**:
   - Copy the script to your VM (replace `192.168.1.100` with your VM’s IP and use the VM’s SSH port):
     ```bash
     scp scripts/ngrok_setup.sh cloud-user@192.168.1.100:~
     ```
   - SSH into the VM and run the script:
     ```bash
     ssh cloud-user@192.168.1.100
     chmod +x ngrok_setup.sh
     ./ngrok_setup.sh
     ```
   - Enter your Ngrok authtoken (from [Ngrok dashboard](https://dashboard.ngrok.com/get-started/your-authtoken)).
   - Specify the VM’s SSH port when prompted (e.g., 22 or your custom port).
   - Note the output for Workflow Dispatch inputs:
     ```
     server_ssh_address: 0.tcp.ngrok.io
     server_ssh_port: 12345
     ```
   - These will be used when triggering the workflow.

2. **Keep Ngrok Running**:
   - Run Ngrok in the background using `nohup` or `tmux`:
     ```bash
     nohup ./ngrok_setup.sh &
     ```
     Or:
     ```bash
     tmux new -s ngrok './ngrok_setup.sh'
     ```
     Detach with `Ctrl+B`, then `D`.

### 3. Disable SSH Password Authentication

Ensure SSH uses key-based authentication for security:

1. Edit `/etc/ssh/sshd_config` on the VM:
   ```bash
   sudo nano /etc/ssh/sshd_config
   ```
   Set:
   ```plaintext
   PasswordAuthentication no
   ```
2. Add your public SSH key to `~/.ssh/authorized_keys`:
   ```bash
   echo "your-public-key" >> ~/.ssh/authorized_keys
   ```
3. Restart SSH:
   ```bash
   sudo systemctl restart sshd
   ```

### 4. Configure Repository Files

Update the following files in the repository root with your settings:

#### `config.json`

Defines the domain, local domain, and Bind IP (SSH details are provided via Workflow Dispatch inputs).

```json
{
  "domain": "example.com",
  "local_domain": "example.local",
  "bind_ip": "192.168.1.2"
}
```

- `domain`: Public domain for services (e.g., `example.com`).
- `local_domain`: Local domain for internal resolution (e.g., `example.local`).
- `bind_ip`: IP address of the Bind server on your network.

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
- `port`: Port the service runs on (e.g., 22 for SSH, or your custom port).
- `type`: Protocol type (`http`, `tcp`, `ssh`).

### 5. Set Up GitHub Secrets

In your GitHub repository, go to **Settings > Secrets and variables > Actions > Secrets** and add:

- `SSH_PRIVATE_KEY`: SSH private key for VM access (contents of `~/.ssh/id_rsa`).
- `CLOUDFLARE_API_TOKEN`: Cloudflare API token with Tunnel, DNS, and Zero Trust permissions.
- `CLOUDFLARE_ACCOUNT_ID`: Your Cloudflare account ID.

### 6. Install Docker and Compose on the VM

```bash
sudo apt update
sudo apt install -y docker.io docker-compose
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker cloud-user
```

### 7. Trigger the Workflow

1. **Push Configuration Changes**:
   ```bash
   git add .
   git commit -m "Configure services for deployment"
   git push origin main
   ```

2. **Run Workflow Dispatch**:
   - Go to the repository’s **Actions** tab.
   - Select **Deploy Cloudflare Tunnel and Bind Server**.
   - Provide dispatch inputs using the Ngrok details from `ngrok_setup.sh`:
     - `server_ssh_address`: Ngrok host (e.g., `0.tcp.ngrok.io`).
     - `server_ssh_username`: SSH username (e.g., `cloud-user`).
     - `server_ssh_port`: Ngrok port (e.g., `12345`).
   - Run the workflow.

### 8. Trust Self-Signed Certificates

- Copy `certs/ca.crt` from `~/.cf-deploy/certs` on the VM to WARP client devices:
  ```bash
  scp -P 12345 cloud-user@0.tcp.ngrok.io:~/.cf-deploy/certs/ca.crt .
  ```
- Install the CA certificate:
  - **macOS**: `sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ca.crt`
  - **Windows**: Import via Certificate Manager (`certmgr.msc`).
  - **Linux**: Copy to `/usr/local/share/ca-certificates/` and run `sudo update-ca-certificates`.

### 9. Verify Deployment

- **Check Containers**:
  ```bash
  ssh -p 12345 cloud-user@0.tcp.ngrok.io "docker ps"
  ```
  Should show `cloudflared` and `bind` containers.

- **Check VM Directory Structure**:
  ```bash
  ssh -p 12345 cloud-user@0.tcp.ngrok.io "ls -R ~/.cf-deploy"
  ```
  Should show:
  ```
  /home/cloud-user/.cf-deploy/
  ├── config/
  │   ├── config.json
  │   └── services.json
  ├── certs/
  │   ├── ca.crt
  │   ├── dev.example.com.crt
  │   ├── dev.example.com.key
  │   ├── mqtt.example.com.crt
  │   ├── mqtt.example.com.key
  │   ├── ssh.example.com.crt
  │   └── ssh.example.com.key
  ├── bind/
  │   ├── config/
  │   │   └── named.conf.local
  │   └── zones/
  │       └── db.example.local
  ├── logs/
  │   └── ngrok.log
  ├── docker-compose.yml
  ```

- **Test DNS Resolution** (WARP enabled):
  ```bash
  nslookup dev.example.local
  ```
  Should resolve to `192.168.1.10`.

- **Test Service Access**:
  ```bash
  curl https://dev.example.com
  ssh cloud-user@192.168.1.12
  ```

## Managing Certificates

- Certificates are stored in `~/.cf-deploy/certs` on the VM.
- The root CA certificate (`ca.crt`) must be installed on client devices to trust services.
- Certificates are only generated if they don’t exist, ensuring efficiency.

## Updating Services

1. Modify `config.json` or `services.json` as needed.
2. Commit and push changes:
   ```bash
   git add .
   git commit -m "Update services or configuration"
   git push origin main
   ```
3. Re-run the Workflow Dispatch with the same or updated Ngrok SSH details (if the tunnel changes).

## SSH Access via Ngrok

Ngrok exposes the VM’s SSH service to a public URL, allowing access from anywhere, even behind a NAT.

1. **Run Ngrok**:
   - Use `scripts/ngrok_setup.sh` to start Ngrok and get the SSH connection details (see Step 2).
   - Example output:
     ```
     server_ssh_address: 0.tcp.ngrok.io
     server_ssh_port: 12345
     ```

2. **Use in Workflow Dispatch**:
   - Enter the `server_ssh_address` and `server_ssh_port` as dispatch inputs when triggering the workflow.

3. **Security Recommendations**:
   - Ensure password authentication is disabled (configured in Step 3).
   - With a paid Ngrok plan, enable client authentication or IP whitelisting.
   - Monitor Ngrok logs: `cat ~/.cf-deploy/logs/ngrok.log`.

## Troubleshooting

- **Tunnel not working**:
  - Check Cloudflared logs: `ssh -p <ngrok_port> cloud-user@<ngrok_host> "docker logs cloudflared"`.
  - Verify `TUNNEL_TOKEN` in workflow logs.
- **DNS resolution fails**:
  - Check Bind logs: `ssh -p <ngrok_port> cloud-user@<ngrok_host> "docker logs bind"`.
  - Verify WARP DNS policy in Cloudflare dashboard.
- **SSL errors**:
  - Ensure `ca.crt` is trusted on clients.
  - Check certificate files: `ssh -p <ngrok_port> cloud-user@<ngrok_host> "ls ~/.cf-deploy/certs"`.
- **Ngrok issues**:
  - Check Ngrok logs: `ssh -p <ngrok_port> cloud-user@<ngrok_host> "cat ~/.cf-deploy/logs/ngrok.log"`.
  - Ensure Ngrok is running: `ssh -p <ngrok_port> cloud-user@<ngrok_host> "ps aux | grep ngrok"`.
- **Workflow errors**:
  - Review GitHub Actions logs for JSON, SSH, or deployment issues.
  - Confirm `server_ssh_address` and `server_ssh_port` inputs match Ngrok details.

## Notes

- Certificates are self-signed; trust `ca.crt` on clients.
- Ngrok URLs change on each run unless using a paid plan with a static domain.
- Keep `config.json` and `services.json` version-controlled for deployment history.
- The deployment directory (`~/.cf-deploy`) is organized for clarity and scalability.
