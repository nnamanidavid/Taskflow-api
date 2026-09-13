resource "aws_route_table" "public" {
  vpc_id = aws_vpc.taskflow_vpc.id

  tags = {
    Name = "taskflow-public-rt"
  }
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id              = aws_internet_gateway.taskflow_igw.id

  depends_on = [aws_internet_gateway.taskflow_igw]
}

resource "aws_route_table_association" "pub_assoc" {
  count          = 2
  subnet_id      = aws_subnet.pub_subnet[count.index].id
  route_table_id = aws_route_table.public.id
}


resource "aws_route_table" "private" {
  vpc_id = aws_vpc.taskflow_vpc.id

  tags = {
    Name = "taskflow-private-rt"
  }
}

resource "aws_route" "private_internet_access" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id          = aws_nat_gateway.taskflow_nat.id

  depends_on = [aws_nat_gateway.taskflow_nat]
}

resource "aws_route_table_association" "priv_assoc" {
  subnet_id      = aws_subnet.priv_subnet.id
  route_table_id = aws_route_table.private.id
}