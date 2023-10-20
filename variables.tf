# ----------------------------------------------------------------#
# EKS cluster
# ----------------------------------------------------------------#
variable "cluster_name" {
  description = "Cluster name EKS"
  type        = string
  default     = "tf-cluster-k8s"
}

variable "vpc_id" {
  description = "Cluster VPC ID"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "List with subnets IDs to cluster"
  type        = list(string)
  default     = null
}

variable "security_groups_ids" {
  description = "List with security groups IDs to cluster"
  type        = list(string)
  default     = null
}

variable "k8s_version" {
  description = "Kuberntes version"
  type        = string
  default     = "1.23"
}

variable "key_pair_name_ssh_nodes_access" {
  description = "Key pair name to SSH nodes access"
  type        = string
  default     = null
}

variable "security_groups_ids_ssh_nodes_access" {
  description = "Security groups ID's to access SSH"
  type        = list(string)
  default     = null
}

variable "use_eks_default_tags" {
  description = "If use EKS default tags"
  type        = bool
  default     = true
}

variable "retention_cloudwatch_log_group" {
  description = "Days to logs retention on CloudWatch"
  type        = number
  default     = 0
}

variable "enabled_cluster_log_types" {
  description = "Enabled cluster log types can be configured with the values api, audit, authenticator, controllerManager and scheduler"
  type        = list(string)
  default     = []
}

variable "eks_endpoint_private_access" {
  description = "If has cluster endpoint private access"
  type        = bool
  default     = false
}

variable "eks_endpoint_public_access" {
  description = "If has cluster endpoint public access"
  type        = bool
  default     = true
}

