# AWS EKS cluster for multiples accounts and regions in Terraform module
* This module simplifies creating and configuring EKS cluster across multiple accounts and regions on AWS

* Is possible use this module with one region using the standard profile or multi account and regions using multiple profiles setting in the modules.
* This module can use an existing network or creating a new network during cluster creation.

## Actions necessary to use this module:

* Create file versions.tf with the exemple code below:
```hcl
terraform {
  required_version = ">= 1.1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.9"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 2.0"
    }
  }
}
```

* Criate file provider.tf with the exemple code below:
```hcl
provider "aws" {
  alias   = "alias_profile_a"
  region  = "us-east-1"
  profile = "my-profile"
}

provider "aws" {
  alias   = "alias_profile_b"
  region  = "us-east-2"
  profile = "my-profile"
}
```


## Features enable of S3 EKS cluster configurations for this module:

- EKS cluster
- Nodes Groups
- Node pools auto scaling
- Policy and roles to cluster and nodes groups
- Autoscaler configuration
- Addons
- AWS auth manager
- Network creation or use of existing 

## Usage exemples
* PS: This module implements all the necessary settings to autoscale and use EBS volumes, these settings may not be implemented if they are not going to be used, for that it is only necessary to set the variables to false, how to do this can be seen in the variable's documentation.

* For the autoscaler to actually happen, it will still need some settings in a .yaml file, this file will have the final settings needed for the scalar cluster, the core of the file is in the url below and will need to be changed according to the documentation.
URL file: https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover

* Full documentation url: 
https://docs.aws.amazon.com/pt_br/eks/latest/userguide/cluster-autoscaler.html

### Create cluster with existing network

```hcl
module "eks_compute_dev" {
  source           = "web-virtua-aws-multi-account-modules/eks/aws"
  cluster_name     = "tf-cluster-k8s"
  k8s_version      = "1.24"
  vpc_id           = var.vpc_id
  subnet_ids       = var.privete_subnets_ids
  node_pools       = var.node_pools
  ou_name          = var.ous.sso

  providers = {
    aws = aws.alias_profile_b
  }
}
```

### Create cluster with existing network and managment users and roles RBAC

```hcl
module "eks_compute_dev" {
  source           = "web-virtua-aws-multi-account-modules/eks/aws"
  cluster_name     = "tf-cluster-k8s"
  k8s_version      = "1.24"
  vpc_id           = var.vpc_id
  subnet_ids       = var.privete_subnets_ids
  node_pools       = var.node_pools
  ou_name          = var.ous.sso

  map_users = [
    {
      userarn  = "arn:aws:iam::123456789:user/user.name"
      username = "user.name"
      groups   = ["system:masters"]
    },
  ]

  map_roles = [
    {
      rolearn  = "arn:aws:iam::123456789:role/role.name"
      username = "role.name"
      groups = [
        "system:masters"
      ]
    }
  ]

  providers = {
    aws = aws.alias_profile_a
  }
}
```

### Create cluster creating a new network

```hcl
module "eks_compute_dev" {
  source           = "web-virtua-aws-multi-account-modules/eks/aws"
  make_new_network = true
  cluster_name     = "tf-cluster-k8s"
  k8s_version      = "1.24"
  node_pools       = var.node_pools

  providers = {
    aws = aws.alias_profile_b
  }
}
```

## EKS Variables

