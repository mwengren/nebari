variable "name" {
  description = "Prefix name to assign to Nebari resources"
  type        = string
}

variable "environment" {
  description = "Environment to create Kubernetes resources"
  type        = string
}

variable "vpc_id" {
  description = "Existing VPC ID to use"
  type = string

  default = null

  validation {
    condition     = var.vpc_id == null ? true : ( length(var.vpc_id) > 4 && substr(var.vpc_id, 0, 4) == "vpc-" )
    error_message = "The vpc_id value must start with \"vpc-\"."
  }
}

variable "public_subnet_ids" {
  description = "The IDs of existing public subnet(s) within the target VPC to use, if any (optional)."
  type = list(string)
  default = null

  #todo: the validation should check each subnet in the list, not just the first one [0]
  validation {
    condition     = var.public_subnet_ids == null ? true : ( length(var.public_subnet_ids[0]) > 7 && substr(var.public_subnet_ids[0], 0, 7) == "subnet-" )
    error_message = "The subnet_id value must start with \"subnet-\"."
  }

}

variable "private_subnet_ids" {
  description = "The IDs of existing private subnet(s) within the target VPC to use, if any (optional)."
  type = list(string)
  default = null

  #todo: the validation should check each subnet in the list, not just the first one [0]
  validation {
    condition     = var.private_subnet_ids == null ? true : ( length(var.private_subnet_ids[0]) > 7 && substr(var.private_subnet_ids[0], 0, 7) == "subnet-" )
    error_message = "The subnet_id value must start with \"subnet-\"."
  }

}


variable "existing_subnet_ids" {
  description = "Existing VPC ID to use for Kubernetes resources"
  type        = list(string)
}

variable "existing_security_group_id" {
  description = "Existing security group ID to use for Kubernetes resources"
  type        = string
}

variable "region" {
  description = "AWS region for EKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "AWS kubernetes version for EKS cluster"
  type        = string
}

variable "node_groups" {
  description = "AWS node groups"
  type = list(object({
    name            = string
    instance_type   = string
    gpu             = bool
    min_size        = number
    desired_size    = number
    max_size        = number
    single_subnet   = bool
    launch_template = map(any)
    ami_type        = string
  }))
}

variable "availability_zones" {
  description = "AWS availability zones within AWS region"
  type        = list(string)
}

variable "vpc_cidr_block" {
  description = "VPC cidr block for infrastructure"
  type        = string
}

variable "kubeconfig_filename" {
  description = "Kubernetes kubeconfig written to filesystem"
  type        = string
}

variable "eks_endpoint_access" {
  description = "EKS cluster api server endpoint access setting"
  type        = string
  default     = "public"
}

variable "eks_endpoint_private_access" {
  type    = bool
  default = false
}

variable "eks_kms_arn" {
  description = "kms key arn for EKS cluster encryption_config"
  type        = string
  default     = null
}

variable "eks_public_access_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "permissions_boundary" {
  description = "ARN of the policy that is used to set the permissions boundary for the role"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags to add to resources"
  type        = map(string)
  default     = {}
}

variable "efs_enabled" {
  description = "Enable EFS"
  type        = bool
}
