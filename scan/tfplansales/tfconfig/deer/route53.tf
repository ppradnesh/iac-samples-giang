data "aws_acm_certificate" "deere_external" {
  domain      = "*.${var.environment_name}.us.e01.c01.johndeerecloud.com"
  types       = ["AMAZON_ISSUED"]
  statuses    = ["ISSUED"]
  most_recent = true
}

data "aws_route53_zone" "external_zone" {
  name         = "${var.environment_name}.us.e01.c01.johndeerecloud.com."
  private_zone = false
}

resource "aws_route53_record" "route53_record" {
  zone_id = data.aws_route53_zone.external_zone.zone_id
  name    = var.project_name
  type    = "A"

  alias {
    name                   = aws_lb.aws_lb.dns_name
    zone_id                = aws_lb.aws_lb.zone_id
    evaluate_target_health = true
  }
}

output "server_url" {
  value = "https://${local.server_url}"
}
