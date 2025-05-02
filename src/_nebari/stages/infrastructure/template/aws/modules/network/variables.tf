variable "name" {
  description = "Prefix name to give to network resources"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to all network resource"
  type        = map(string)
  default     = {}
}

variable "vpc_tags" {
  description = "Additional tags to apply to vpc network resource"
  type        = map(string)
  default     = {}
}

variable "subnet_tags" {
  description = "Additional tags to apply to subnet network resources"
  type        = map(string)
  default     = {}
}

variable "security_group_tags" {
  description = "Additional tags to apply to security group network resource"
  type        = map(string)
  default     = {}
}

variable "aws_availability_zones" {
  description = "AWS Availability zones to operate infrastructure"
  type        = list(string)
}

variable "vpc_cidr_block" {
  description = "VPC cidr for subnets to be inside of"
  type        = string
}

variable "vpc_cidr_newbits" {
  description = "VPC cidr number of bits to support 2^N subnets"
  type        = number
  default     = 2 # allows 4 /18 subnets with 16382 addresses each
}

variable "region" {
  description = "AWS region to operate infrastructure"
  type        = string

}

variable "existing_security_group_id" {
  description = "Existing security group ID to use for Kubernetes resources"
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


