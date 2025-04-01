# File 6: modules/vpc/nat_gateway.tf
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway

resource "aws_eip" "eip" {
  domain = "vpc"
  tags = {
    Name = "nat-eip"
  }
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public.id
  tags = {
    Name = "nat-gw"
  }
  depends_on = [aws_internet_gateway.igw]
}
