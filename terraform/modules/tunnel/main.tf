# terraform/modules/tunnel/main.tf
# Configures Cloudflare Tunnel, access policies, and DNS routing

resource "random_password" "tunnel_secret" {
  length  = 64
  special = false
  keepers = {
    # Regenerate secret if tunnel name changes
    tunnel_name = var.tunnel_name
  }
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "tunnel" {
  account_id = var.account_id
  name       = var.tunnel_name
  secret     = random_password.tunnel_secret.result
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "tunnel_config" {
  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id
  config {
    dynamic "ingress_rule" {
      for_each = var.services
      content {
        hostname = "${ingress_rule.value.subdomain}.${var.domain}"
        service  = "${ingress_rule.value.type}://localhost:${ingress_rule.value.port}"
      }
    }
    ingress_rule {
      hostname = "dns.${var.local_domain}"
      service  = "udp://localhost:53"
    }
    ingress_rule {
      service = "http_status:404"
    }
  }
}

resource "cloudflare_zero_trust_access_application" "service_app" {
  for_each   = { for s in var.services : s.subdomain => s }
  account_id = var.account_id
  name       = "${each.value.subdomain}-internal-access"
  domain     = "${each.value.subdomain}.${var.domain}"
  type       = "self_hosted"
}

resource "cloudflare_zero_trust_access_policy" "warp_policy" {
  for_each       = { for s in var.services : s.subdomain => s }
  application_id = cloudflare_zero_trust_access_application.service_app[each.key].id
  account_id     = var.account_id
  name           = "${each.value.subdomain}-warp-policy"
  decision       = "allow"
  include {
    login_method = ["warp"]
  }
}

# DNS policy to forward *.local_domain to Bind server
resource "cloudflare_zero_trust_gateway_dns_policy" "local_domain" {
  account_id = var.account_id
  name       = "local-domain-resolution"
  decision   = "allow"
  match      = "*.${var.local_domain}"

  settings {
    ip_categories      = false
    resolve_unmanaged  = false
    virtual_network_id = var.virtual_network_id
  }
}

resource "cloudflare_zero_trust_tunnel_cloudflared_route" "private_network" {
  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id
  network    = "192.168.1.0/24"
  comment    = "Private network for WARP access"
}
