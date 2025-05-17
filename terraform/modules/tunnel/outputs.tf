# terraform/modules/tunnel/outputs.tf
# Outputs for the tunnel module

output "tunnel_token" {
  description = "Token for the Cloudflared tunnel"
  value       = cloudflare_zero_trust_tunnel_cloudflared.tunnel.tunnel_token
  sensitive   = true
}

output "tunnel_id" {
  description = "ID of the Cloudflare Tunnel"
  value       = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id
}

output "dns_policy_id" {
  description = "ID of the DNS policy for local domain resolution"
  value       = cloudflare_zero_trust_gateway_dns_policy.local_domain.id
}