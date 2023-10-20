# ----------------------------------------------------------------#
# EKS cluster
# ----------------------------------------------------------------#
data "aws_iam_policy_document" "create_eks_cluster_role_policy" {
  version = "2012-10-17"

  statement {
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "Service"
      identifiers = [
        "eks.amazonaws.com",
        "eks-fargate-pods.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "create_eks_cluster_role" {
  name               = "${var.role_policy_metrics_cusmized_name != null ? var.role_policy_metrics_cusmized_name : var.cluster_name}-eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.create_eks_cluster_role_policy.json
}

resource "aws_iam_role_policy_attachment" "create_attach_eks_cluster_policy_on_eks_cluste_role" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.create_eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "create_attach_eks_service_policy_on_eks_cluste_role" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.create_eks_cluster_role.name
}

resource "aws_iam_policy" "create_lb_controller_policy" {
  name        = "${var.role_policy_metrics_cusmized_name != null ? var.role_policy_metrics_cusmized_name : var.cluster_name}-lb-controller-policy"
  path        = "/"
  description = "Policy to controller AWS loadbalancer IAM policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Resource = "*"
        Action = [
          "iam:CreateServiceLinkedRole",
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeTags",
          "ec2:GetCoipPoolUsage",
          "ec2:DescribeCoipPools",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeListenerCertificates",
          "elasticloadbalancing:DescribeSSLPolicies",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DescribeTags"
        ]
      },
      {
        Effect   = "Allow"
        Resource = "*"
        Action = [
          "cognito-idp:DescribeUserPoolClient",
          "acm:ListCertificates",
          "acm:DescribeCertificate",
          "iam:ListServerCertificates",
          "iam:GetServerCertificate",
          "waf-regional:GetWebACL",
          "waf-regional:GetWebACLForResource",
          "waf-regional:AssociateWebACL",
          "waf-regional:DisassociateWebACL",
          "wafv2:GetWebACL",
          "wafv2:GetWebACLForResource",
          "wafv2:AssociateWebACL",
          "wafv2:DisassociateWebACL",
          "shield:GetSubscriptionState",
          "shield:DescribeProtection",
          "shield:CreateProtection",
          "shield:DeleteProtection"
        ]
      },
      {
        Effect   = "Allow"
        Resource = "*"
        Action = [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:CreateSecurityGroup",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:DeleteSecurityGroup"
        ]
      },
      {
        Effect   = "Allow"
        Resource = "*"
        Action = [
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:CreateRule",
          "elasticloadbalancing:DeleteRule",
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags",
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:SetIpAddressType",
          "elasticloadbalancing:SetSecurityGroups",
          "elasticloadbalancing:SetSubnets",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "elasticloadbalancing:DeleteTargetGroup",
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:SetWebAcl",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:AddListenerCertificates",
          "elasticloadbalancing:RemoveListenerCertificates",
          "elasticloadbalancing:ModifyRule"
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "create_attach_lb_controller_policy_on_eks_cluste_role" {
  policy_arn = aws_iam_policy.create_lb_controller_policy.arn
  role       = aws_iam_role.create_eks_cluster_role.name
}

# ----------------------------------------------------------------#
# Nodes EKS cluster
# ----------------------------------------------------------------#
data "aws_iam_policy_document" "create_eks_nodes_role_policy" {
  version = "2012-10-17"

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "ec2.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "create_eks_nodes_roles" {
  name               = "${var.role_policy_metrics_cusmized_name != null ? var.role_policy_metrics_cusmized_name : var.cluster_name}-eks-nodes-roles"
  assume_role_policy = data.aws_iam_policy_document.create_eks_nodes_role_policy.json
}

resource "aws_iam_role_policy_attachment" "create_attach_eks_cni_policy_on_eks_nodes_roles" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.create_eks_nodes_roles.name
}

resource "aws_iam_role_policy_attachment" "create_attach_eks_worker_node_policy_on_eks_nodes_roles" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.create_eks_nodes_roles.name
}

resource "aws_iam_role_policy_attachment" "create_attach_ec2_ecr_policy_on_eks_nodes_roles" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.create_eks_nodes_roles.name
}

# ----------------------------------------------------------------#
# Autoscaler, EBS Driver and User Managment
# ----------------------------------------------------------------#
locals {
  tags_autoscaler = {
    "Name"      = var.cluster_name
    "tf-policy" = var.cluster_name
    "tf-ou"     = var.ou_name
  }

  tags_identity_provider = {
    "Name"        = "${var.cluster_name}-eks-oidc"
    "tf-provider" = "${var.cluster_name}-eks-oidc"
    "tf-ou"       = var.ou_name
  }
}

