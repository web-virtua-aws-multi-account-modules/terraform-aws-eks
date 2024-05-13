module "create_vpc_full" {
  count           = var.make_new_network ? 1 : 0
  source          = "web-virtua-aws-multi-account-modules/vpc-full/aws"
  vpc_name        = "tf-vpc-eks"
  cidr_block      = "10.0.0.0/16"
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  ou_name         = var.ou_name
}
