# terraform/main.tf
# Configures Cloudflare Zero Trust tunnel, access policies, and DNS routing for internal services

terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.45" # Stable version for compatibility
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Remote backend for state management (recommended for production)
  # Uncomment and configure for your environment
  /*
  backend "s3" {
    bucket = "your-terraform-state-bucket"
    key    = "cloudflare-tunnel-setup/terraform.tfstate"
    region = "us-east-1"
  }
  */
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Module for Cloudflare Tunnel and related resources
module "cloudflare_tunnel" {
  source = "./modules/tunnel"

  account_id         = var.cloudflare_account_id
  tunnel_name        = var.tunnel_name
  services           = var.services
  domain             = var.domain
  local_domain       = var.local_domain
  bind_ip            = var.bind_ip
  zone_id            = var.cloudflare_zone_id
  virtual_network_id = var.virtual_network_id
}