resource "aws_iam_policy" "create_autoscaler_policy" {
  count = var.make_policy_role_provider_autoscaler ? 1 : 0

  name        = var.role_policy_metrics_cusmized_name != null ? var.role_policy_metrics_cusmized_name : var.cluster_autoscaler_policy.name
  policy      = jsonencode(var.cluster_autoscaler_policy.policy)
  path        = try(var.cluster_autoscaler_policy.path, null)
  description = try(var.cluster_autoscaler_policy.description, null)
  tags        = merge(var.tags_autoscaler, var.use_tags_default ? local.tags_autoscaler : {})
}

data "tls_certificate" "get_tls_url" {
  url = aws_eks_cluster.create_eks_cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "create_oidc_identity_provider" {
  count = var.make_policy_role_provider_autoscaler ? 1 : 0

  client_id_list  = var.identity_provider_audiences
  thumbprint_list = [data.tls_certificate.get_tls_url.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.create_eks_cluster.identity[0].oidc[0].issuer
  tags            = merge(var.tags, var.use_tags_default ? local.tags_identity_provider : {})
}

resource "aws_iam_role" "create_autoscaler_role" {
  count = var.make_policy_role_provider_autoscaler ? 1 : 0

  name = var.role_policy_metrics_cusmized_name != null ? var.role_policy_metrics_cusmized_name : "tf-amazon-eks-cluster-autoscaler-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : "arn:aws:iam::${split(":", aws_eks_cluster.create_eks_cluster.arn)[4]}:oidc-provider/${replace(aws_eks_cluster.create_eks_cluster.identity[0].oidc[0].issuer, "https://", "")}"
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            "${replace(aws_eks_cluster.create_eks_cluster.identity[0].oidc[0].issuer, "https://", "")}:sub" : "system:serviceaccount:kube-system:cluster-autoscaler"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "create_attach_autoscaler_role_policy" {
  count = var.make_policy_role_provider_autoscaler ? 1 : 0

  policy_arn = aws_iam_policy.create_autoscaler_policy[0].arn
  role       = aws_iam_role.create_autoscaler_role[0].name
}

resource "aws_iam_role" "create_ebs_management_role" {
  count = var.make_role_ebs_csi_driver ? 1 : 0

  name = var.role_policy_metrics_cusmized_name != null ? var.role_policy_metrics_cusmized_name : "tf-amazon-eks-cluster-ebs-csi-driver-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : "arn:aws:iam::${split(":", aws_eks_cluster.create_eks_cluster.arn)[4]}:oidc-provider/${replace(aws_eks_cluster.create_eks_cluster.identity[0].oidc[0].issuer, "https://", "")}"
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            "${replace(aws_eks_cluster.create_eks_cluster.identity[0].oidc[0].issuer, "https://", "")}:sub" : "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          }
        }
      }
    ]
  })
}

data "aws_iam_policy" "get_data_ebs_csi_policy" {
  name = "AmazonEBSCSIDriverPolicy"
}

resource "aws_iam_role_policy_attachment" "create_attach_ebs_role_policy" {
  count = var.make_role_ebs_csi_driver ? 1 : 0

  policy_arn = data.aws_iam_policy.get_data_ebs_csi_policy.arn
  role       = aws_iam_role.create_ebs_management_role[0].name
}

resource "aws_eks_addon" "create_ebs_addon" {
  count = var.make_role_ebs_csi_driver ? 1 : 0

  cluster_name             = aws_eks_cluster.create_eks_cluster.name
  addon_name               = "aws-ebs-csi-driver"
  resolve_conflicts        = "OVERWRITE"
  service_account_role_arn = aws_iam_role.create_ebs_management_role[0].arn
}

resource "aws_eks_addon" "create_others_addons" {
  count = length(var.eks_addons)

  cluster_name             = aws_eks_cluster.create_eks_cluster.name
  addon_name               = var.eks_addons[count.index].addon_name
  resolve_conflicts        = var.eks_addons[count.index].resolve_conflicts
  service_account_role_arn = var.eks_addons[count.index].service_account_role_arn
  addon_version            = var.eks_addons[count.index].addon_version
  tags                     = var.eks_addons[count.index].tags
}

data "aws_eks_cluster" "cluster" {
  name = aws_eks_cluster.create_eks_cluster.id
}

data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.create_eks_cluster.id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

resource "kubernetes_config_map_v1_data" "aws_auth" {
  count = var.manage_aws_auth ? 1 : 0

  force = true

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode(
      distinct(concat(
        [{
          rolearn  = aws_iam_role.create_eks_nodes_roles.arn
          username = "system:node:{{EC2PrivateDNSName}}"
          groups   = ["system:bootstrappers", "system:nodes"]
        }],
        distinct(var.map_roles),
      ))
    )
    mapUsers    = yamlencode(distinct(var.map_users))
    mapAccounts = yamlencode(distinct(var.map_accounts))
  }

  depends_on = [
    aws_eks_node_group.create_eks_nodes_groups
  ]
}
