locals {
  vpc = var.vpc_id == null ? one(aws_vpc.main[*]) : one(data.aws_vpc.main[*]) 
  public_subnets = var.public_subnet_ids == null ? aws_subnet.public[*] : data.aws_subnet.public[*] 
  private_subnets = var.private_subnet_ids == null ? aws_subnet.private[*] : data.aws_subnet.private[*] 
  private_route_tables = var.private_subnet_ids == null ? aws_route_table.private[*] : data.aws_route_table.private[*]
  aws_security_group = var.existing_security_group_id == null ? aws_security_group.main : data.aws_security_group.main
}

resource "aws_vpc" "main" {
  count = var.vpc_id == null ? 1 : 0
  cidr_block = var.vpc_cidr_block

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge({ Name = var.name }, var.tags, var.vpc_tags)
}

data "aws_vpc" "main" {
  count = var.vpc_id == null ? 0 : 1
  id = var.vpc_id
}

resource "aws_subnet" "public" {
  #count = length(var.aws_availability_zones)
  #count = var.public_subnet_ids != null ? length(var.public_subnet_ids) : length(var.aws_availability_zones)
  count = var.public_subnet_ids == null ? length(var.aws_availability_zones) : 0

  availability_zone = var.aws_availability_zones[count.index]
  cidr_block        = cidrsubnet(var.vpc_cidr_block, var.vpc_cidr_newbits, count.index)
  vpc_id            = aws_vpc.main.id

  tags = merge({ Name = "${var.name}-pulbic-subnet-${count.index}", "kubernetes.io/role/elb" = 1 }, var.tags, var.subnet_tags)

  lifecycle {
    ignore_changes = [
      availability_zone
    ]
  }
}

moved {
  from = aws_subnet.main
  to   = aws_subnet.public
}

data "aws_subnet" "public" {
  #count = var.subnet_id != null ? 1 : 0
  count = length(var.public_subnet_ids)
  id = var.public_subnet_ids[count.index]
}

resource "aws_subnet" "private" {
  #count = length(var.aws_availability_zones)
  count = var.private_subnet_ids == null ? length(var.aws_availability_zones) : 0

  availability_zone = var.aws_availability_zones[count.index]
  cidr_block        = cidrsubnet(var.vpc_cidr_block, var.vpc_cidr_newbits, count.index + length(var.aws_availability_zones))
  vpc_id            = aws_vpc.main.id

  tags = merge({ Name = "${var.name}-private-subnet-${count.index}" }, var.tags, var.subnet_tags)

  lifecycle {
    ignore_changes = [
      availability_zone
    ]
  }
}

data "aws_subnet" "private" {
  #count = var.subnet_id != null ? 1 : 0
  count = length(var.private_subnet_ids)
  id = var.private_subnet_ids[count.index]
}

resource "aws_internet_gateway" "main" {
  count = var.vpc_id == null ? 1 : 0
  vpc_id = local.vpc.id

  tags = merge({ Name = var.name }, var.tags)
}

resource "aws_eip" "nat-gateway-eip" {
  #count = length(var.aws_availability_zones)
  count = var.public_subnet_ids == null ? length(var.aws_availability_zones) : 0

  domain = "vpc"

  tags = merge({ Name = "${var.name}-nat-gateway-eip-${count.index}" }, var.tags)
}

resource "aws_nat_gateway" "main" {
  #count = length(var.aws_availability_zones)
  count = var.public_subnet_ids == null ? length(var.aws_availability_zones) : 0

  allocation_id = aws_eip.nat-gateway-eip[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags       = merge({ Name = "${var.name}-nat-gateway-${count.index}" }, var.tags)
  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "public" {
  count = var.vpc_id == null ? 1 : 0
  vpc_id = local.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge({ Name = var.name }, var.tags)
}

moved {
  from = aws_route_table.main
  to   = aws_route_table.public
}

resource "aws_route_table" "private" {
  #count = length(var.aws_availability_zones)
  count = var.private_subnet_ids == null ? length(var.aws_availability_zones) : 0

  vpc_id = local.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = merge({ Name = var.name }, var.tags)
}

data "aws_route_table" "private" {
  count = var.private_subnet_ids == null ? 0 : length(var.private_subnet_ids)
  subnet_id = var.private_subnet_ids[count.index]
}

resource "aws_route_table_association" "public" {
  #count = length(var.aws_availability_zones)
  count = var.vpc_id == null ? length(var.aws_availability_zones) : 0

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  #count = length(var.aws_availability_zones)
  count = var.private_subnet_ids == null ? length(var.aws_availability_zones) : 0

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_security_group" "main" {
  count = var.existing_security_group_id == null ? 1 : 0
  name        = var.name
  description = "Main security group for infrastructure deployment"

  vpc_id = local.vpc.id

  ingress {
    description = "Allow all ports and protocols to enter the security group"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr_block]
  }

  egress {
    description = "Allow all ports and protocols to exit the security group"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({ Name = var.name }, var.tags, var.security_group_tags)
}

data "aws_security_group" "main" {
  count = var.existing_security_group_id == null ? 0 : 1
  id = var.existing_security_group_id
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = local.vpc.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  # need to obtain private route tables in a local variable list and use here:
  route_table_ids   = local.private_route_tables[*].id
  tags              = merge({ Name = "${var.name}-s3-endpoint" }, var.tags)
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = local.vpc.id
  service_name        = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  security_group_ids  = [local.aws_security_group.id]
  subnet_ids          = local.private_subnets[*].id
  tags                = merge({ Name = "${var.name}-ecr-api-endpoint" }, var.tags)
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = local.vpc.id
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  security_group_ids  = [local.aws_security_group.id]
  subnet_ids          = local.private_subnets[*].id
  tags                = merge({ Name = "${var.name}-ecr-dkr-endpoint" }, var.tags)
}

resource "aws_vpc_endpoint" "elasticloadbalancing" {
  vpc_id              = local.vpc.id
  service_name        = "com.amazonaws.${var.region}.elasticloadbalancing"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  security_group_ids  = [local.aws_security_group.id]
  subnet_ids          = local.private_subnets[*].id
  tags                = merge({ Name = "${var.name}-elb-endpoint" }, var.tags)
}

resource "aws_vpc_endpoint" "sts" {
  vpc_id              = local.vpc.id
  service_name        = "com.amazonaws.${var.region}.sts"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  security_group_ids  = [local.aws_security_group.id]
  subnet_ids          = local.private_subnets[*].id
  tags                = merge({ Name = "${var.name}-sts-endpoint" }, var.tags)
}

resource "aws_vpc_endpoint" "eks" {
  vpc_id              = local.vpc.id
  service_name        = "com.amazonaws.${var.region}.eks"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  security_group_ids  = [local.aws_security_group.id]
  subnet_ids          = local.private_subnets[*].id
  tags                = merge({ Name = "${var.name}-eks-endpoint" }, var.tags)
}
