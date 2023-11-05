# AWS Nat instance.

Terraform VPC sub module which creates a nat instance for private networks.<br>

*A NAT (Network Address Translation) instance is, like a bastion host, an EC2 instance that lives in your public subnet.<br>
A NAT instance, however, allows your private instances outgoing connectivity to the internet<br><u>while at the same time blocking inbound traffic from the internet</u>.*

This is a fork of https://github.com/toluna-terraform/terraform-aws-vpc/tree/v1.0.12/modules/nat-instance