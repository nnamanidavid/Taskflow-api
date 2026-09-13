resource "aws_subnet" "pub_subnet" {
  count             = 2
  vpc_id            = aws_vpc.taskflow_vpc.id
  cidr_block        = var.pub_subnet_cidr_blocks[count.index]
  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name = "taskflow-pub-subnet-${count.index}"
  }
}