| Name | Type | Default | Required | Description | Options |
|------|-------------|------|---------|:--------:|:--------|
| cluster_name | `string` | `tf-cluster-k8s` | no | Cluster name EKS | `-` |
| vpc_id | `string` | `null` | no | Cluster VPC ID, It's required if make_new_network set false | `-` |
| subnet_ids | `list(string)` | `null` | no | List with subnets IDs to cluster, It's required if make_new_network set false | `-` |
| security_groups_ids | `list(string)` | `null` | no | List with security groups IDs to cluster | `-`|
| k8s_version | `string` | `1.24` | no | Kuberntes version | `-` |
| cluster_environment | `string` | `prod` | no | Cluster environment, ex: prod, dev... | `-` |
| key_pair_name_ssh_nodes_access | `string` | `null` | no | Key pair name to SSH nodes access | `-` |
| security_groups_ids_ssh_nodes_access | `list(string)` | `null` | no | Security groups ID's to access SSH | `-`|
| use_eks_default_tags | `bool` | `true` | no | If use EKS default tags | `*`true<br> `*`false |
| retention_cloudwatch_log_group | `number` | `0` | no | Days to logs retention on CloudWatch | `-` |
| enabled_cluster_log_types | `list(strign)` | `[]` | no | Enabled cluster log types | `*`api<br> `*`audit<br> `*`authenticator<br> `*`controllerManager<br> `*`scheduler |
| eks_endpoint_private_access | `bool` | `false` | no | If has cluster endpoint private access | `*`true<br> `*`false |
| eks_endpoint_public_access | `bool` | `true` | no | If has cluster endpoint public access | `*`true<br> `*`false |
| eks_endpoint_public_access_cidrs | `list(string)` | `["0.0.0.0/0"]` | no | EKS endpoint public access cidrs | `-`|
| eks_ip_family | `string` | `ipv4` | no | EKS IP family can be IPV4 or IPV6 | `-` |
| eks_service_ipv4_cidr | `string` | `172.20.0.0/16` | no | EKS network config CIDR, ex: 10.100.0.0/16 or 172.20.0.0/16 | `-` |
| ou_name | `string` | `no` | no | Organization unit name | `-` |
| tags | `map(any)` | `{}` | no | Tags to EKS cluster | `-` |
| eks_timeouts | `map(object)` | `object` | no | Define cluster timeouts | `-`|
| use_tags_default | `bool` | `true` | no | If true will be use the tags default | `*`true<br> `*`false |
| tags_autoscaler | `map(any)` | `object` | no | Tags to autocaler policy | `-`|
| manage_aws_auth | `bool` | `true` | no | If true will be management aws auth, else will be create the basic access to user the created the cluster | `*`true<br> `*`false |
| make_policy_role_provider_autoscaler | `bool` | `true` | no | If true will be create a policy, role and identity provider to allow autocaler on cluster | `*`true<br> `*`false |
| make_role_ebs_csi_driver | `bool` | `true` | no | If true will be create a role to allow EBS CSI driver on cluster | `*`true<br> `*`false |
| eks_addons | `list(object)` | `[]` | no | List with additional addons to enable on cluster | `-`|
| map_users | `list(object)` | `[]` | no | Additional IAM users to add to the aws-auth configmap | `-`|
| map_roles | `list(object)` | `[]` | no | Additional IAM roles to add to the aws-auth configmap | `-`|
| map_accounts | `list(string)` | `[]` | no | Additional AWS account numbers to add to the aws-auth configmap | `-`|
| identity_provider_audiences | `list(string)` | `["sts.amazonaws.com"]` | no | List with to specify the client ID issued by the Identity provider for your app, ex: sts.amazonaws.com | `-`|
| cluster_autoscaler_policy | `list(object)` | `object` | no | Cluster autoscaler policy | `-`|

* Examples of object populated by default in the eks_timeouts variable
```hcl
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
```

* Examples to eks_addons variable
```hcl
variable "eks_addons" {
  description = "List with additional addons to enable on cluster"
  type = list(object({
    addon_name               = string
    resolve_conflicts        = optional(string)
    service_account_role_arn = optional(string)
    addon_version            = optional(string)
    tags                     = optional(any)
  }))
  default = [
    {
      cluster_name             = var.cluster_name
      addon_name               = "aws-ebs-csi-driver"
      resolve_conflicts        = "OVERWRITE"
    }
  ]
}
```

* Examples to map_users variable
```hcl
variable "map_users" {
  description = "Additional IAM users to add to the aws-auth configmap"
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = [
    {
      userarn  = var.user_arn
      username = var.user_name
      groups   = ["system:masters"]
    }
  ]
}
```

* Examples to map_roles variable
```hcl
variable "map_roles" {
  description = "Additional IAM roles to add to the aws-auth configmap"
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = [
    {
      rolearn  = "arn:aws:iam::123456789:role/role.name"
      username = "role.name"
      groups = [
        "system:masters"
      ]
    }
  ]
}
```

* Examples to map_accounts variable
```hcl
variable "map_accounts" {
  description = "Additional AWS account numbers to add to the aws-auth configmap"
  type        = list(string)
  default     = [
    "123456789"
  ]
}
```

* Examples to identity_provider_audiences variable
```hcl
variable "identity_provider_audiences" {
  description = "List with to specify the client ID issued by the Identity provider for your app, ex: sts.amazonaws.com"
  type        = list(string)
  default     = ["sts.amazonaws.com"]
}
```

* Examples to cluster_autoscaler_policy variable
```hcl
variable "cluster_autoscaler_policy" {
  description = "Cluster autoscaler policy"
  type = object({
    name        = string
    policy      = any
    path        = optional(string)
    description = optional(string)
  })
  default = {
    name        = "AmazonEKSClusterAutoscalerPolicy"
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
```


## Network Variables

| Name | Type | Default | Required | Description | Options |
|------|-------------|------|---------|:--------:|:--------|
| make_new_network | `bool` | `false` | no | If true it will create a new network and will be used in the cluster | `*`true<br> `*`false |
| public_subnets | `list(object)` | `object` | no | Define the public subnets configuration to new network | `-` |
| private_subnets | `list(object)` | `object` | no | Define the private subnets configuration to new network | `-` |

* Examples of object populated by default in the public_subnets variable, if variable make_new_network set true
```hcl
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
```
* Examples of object populated by default in the private_subnets variable, if variable make_new_network set true
```hcl
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
```

## Node Pools Variables

| Name | Type | Default | Required | Description | Options |
|------|-------------|------|---------|:--------:|:--------|
| node_pools | `list(object)` | `[]` | no | Define the node pools configuration | `-` |
| default_cpu_scaling_configuration | `list(object)` | `object` | no | Default cpu scaling configuration to all nodes if not exists cpu_scaling_configuration in node_pools variable | `-` |

* Examples of object populated by default in the default_cpu_scaling_configuration variable
```hcl
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
```


