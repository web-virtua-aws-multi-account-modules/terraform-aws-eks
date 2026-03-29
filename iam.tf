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
  name               = "${var.role_policy_metrics_cusmized_name != null ? "${var.role_policy_metrics_cusmized_name}-eks-cluster-role" : var.cluster_name}-eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.create_eks_cluster_role_policy.json
}

resource "aws_iam_role_policy_attachment" "create_attach_eks_cluster_policy_on_eks_cluste_role" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.create_eks_cluster_role.name
}


data "http" "aws_load_balancer_controller_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"
}

resource "aws_iam_policy" "create_lb_controller_policy" {
  name        = "${var.role_policy_metrics_cusmized_name != null ? "${var.role_policy_metrics_cusmized_name}-lb-controller-policy" : var.cluster_name}-lb-controller-policy"
  path        = "/"
  description = "Policy to controller AWS loadbalancer IAM policy"
  policy      = data.http.aws_load_balancer_controller_policy.response_body
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
  name               = "${var.role_policy_metrics_cusmized_name != null ? "${var.role_policy_metrics_cusmized_name}-eks-nodes-roles" : var.cluster_name}-eks-nodes-roles"
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

  name = var.role_policy_metrics_cusmized_name != null ? "${var.role_policy_metrics_cusmized_name}-autoscaler-role" : "tf-amazon-eks-cluster-autoscaler-role"
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

resource "aws_iam_policy" "create_desired_terminate_scaling_policy" {
  count = var.make_policy_role_provider_autoscaler ? 1 : 0

  name        = "${var.role_policy_metrics_cusmized_name != null ? "${var.role_policy_metrics_cusmized_name}-desired-term-scaling-policy" : var.cluster_name}-desired-term-scaling-policy"
  path        = "/"
  description = "Policy to set desired and terminate scaling IAM policy"
  tags        = merge(var.tags_autoscaler, var.use_tags_default ? local.tags_autoscaler : {})

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : {
            "aws:ResourceTag/k8s.io/cluster-autoscaler/enabled" : "true",
            "aws:ResourceTag/k8s.io/cluster-autoscaler/${var.cluster_name}" : "owned"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeTags",
          "ec2:DescribeImages",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:GetInstanceTypesFromInstanceRequirements",
          "eks:DescribeNodegroup"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "create_attach_desired_terminate_scaler_policy_on_iam_autoscaler_role" {
  count = var.make_policy_role_provider_autoscaler ? 1 : 0

  policy_arn = aws_iam_policy.create_desired_terminate_scaling_policy[0].arn
  role       = aws_iam_role.create_autoscaler_role[0].name
}

resource "aws_iam_role" "create_ebs_management_role" {
  count = var.make_role_ebs_csi_driver ? 1 : 0

  name = var.role_policy_metrics_cusmized_name != null ? "${var.role_policy_metrics_cusmized_name}-ebs-csi-driver-role" : "tf-amazon-eks-cluster-ebs-csi-driver-role"
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

resource "aws_iam_policy" "create_fix_addon_ebs_csi_driver_policy" {
  count = var.make_role_ebs_csi_driver ? 1 : 0

  name        = "${var.role_policy_metrics_cusmized_name != null ? "${var.role_policy_metrics_cusmized_name}-aws-ebs-csi-driver-policy" : var.cluster_name}-aws-ebs-csi-driver-policy"
  path        = "/"
  description = "Policy to set desired and terminate scaling IAM policy"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateSnapshot",
          "ec2:AttachVolume",
          "ec2:DeleteSnapshot",
          "ec2:DetachVolume",
          "ec2:ModifyVolume",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInstances",
          "ec2:DescribeSnapshots",
          "ec2:DescribeTags",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumesModifications"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "create_attach_ebs_role_policy" {
  count = var.make_role_ebs_csi_driver ? 1 : 0

  policy_arn = data.aws_iam_policy.get_data_ebs_csi_policy.arn
  role       = aws_iam_role.create_ebs_management_role[0].name
}

resource "aws_iam_role_policy_attachment" "create_attach_fix_addon_ebs_driver_role_policy" {
  count = var.make_role_ebs_csi_driver ? 1 : 0

  policy_arn = aws_iam_policy.create_fix_addon_ebs_csi_driver_policy[0].arn
  role       = aws_iam_role.create_ebs_management_role[0].name
}

resource "aws_eks_addon" "create_ebs_addon" {
  count = var.make_role_ebs_csi_driver ? 1 : 0

  cluster_name                = aws_eks_cluster.create_eks_cluster.name
  addon_name                  = "aws-ebs-csi-driver"
  resolve_conflicts_on_update = "OVERWRITE"
  service_account_role_arn    = aws_iam_role.create_ebs_management_role[0].arn
  addon_version               = var.ebs_addon_version
}

resource "aws_eks_addon" "create_others_addons" {
  count = length(var.eks_addons)

  cluster_name                = aws_eks_cluster.create_eks_cluster.name
  addon_name                  = var.eks_addons[count.index].addon_name
  resolve_conflicts_on_update = var.eks_addons[count.index].resolve_conflicts
  service_account_role_arn    = var.eks_addons[count.index].service_account_role_arn
  addon_version               = var.eks_addons[count.index].addon_version
  tags                        = var.eks_addons[count.index].tags
}

# ----------------------------------------------------------------#
# EKS Access Entries (Replaces aws-auth)
# ----------------------------------------------------------------#

resource "aws_eks_access_entry" "node_group" {
  count         = var.manage_aws_auth ? 1 : 0
  cluster_name  = aws_eks_cluster.create_eks_cluster.name
  principal_arn = aws_iam_role.create_eks_nodes_roles.arn
  type          = "EC2_LINUX"
}

# Access entries for roles (custom managed users from terraform inputs)
resource "aws_eks_access_entry" "roles" {
  for_each      = var.manage_aws_auth ? { for role in var.map_roles : role.rolearn => role } : {}
  cluster_name  = aws_eks_cluster.create_eks_cluster.name
  principal_arn = each.value.rolearn
  user_name     = try(each.value.username, null)
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "roles_admin" {
  for_each      = var.manage_aws_auth ? { for role in var.map_roles : role.rolearn => role if contains(role.groups, "system:masters") } : {}
  cluster_name  = aws_eks_cluster.create_eks_cluster.name
  principal_arn = aws_eks_access_entry.roles[each.key].principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  access_scope {
    type = "cluster"
  }
}

# Access entries for users
resource "aws_eks_access_entry" "users" {
  for_each      = var.manage_aws_auth ? { for user in var.map_users : user.userarn => user } : {}
  cluster_name  = aws_eks_cluster.create_eks_cluster.name
  principal_arn = each.value.userarn
  user_name     = try(each.value.username, null)
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "users_admin" {
  for_each      = var.manage_aws_auth ? { for user in var.map_users : user.userarn => user if contains(user.groups, "system:masters") } : {}
  cluster_name  = aws_eks_cluster.create_eks_cluster.name
  principal_arn = aws_eks_access_entry.users[each.key].principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  access_scope {
    type = "cluster"
  }
}

# Access entries for accounts (Legacy support for account root delegation)
resource "aws_eks_access_entry" "accounts" {
  for_each      = var.manage_aws_auth ? toset(var.map_accounts) : toset([])
  cluster_name  = aws_eks_cluster.create_eks_cluster.name
  principal_arn = "arn:aws:iam::${each.value}:root"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "accounts_admin" {
  for_each      = var.manage_aws_auth ? toset(var.map_accounts) : toset([])
  cluster_name  = aws_eks_cluster.create_eks_cluster.name
  principal_arn = aws_eks_access_entry.accounts[each.value].principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  access_scope {
    type = "cluster"
  }
}
