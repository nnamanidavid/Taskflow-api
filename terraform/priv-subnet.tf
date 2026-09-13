resource "aws_subnet" "priv_subnet" {
  vpc_id            = aws_vpc.taskflow_vpc.id
  cidr_block        = var.priv_subnet_cidr_block
  availability_zone = var.availability_zones[0]

  tags = {
    Name = "taskflow_priv_subnet"
  }
}
