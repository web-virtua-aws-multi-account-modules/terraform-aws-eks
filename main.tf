locals {
  eks_default_tags = {
    Name                                            = var.cluster_name
    tf                                              = var.cluster_name
    Terraform                                       = true
    Scost                                           = var.cluster_environment
    Environment                                     = var.cluster_environment
    "eks:cluster-name"                              = var.cluster_name
    "eks:nodegroup-name"                            = var.cluster_name
    "k8s.io/cluster-autoscaler/enabled"             = true
    "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
    "kubernetes.io/cluster/${var.cluster_name}"     = "owned"
    "kubernetes.io/cluster/${var.cluster_name}"     = "shared"
    "tf-ou"                                         = var.ou_name
  }
}
resource "aws_eks_cluster" "create_eks_cluster" {
  name                      = var.cluster_name
  version                   = var.k8s_version
  role_arn                  = aws_iam_role.create_eks_cluster_role.arn
  enabled_cluster_log_types = var.enabled_cluster_log_types

  vpc_config {
    subnet_ids              = var.make_new_network ? module.create_vpc_full[0].private_subnets[*].id : var.subnet_ids
    endpoint_private_access = var.eks_endpoint_private_access
    endpoint_public_access  = var.eks_endpoint_public_access
    public_access_cidrs     = var.eks_endpoint_public_access_cidrs
    security_group_ids      = var.security_groups_ids == null ? [aws_security_group.create_sec_group_eks_internal[0].id] : var.security_groups_ids
  }

  timeouts {
    create = lookup(var.eks_timeouts, "create", null)
    update = lookup(var.eks_timeouts, "update", null)
    delete = lookup(var.eks_timeouts, "delete", null)
  }

  kubernetes_network_config {
    ip_family         = var.eks_ip_family
    service_ipv4_cidr = var.eks_service_ipv4_cidr
  }

  tags = merge(var.tags, var.use_eks_default_tags ? local.eks_default_tags : {})

  depends_on = [
    aws_iam_role.create_eks_cluster_role
  ]
}

resource "aws_cloudwatch_log_group" "create_cloudwatch_log_group" {
  count             = var.retention_cloudwatch_log_group > 0 ? 1 : 0
  name              = "/aws/eks/${var.cluster_name}/${var.cluster_name}"
  retention_in_days = var.retention_cloudwatch_log_group
}

resource "aws_security_group" "create_sec_group_eks_internal" {
  count  = var.security_groups_ids == null ? 1 : 0
  name   = "${var.cluster_name}-sec-group-eks-internal"
  vpc_id = var.make_new_network ? module.create_vpc_full[0].vpc_id : var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-sec-group-eks-internal"
  }
}
