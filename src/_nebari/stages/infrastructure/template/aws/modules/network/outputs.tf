output "security_group_id" {
  description = "AWS security group id"
  value       = local.aws_security_group.id
}

output "public_subnet_ids" {
  description = "AWS VPC public subnet ids"
  value       = local.public_subnets[*].id
}

output "private_subnet_ids" {
  description = "AWS VPC private subnet ids"
  value       = local.private_subnets[*].id
}

output "vpc_id" {
  description = "AWS VPC id"
  value       = local.vpc.id
}
