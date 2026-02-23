# ------------------------------------------------------------------------------
# Amazon Client VPN
# https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/what-is.html
#
# NOTE: cloudposse/ec2-client-vpn/aws 0.14.0 was removed because it transitively
# requires hashicorp/template v2.2.0, which has no darwin_arm64 binary and is
# permanently archived by HashiCorp. The VPN was always disabled (enable_client_vpn
# = false) so this has no functional impact. Re-implement using the custom
# modules/vpn module if VPN support is needed in the future.
# ------------------------------------------------------------------------------
