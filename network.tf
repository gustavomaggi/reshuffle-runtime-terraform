resource "aws_vpc" "main" {
  enable_dns_hostnames = true
  cidr_block           = var.vpcCidrBlock
  tags                 = merge(
    local.defaultTags,
    map(
        "Name", "reshuffle-${var.system}-vpc"
    )
  )
}

resource "aws_subnet" "subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpcCidrBlock, 2, count.index)
  count             = 2
  tags              = local.defaultTags
  availability_zone = element(["${var.region}a", "${var.region}b"], count.index)
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags   = local.defaultTags
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id
  tags   = local.defaultTags

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "ra" {
  depends_on     = [aws_subnet.subnet]
  count          = 2
  subnet_id      = element(aws_subnet.subnet.*.id, count.index)
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "sglb" {
  name        = "reshuffle-${var.system}-sglb"
  description = "Allow inbound HTTPS"
  vpc_id      = aws_vpc.main.id
  tags        = local.defaultTags

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sgecs" {
  name        = "reshuffle-${var.system}-sgecs"
  description = "ECS cluster group"
  vpc_id      = aws_vpc.main.id
  tags        = local.defaultTags

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = var.containerPort
    to_port         = var.containerPort
    protocol        = "tcp"
    security_groups = [aws_security_group.sglb.id]
  }
}

resource "aws_security_group" "sgdb" {
  count       = 0 < var.dbInstanceCount ? 1 : 0
  name        = "reshuffle-${var.system}-sgdb"
  description = "Database group"
  vpc_id      = aws_vpc.main.id
  tags        = local.defaultTags

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.sgecs.id]
  }
}
