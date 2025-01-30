# File 11: modules/networking/route_tables.tf
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association

resource "aws_route_table" "public" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.igw_id
  }
  tags = {
    Name = "rtb-public"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = var.vpc_subnet_public_id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = var.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.nat_id
  }
  tags = {
    Name = "rtb-private"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = var.vpc_subnet_private_id
  route_table_id = aws_route_table.private.id
}