variable "eks_endpoint_public_access_cidrs" {
  description = "EKS endpoint public access cidrs"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "eks_ip_family" {
  description = "EKS IP family can be IPV4 or IPV6"
  type        = string
  default     = "ipv4"
}

variable "eks_service_ipv4_cidr" {
  description = "EKS network config CIDR, ex: 10.100.0.0/16 or 172.20.0.0/16"
  type        = string
  default     = "172.20.0.0/16"
}

variable "ou_name" {
  description = "Organization unit name"
  type        = string
  default     = "no"
}

variable "tags" {
  description = "Tags to EKS"
  type        = map(any)
  default     = {}
}

variable "eks_timeouts" {
  description = "Define cluster timeouts"
  type = object({
    create = string
    update = string
    delete = string
  })
  default = {
    create = null
    update = null
    delete = null
  }
}

variable "cluster_environment" {
  description = "Cluster environment, ex: prod, dev..."
  type        = string
  default     = "prod"
}

# ----------------------------------------------------------------#
# New network
# ----------------------------------------------------------------#
variable "make_new_network" {
  description = "If true it will create a new network and will be used in the cluster"
  type        = bool
  default     = false
}

variable "public_subnets" {
  description = "Define the public subnets configuration to new network"
  type = list(object({
    cidr_block              = string
    availability_zone       = string
    map_public_ip_on_launch = optional(bool)
    tags                    = optional(map(any))
  }))
  default = [
    {
      cidr_block              = "10.0.1.0/24"
      availability_zone       = "us-east-1a"
      map_public_ip_on_launch = true
      tags                    = {}
    }
  ]
}

variable "private_subnets" {
  description = "Define the private subnets configuration to new network"
  type = list(object({
    cidr_block              = string
    availability_zone       = string
    map_public_ip_on_launch = optional(bool)
    tags                    = optional(map(any))
  }))
  default = [
    {
      cidr_block              = "10.0.3.0/24"
      availability_zone       = "us-east-1a"
      map_public_ip_on_launch = true
      tags                    = {}
    },
    {
      cidr_block              = "10.0.4.0/24"
      availability_zone       = "us-east-1b"
      is_private              = true
      map_public_ip_on_launch = true
    },
  ]
}

# ----------------------------------------------------------------#
# Node pools
# ----------------------------------------------------------------#
variable "node_pools" {
  description = "Define the node pools configuration"
  type = list(object({
    node_group_name            = string
    subnet_ids                 = optional(list(string))
    eks_node_version           = optional(string)
    force_update_version       = optional(bool)
    disk_size                  = optional(number)
    instance_types             = optional(list(string))
    capacity_type              = optional(string)
    desired_capacity           = optional(number)
    min_capacity_size          = optional(number)
    max_capacity_size          = optional(number)
    max_unavailable            = optional(number)
    max_unavailable_percentage = optional(number)
    node_ami_type              = optional(string)
    node_ami_release_version   = optional(string)
    labels                     = optional(map(any))
    tags                       = optional(map(any))
    cpu_scaling_configuration = optional(object({
      scale_up_threshold    = number
      scale_up_period       = number
      scale_up_evaluation   = number
      scale_up_cooldown     = number
      scale_up_add          = number
      scale_down_threshold  = number
      scale_down_period     = number
      scale_down_evaluation = number
      scale_down_cooldown   = number
      scale_down_remove     = number
    }))
  }))
  default = []
}

variable "default_cpu_scaling_configuration" {
  description = "Default cpu scaling configuration to all nodes if not exists cpu_scaling_configuration in node_pools variable"
  type = object({
    scale_up_threshold    = number
    scale_up_period       = number
    scale_up_evaluation   = number
    scale_up_cooldown     = number
    scale_up_add          = number
    scale_down_threshold  = number
    scale_down_period     = number
    scale_down_evaluation = number
    scale_down_cooldown   = number
    scale_down_remove     = number
  })
  default = {
    scale_up_threshold    = 80
    scale_up_period       = 60
    scale_up_evaluation   = 2
    scale_up_cooldown     = 300
    scale_up_add          = 2
    scale_down_threshold  = 40
    scale_down_period     = 120
    scale_down_evaluation = 2
    scale_down_cooldown   = 300
    scale_down_remove     = -1
  }
}

# ----------------------------------------------------------------#
# Permissions
# ----------------------------------------------------------------#
variable "role_policy_metrics_cusmized_name" {
  description = "This variable is required if create more than one cluster in the same account, if defined will be used these name to roles, policies and resources names that must not has the same name"
  type = string
  default = null
}

variable "use_tags_default" {
  description = "If true will be use the tags default"
  type        = bool
  default     = true
}

variable "tags_autoscaler" {
  description = "Tags to autocaler policy"
  type        = map(any)
  default     = {}
}

variable "manage_aws_auth" {
  description = "If true will be management aws auth, else will be create the basic access to user the created the cluster"
  type        = bool
  default     = true
}

variable "make_policy_role_provider_autoscaler" {
  description = "If true will be create a policy, role and identity provider to allow autocaler on cluster"
  type        = bool
  default     = true
}

variable "make_role_ebs_csi_driver" {
  description = "If true will be create a role to allow EBS CSI driver on cluster"
  type        = bool
  default     = true
}

variable "eks_addons" {
  description = "List with additional addons to enable on cluster"
  type = list(object({
    addon_name               = string
    resolve_conflicts        = optional(string)
    service_account_role_arn = optional(string)
    addon_version            = optional(string)
    tags                     = optional(any)
  }))
  default = []
}

variable "map_users" {
  description = "Additional IAM users to add to the aws-auth configmap"
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "map_roles" {
  description = "Additional IAM roles to add to the aws-auth configmap"
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "map_accounts" {
  description = "Additional AWS account numbers to add to the aws-auth configmap"
  type        = list(string)
  default     = []
}

variable "identity_provider_audiences" {
  description = "List with to specify the client ID issued by the Identity provider for your app, ex: sts.amazonaws.com"
  type        = list(string)
  default     = ["sts.amazonaws.com"]
}

variable "cluster_autoscaler_policy" {
  description = "Cluster autoscaler policy"
  type = object({
    name        = string
    policy      = any
    path        = optional(string)
    description = optional(string)
  })
  default = {
    name        = "tf-amazon-eks-cluster-autoscaler-policy"
    description = "Policy to autoscaling on EKS."
    policy = {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "autoscaling:DescribeAutoScalingGroups",
            "autoscaling:DescribeAutoScalingInstances",
            "autoscaling:DescribeLaunchConfigurations",
            "autoscaling:DescribeTags",
            "autoscaling:SetDesiredCapacity",
            "autoscaling:TerminateInstanceInAutoScalingGroup",
            "ec2:DescribeLaunchTemplateVersions"
          ],
          "Resource" : "*",
          "Effect" : "Allow"
        }
      ]
    }
  }
}
