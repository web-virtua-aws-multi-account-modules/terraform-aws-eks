# ----------------------------------------------------------------#
# EKS cluster
# ----------------------------------------------------------------#
output "eks_cluster_id" {
  value = aws_eks_cluster.create_eks_cluster.id
}

output "eks_cluster" {
  value = aws_eks_cluster.create_eks_cluster
}

output "eks_cluster_name" {
  value = aws_eks_cluster.create_eks_cluster.name
}

output "eks_security_group_internal" {
  value = try(aws_security_group.create_sec_group_eks_internal, null)
}

output "eks_endpoint" {
  value = aws_eks_cluster.create_eks_cluster.endpoint
}

output "eks_kubeconfig_certificate_authority_data" {
  value = aws_eks_cluster.create_eks_cluster.certificate_authority[0].data
}

output "cloudwatch_log_group" {
  value = try(aws_cloudwatch_log_group.create_cloudwatch_log_group, null)
}

# ----------------------------------------------------------------#
# New network
# ----------------------------------------------------------------#
output "vpc_new" {
  value = module.create_vpc_full
}

output "vpc_new_id" {
  value = try(module.create_vpc_full.vpc_id, null)
}

output "vpc_new_internet_gateway" {
  value = try(module.create_vpc_full.internet_gateway, null)
}

output "vpc_new_nat_gateway" {
  value = try(module.create_vpc_full.nat_gateway, null)
}

output "vpc_new_subnets" {
  value = try(module.create_vpc_full[0].private_subnets, null)
}

output "vpc_new_private_subnets_ids" {
  value = try(module.create_vpc_full[0].private_subnets[*].id, null)
}

output "vpc_new_public_subnets_ids" {
  value = try(module.create_vpc_full[0].public_subnets[*].id, null)
}

# ----------------------------------------------------------------#
# Node pools
# ----------------------------------------------------------------#
output "eks_nodes_groups" {
  value = aws_eks_node_group.create_eks_nodes_groups
}

output "nodes_autoscaler_label_tags" {
  value = aws_autoscaling_group_tag.create_nodes_autoscaler_label_tags
}

# ----------------------------------------------------------------#
# IAM
# ----------------------------------------------------------------#

output "eks_cluster_role" {
  value = aws_iam_role.create_eks_cluster_role
}

output "lb_controller_policy" {
  value = aws_iam_policy.create_lb_controller_policy
}

output "eks_nodes_roles" {
  value = aws_iam_role.create_eks_nodes_roles
}

# ----------------------------------------------------------------#
# Autoscaler, EBS Driver and User Managment
# ----------------------------------------------------------------#
output "autoscaler_policy" {
  value = try(aws_iam_policy.create_autoscaler_policy, null)
}

output "oidc_identity_provider" {
  value = try(aws_iam_openid_connect_provider.create_oidc_identity_provider, null)
}

output "iam_autoscaler_role" {
  value = try(aws_iam_role.create_autoscaler_role, null)
}

output "iam_autoscaler_role_arn" {
  value = try(aws_iam_role.create_autoscaler_role[0].arn, null)
}

output "ebs_management_role" {
  value = try(aws_iam_role.create_ebs_management_role, null)
}

output "eks_addons" {
  value = try(concat(aws_eks_addon.create_ebs_addon, aws_eks_addon.create_others_addons), null)
}

output "aws_auth" {
  value = try(kubernetes_config_map_v1_data.aws_auth, null)
}
