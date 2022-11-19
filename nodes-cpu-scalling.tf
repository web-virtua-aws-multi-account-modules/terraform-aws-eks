resource "aws_autoscaling_policy" "create_scaling_cpu_up_policy" {
  count                  = length(aws_eks_node_group.create_eks_nodes_groups)
  name                   = "${aws_eks_node_group.create_eks_nodes_groups[count.index].node_group_name}-cpu-scale-up"
  adjustment_type        = "ChangeInCapacity"
  cooldown               = lookup(var.node_pools[count.index].cpu_scaling_configuration != null ? var.node_pools[count.index].cpu_scaling_configuration : var.default_cpu_scaling_configuration, "scale_up_cooldown")
  scaling_adjustment     = lookup(var.node_pools[count.index].cpu_scaling_configuration != null ? var.node_pools[count.index].cpu_scaling_configuration : var.default_cpu_scaling_configuration, "scale_up_add")
  autoscaling_group_name = aws_eks_node_group.create_eks_nodes_groups[count.index].resources[0].autoscaling_groups[0].name
}

resource "aws_cloudwatch_metric_alarm" "create_metric_cpu_up_alarm" {
  count               = length(aws_eks_node_group.create_eks_nodes_groups)
  alarm_name          = "${aws_eks_node_group.create_eks_nodes_groups[count.index].node_group_name}-cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  statistic           = "Average"
  evaluation_periods  = lookup(var.node_pools[count.index].cpu_scaling_configuration != null ? var.node_pools[count.index].cpu_scaling_configuration : var.default_cpu_scaling_configuration, "scale_up_evaluation")
  period              = lookup(var.node_pools[count.index].cpu_scaling_configuration != null ? var.node_pools[count.index].cpu_scaling_configuration : var.default_cpu_scaling_configuration, "scale_up_period")
  threshold           = lookup(var.node_pools[count.index].cpu_scaling_configuration != null ? var.node_pools[count.index].cpu_scaling_configuration : var.default_cpu_scaling_configuration, "scale_up_threshold")

  dimensions = {
    AutoScalingGroupName = aws_eks_node_group.create_eks_nodes_groups[count.index].resources[0].autoscaling_groups[0].name
  }

  alarm_actions = [aws_autoscaling_policy.create_scaling_cpu_up_policy[count.index].arn]

  tags = {
    Name = "${aws_eks_node_group.create_eks_nodes_groups[count.index].node_group_name}-cpu-high"
  }
}

resource "aws_autoscaling_policy" "create_scaling_cpu_down_policy" {
  count                  = length(aws_eks_node_group.create_eks_nodes_groups)
  name                   = "${aws_eks_node_group.create_eks_nodes_groups[count.index].node_group_name}-cpu-scale-down"
  adjustment_type        = "ChangeInCapacity"
  cooldown               = lookup(var.node_pools[count.index].cpu_scaling_configuration != null ? var.node_pools[count.index].cpu_scaling_configuration : var.default_cpu_scaling_configuration, "scale_down_cooldown")
  scaling_adjustment     = lookup(var.node_pools[count.index].cpu_scaling_configuration != null ? var.node_pools[count.index].cpu_scaling_configuration : var.default_cpu_scaling_configuration, "scale_down_remove")
  autoscaling_group_name = aws_eks_node_group.create_eks_nodes_groups[count.index].resources[0].autoscaling_groups[0].name
}

resource "aws_cloudwatch_metric_alarm" "create_metric_cpu_down_alarm" {
  count               = length(aws_eks_node_group.create_eks_nodes_groups)
  alarm_name          = "${aws_eks_node_group.create_eks_nodes_groups[count.index].node_group_name}-cpu-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  statistic           = "Average"
  evaluation_periods  = lookup(var.node_pools[count.index].cpu_scaling_configuration != null ? var.node_pools[count.index].cpu_scaling_configuration : var.default_cpu_scaling_configuration, "scale_down_evaluation")
  period              = lookup(var.node_pools[count.index].cpu_scaling_configuration != null ? var.node_pools[count.index].cpu_scaling_configuration : var.default_cpu_scaling_configuration, "scale_down_period")
  threshold           = lookup(var.node_pools[count.index].cpu_scaling_configuration != null ? var.node_pools[count.index].cpu_scaling_configuration : var.default_cpu_scaling_configuration, "scale_down_threshold")

  dimensions = {
    AutoScalingGroupName = aws_eks_node_group.create_eks_nodes_groups[count.index].resources[0].autoscaling_groups[0].name
  }

  alarm_actions = [aws_autoscaling_policy.create_scaling_cpu_down_policy[count.index].arn]

  tags = {
    Name = "${aws_eks_node_group.create_eks_nodes_groups[count.index].node_group_name}-cpu-down"
  }
}
