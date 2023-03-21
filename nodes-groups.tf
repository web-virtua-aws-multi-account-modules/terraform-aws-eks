resource "aws_eks_node_group" "create_eks_nodes_groups" {
  count = length(var.node_pools)

  cluster_name         = aws_eks_cluster.create_eks_cluster.name
  node_role_arn        = aws_iam_role.create_eks_nodes_roles.arn
  node_group_name      = var.node_pools[count.index].node_group_name
  subnet_ids           = var.make_new_network ? module.create_vpc_full[0].private_subnets[*].id : try(var.node_pools[count.index].subnet_ids, var.subnet_ids)
  version              = try(var.node_pools[count.index].eks_node_version, var.k8s_version)
  force_update_version = try(var.node_pools[count.index].force_update_version, false)
  disk_size            = try(var.node_pools[count.index].disk_size, 20)
  instance_types       = try(var.node_pools[count.index].instance_types, ["t3a.small"])
  capacity_type        = try(var.node_pools[count.index].capacity_type, "ON_DEMAND")
  ami_type             = try(var.node_pools[count.index].node_ami_type, "AL2_x86_64")
  release_version      = try(var.node_pools[count.index].node_ami_release_version, "")

  scaling_config {
    desired_size = try(var.node_pools[count.index].desired_capacity, 1)
    min_size     = try(var.node_pools[count.index].min_capacity_size, 1)
    max_size     = try(var.node_pools[count.index].max_capacity_size, 1)
  }

  dynamic "update_config" {
    for_each = (try(var.node_pools[count.index].max_unavailable_percentage, null) != null || try(var.node_pools[count.index].max_unavailable, null) != null) ? [1] : []
    content {
      max_unavailable_percentage = try(var.node_pools[count.index].max_unavailable_percentage, null)
      max_unavailable            = try(var.node_pools[count.index].max_unavailable, null)
    }
  }

  dynamic "remote_access" {
    for_each = var.key_pair_name_ssh_nodes_access != null ? [1] : []
    content {
      ec2_ssh_key               = var.key_pair_name_ssh_nodes_access
      source_security_group_ids = var.security_groups_ids_ssh_nodes_access
    }
  }

  labels = try(var.node_pools[count.index].labels, null)

  tags = merge(try(var.node_pools[count.index].tags, {}), {
    Name              = var.node_pools[count.index].node_group_name
    "tf-node-group"   = var.node_pools[count.index].node_group_name
    "tf-node-cluster" = "${var.cluster_name}"
    "tf-ou"           = var.ou_name
  })

  lifecycle {
    create_before_destroy = false
  }
}

resource "aws_autoscaling_group_tag" "create_nodes_autoscaler_label_tags" {
  count = length(aws_eks_node_group.create_eks_nodes_groups)

  autoscaling_group_name = "eks-${aws_eks_node_group.create_eks_nodes_groups[count.index].node_group_name}-${split("/", aws_eks_node_group.create_eks_nodes_groups[count.index].arn)[length(split("/", aws_eks_node_group.create_eks_nodes_groups[count.index].arn)) - 1]}"

  tag {
    key   = "Name"
    value = "${var.cluster_name}-eks${aws_eks_node_group.create_eks_nodes_groups[count.index].version}-${substr(aws_eks_node_group.create_eks_nodes_groups[count.index].node_group_name, 0, 3) == "tf-" ? substr(aws_eks_node_group.create_eks_nodes_groups[count.index].node_group_name, 3, length(aws_eks_node_group.create_eks_nodes_groups[count.index].node_group_name) - 1) : aws_eks_node_group.create_eks_nodes_groups[count.index].node_group_name}"

    propagate_at_launch = true
  }

  depends_on = [
    aws_eks_node_group.create_eks_nodes_groups
  ]
}
