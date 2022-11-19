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

variable "eks_default_tags" {
  description = "EKS default tags"
  type        = map(any)
  default = {
    Name                                       = "tf-cluster-k8s"
    tf                                         = "tf-cluster-k8s"
    Scost                                      = "prod"
    Terraform                                  = true
    Environment                                = "prod"
    "eks:cluster-name"                         = "tf-cluster-k8s"
    "eks:nodegroup-name"                       = "tf-cluster-k8s"
    "k8s.io/cluster-autoscaler/enabled"        = true
    "k8s.io/cluster-autoscaler/tf-cluster-k8s" = "owned"
    "kubernetes.io/cluster/tf-cluster-k8s"     = "owned"
    "kubernetes.io/cluster/tf-cluster-k8s"     = "shared"
  }
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
