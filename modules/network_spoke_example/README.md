# Network Spoke

A centralized network "spoke" which connects to a "hub" VPC in another AWS account for centralized egress.

Related links:
- [Infrastructure OU - Network account](https://docs.aws.amazon.com/prescriptive-guidance/latest/security-reference-architecture/network.html)
- [Using the NAT gateway with AWS Network Firewall for centralized IPv4 egress](https://docs.aws.amazon.com/whitepapers/latest/building-scalable-secure-multi-vpc-network-infrastructure/using-nat-gateway-with-firewall.html)
- [Visual subnet calculator](https://www.davidc.net/sites/default/subnets/subnets.html)
- [terraform-aws-vpc module](https://github.com/terraform-aws-modules/terraform-aws-vpc)
- [terraform-aws-modules/terraform-aws-network-firewall](https://github.com/terraform-aws-modules/terraform-aws-network-firewall)
- [aws-samples/aws-network-firewall-terraform](https://github.com/aws-samples/aws-network-firewall-terraform)