variable "nodes_ami_type" {
  description = "Node ami type, can be AL2_x86_64, AL2_x86_64_GPU, AL2_ARM_64, CUSTOM, BOTTLEROCKET_ARM_64, BOTTLEROCKET_x86_64, BOTTLEROCKET_ARM_64_NVIDIA or BOTTLEROCKET_x86_64_NVIDIA"
  type        = list(string)
  default     = null
}


* Model of variable public_subnets
```hcl
variable "public_subnets" {
  description = "Define the public subnets configuration"
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
    },
    {
      cidr_block              = "10.0.2.0/24"
      availability_zone       = "us-east-1b"
      is_private              = true
      map_public_ip_on_launch = true
    },
  ]
}
```

* Model of variable private_subnets
```hcl
variable "private_subnets" {
  description = "Define the private subnets configuration"
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
```

* Model of variable node_pools
```hcl
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
  default = [
    {
      node_group_name  = "tf-node-pool-demand-1",
      eks_node_version = "1.23",
      disk_size        = 25,
      subnet_ids = [
        "subnet-05c6c...a4082",
        "subnet-0f2ec...l34fa"
      ],
      instance_types    = ["t3a.medium"],
      capacity_type     = "ON_DEMAND",
      desired_capacity  = 2,
      min_capacity_size = 1,
      max_capacity_size = 4,
      cpu_scaling_configuration = {
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
    },
  ]
}
```

## Resources

| Name | Type |
|------|------|
| [aws_eks_cluster.create_eks_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster) | resource |
| [aws_cloudwatch_log_group.create_cloudwatch_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_security_group.create_sec_group_eks_internal](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_eks_node_group.create_eks_nodes_groups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group) | resource |
| [aws_iam_role.create_eks_cluster_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.create_attach_eks_cluster_policy_on_eks_cluste_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.create_attach_eks_service_policy_on_eks_cluste_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_policy.create_lb_controller_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role_policy_attachment.create_attach_lb_controller_policy_on_eks_cluste_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.create_eks_nodes_roles](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.create_attach_eks_cni_policy_on_eks_nodes_roles](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.create_attach_eks_worker_node_policy_on_eks_nodes_roles](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.create_attach_ec2_ecr_policy_on_eks_nodes_roles](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_autoscaling_policy.create_scaling_cpu_up_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_policy) | resource |
| [aws_cloudwatch_metric_alarm.create_metric_cpu_up_alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_autoscaling_policy.create_scaling_cpu_down_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_policy) | resource |
| [aws_cloudwatch_metric_alarm.create_metric_cpu_down_alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_iam_policy.create_autoscaler_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_openid_connect_provider.create_oidc_identity_provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_role.create_autoscaler_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.create_attach_autoscaler_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.create_ebs_management_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_eks_addon.create_ebs_addon](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_addon.create_others_addons](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [kubernetes_config_map_v1_data.aws_auth](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map_v1_data) | resource |
| [aws_autoscaling_group_tag.create_nodes_autoscaler_label_tags](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group_tag) | resource |


## Outputs

| Name | Description |
|------|-------------|
| `eks_cluster` | All informations of the EKS cluster |
| `eks_cluster_name` | EKS cluster name |
| `eks_security_group_internal` | All informations of the EKS cluster security group internal |
| `eks_endpoint` | EKS cluster endpoint |
| `eks_kubeconfig_certificate_authority_data` | EKS eks kubeconfig certificate authority data|
| `cloudwatch_log_group` | All informations of the EKS cloudwathc log group |
| `vpc_new` | All informations of the new network|
| `vpc_new_id` | VPC ID of the new network|
| `vpc_new_internet_gateway` | Internet gateway of the new network|
| `vpc_new_nat_gateway` | NAT gateway of the new network|
| `vpc_new_subnets` | Subnets of the new network|
| `vpc_new_private_subnets_ids` | Private subnets ID's of the new network|
| `vpc_new_public_subnets_ids` | Public subnets ID's of the new network|
| `eks_nodes_groups` | All informations of the EKS nodes groups |
| `eks_cluster_role` | All informations of the EKS cluster role |
| `lb_controller_policy` | All informations of the EKS load balance controller poliby|
| `eks_nodes_roles` | All informations of the EKS nodes roles |
| `scaling_cpu_up_policy` | All informations of the EKS scaling CPU up policy |
| `scaling_cpu_down_policy` | All informations of the EKS scaling CPU down policy |
| `metric_cpu_up_alarm` | All informations of the EKS metric CPU up cloudwatch alarm |
| `metric_cpu_down_alarm` | All informations of the EKS metric CPU down cloudwatch alarm |
| `autoscaler_policy` | Policy to autoscaler |
| `oidc_identity_provider` | OIDC identity provider |
| `iam_autoscaler_role` | Role to autoscaler |
| `iam_autoscaler_role_arn` | Role ARN to autoscaler, this role will be used in autoscaler cluster configuration file |
| `ebs_management_role` | Role to EBS managment |
| `eks_addons` | EKS addons |
| `aws_auth` | AWS authorization on cluster |
| `nodes_autoscaler_label_tags` | Nodes autoscaler label tags to VMs |
