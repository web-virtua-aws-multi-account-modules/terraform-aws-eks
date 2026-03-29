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
    "karpenter.sh/discovery"                        = var.cluster_name
  }
}

data "aws_caller_identity" "current" {}

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

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
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

  dynamic "encryption_config" {
    for_each = var.enable_kms_secrets ? [1] : []
    content {
      provider {
        key_arn = aws_kms_key.eks_secrets[0].arn
      }
      resources = ["secrets"]
    }
  }

  tags = merge(var.tags, var.use_eks_default_tags ? local.eks_default_tags : {})

  depends_on = [
    aws_iam_role.create_eks_cluster_role
  ]
}

data "aws_iam_policy_document" "eks_secrets" {
  count = var.enable_kms_secrets ? 1 : 0

  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "Allow access for EKS Service"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.create_eks_cluster_role.arn]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = length(var.kms_key_administrators) > 0 ? [1] : []
    content {
      sid    = "Allow access for Key Administrators"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = var.kms_key_administrators
      }
      actions = [
        "kms:Create*",
        "kms:Describe*",
        "kms:Enable*",
        "kms:List*",
        "kms:Put*",
        "kms:Update*",
        "kms:Revoke*",
        "kms:Disable*",
        "kms:Get*",
        "kms:Delete*",
        "kms:TagResource",
        "kms:UntagResource",
        "kms:ScheduleKeyDeletion",
        "kms:CancelKeyDeletion"
      ]
      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = length(var.kms_key_users) > 0 ? [1] : []
    content {
      sid    = "Allow access for Key Users"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = var.kms_key_users
      }
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ]
      resources = ["*"]
    }
  }
}

resource "aws_kms_key" "eks_secrets" {
  count                   = var.enable_kms_secrets ? 1 : 0
  description             = "KMS key to encrypt Kubernetes Secrets in ${var.cluster_name}"
  enable_key_rotation     = true
  deletion_window_in_days = var.kms_secrets_deletion_window

  policy = try(data.aws_iam_policy_document.eks_secrets[0].json, null)

  tags = merge(var.tags, var.use_eks_default_tags ? local.eks_default_tags : {})
}

resource "aws_cloudwatch_log_group" "create_cloudwatch_log_group" {
  count             = var.retention_cloudwatch_log_group > 0 ? 1 : 0
  name              = "/aws/eks/${var.cluster_name}/${var.role_policy_metrics_cusmized_name != null ? var.role_policy_metrics_cusmized_name : var.cluster_name}"
  retention_in_days = var.retention_cloudwatch_log_group
}

resource "aws_security_group" "create_sec_group_eks_internal" {
  count  = var.security_groups_ids == null ? 1 : 0
  name   = "${var.role_policy_metrics_cusmized_name != null ? var.role_policy_metrics_cusmized_name : var.cluster_name}-sec-group-eks-internal"
  vpc_id = var.make_new_network ? module.create_vpc_full[0].vpc_id : var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.role_policy_metrics_cusmized_name != null ? var.role_policy_metrics_cusmized_name : var.cluster_name}-sec-group-eks-internal"
    # Karpenter Autoscaler
    "karpenter.sh/discovery" = var.cluster_name
  }
}
