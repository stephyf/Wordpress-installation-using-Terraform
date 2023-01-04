resource "aws_vpc" "terraformvpc" {

  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.project}-${var.environment}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.terraformvpc.id
  tags = {
    Name = "${var.project}-${var.environment}"
  }
}

resource "aws_subnet" "public" {

  count                   = local.subnets
  vpc_id                  = aws_vpc.terraformvpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project}-${var.environment}-public${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count                   = local.subnets
  vpc_id                  = aws_vpc.terraformvpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, "${local.subnets + count.index}")
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.project}-${var.environment}-private${count.index + 1}"
  }

}

resource "aws_eip" "nat" {
  vpc = true
  tags = {
    Name = "${var.project}-${var.environment}-natgw"
  }
}

resource "aws_nat_gateway" "nat" {

  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  tags = {
    Name = "${var.project}-${var.environment}"
  }
  depends_on = [aws_internet_gateway.igw]
}


resource "aws_route_table" "public" {

  vpc_id = aws_vpc.terraformvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${var.project}-${var.environment}-public"
  }

}


resource "aws_route_table" "private" {

  vpc_id = aws_vpc.terraformvpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "${var.project}-${var.environment}-private"
  }

}

resource "aws_route_table_association" "public" {
  count          = local.subnets
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}


resource "aws_route_table_association" "private" {
  count          = local.subnets
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "bastion-sg" {

  name_prefix = "${var.project}-${var.environment}-bastion-"
  description = "Allows ssh traffic only"
  vpc_id      = aws_vpc.terraformvpc.id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
   egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    "Name" = "${var.project}-${var.environment}-bastion"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "frontend-sg" {

  name_prefix = "${var.project}-${var.environment}-frontend-"
  description = "Allow http,https,ssh traffic only"
  vpc_id      = aws_vpc.terraformvpc.id

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion-sg.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    "Name" = "${var.project}-${var.environment}-frontend"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "backend-sg" {

  name_prefix = "${var.project}-${var.environment}-backend-"
  description = "Allow mysql,ssh traffic only"
  vpc_id      = aws_vpc.terraformvpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend-sg.id]
  }


  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion-sg.id]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    "Name" = "${var.project}-${var.environment}-backend"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_key_pair" "ssh_key" {

  key_name   = "${var.project}-${var.environment}"
  public_key = file("mykey.pub")
  tags = {
    "Name" = "${var.project}-${var.environment}"
  }
}

resource "aws_instance" "bastion" {

  ami                         = var.instance_ami
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.ssh_key.key_name
  subnet_id                   = aws_subnet.public.1.id
  vpc_security_group_ids      = [aws_security_group.bastion-sg.id]
  user_data                   = file("setup-bastion.sh")
  user_data_replace_on_change = true

  tags = {
    "Name" = "${var.project}-${var.environment}-bastion"
  }
}

resource "aws_instance" "frontend" {

  ami                         = var.instance_ami
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.ssh_key.key_name
  subnet_id                   = aws_subnet.public.0.id
  user_data                   = file("setup-frontend.sh")
  user_data_replace_on_change = true
  vpc_security_group_ids      = [aws_security_group.frontend-sg.id]
  tags = {
    "Name" = "${var.project}-${var.environment}-frontend"
  }
}

resource "aws_instance" "backend" {

  ami                         = var.instance_ami
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.ssh_key.key_name
  subnet_id                   = aws_subnet.private.0.id
  vpc_security_group_ids      = [aws_security_group.backend-sg.id]
  user_data                   = file("setup-backend.sh")
  user_data_replace_on_change = true
  tags = {
    "Name" = "${var.project}-${var.environment}-backend"
  }
}
resource "aws_route53_zone" "private" {
  name = "indiantechie.local"

  vpc {
    vpc_id = aws_vpc.terraformvpc.id
  }
}
resource "aws_route53_record" "db" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "db.indiantechie.local"
  type    = "A"
  ttl     = 300
  records = [aws_instance.backend.private_ip]
}

resource "aws_route53_record" "wordpress" {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = "wordpress.${data.aws_route53_zone.public.name}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.frontend.public_ip]
}
