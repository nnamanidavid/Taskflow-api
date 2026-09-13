resource "aws_internet_gateway" "taskflow_igw" {
  vpc_id = aws_vpc.taskflow_vpc.id

  tags = {
    Name = "taskflow_igw"
  }
}


##### 

resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "taskflow_eip_nat"
  }

  depends_on = [aws_internet_gateway.taskflow_igw]
}

resource "aws_nat_gateway" "taskflow_nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.pub_subnet[0].id
  
  tags = {
    Name = "taskflow_nat"
  }

  depends_on = [aws_internet_gateway.taskflow_igw]
}

