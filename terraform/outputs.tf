# terraform/outputs.tf
# Outputs for Cloudflare Zero Trust configuration

output "tunnel_token" {
  description = "Token for the Cloudflared tunnel"
  value       = module.cloudflare_tunnel.tunnel_token
  sensitive   = true
}

output "tunnel_id" {
  description = "ID of the Cloudflare Tunnel"
  value       = module.cloudflare_tunnel.tunnel_id
}

output "dns_policy_id" {
  description = "ID of the DNS policy for local domain resolution"
  value       = module.cloudflare_tunnel.dns_policy_id
}