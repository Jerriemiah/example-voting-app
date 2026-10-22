# 1. Dynamically fetch available AZs in eu-north-1
data "aws_availability_zones" "available" {
  state = "available"
}

# 2. Create Subnet 1 in the first Availability Zone (e.g., eu-north-1a)
resource "aws_subnet" "subnet_1" {
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = "172.31.32.0/20"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name                               = "voting-app-subnet-1"
    "kubernetes.io/cluster/voting-app" = "shared"
  }
}

# 3. Create Subnet 2 in the second Availability Zone (e.g., eu-north-1b)
resource "aws_subnet" "subnet_2" {
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = "172.31.48.0/20"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name                               = "voting-app-subnet-2"
    "kubernetes.io/cluster/voting-app" = "shared"
  }
}

# Subnet Association

# 1. Look up the main/default route table of your default VPC
data "aws_route_table" "default" {
  vpc_id = data.aws_vpc.default.id
  filter {
    name   = "association.main"
    values = ["true"]
  }
}

# 2. Explicitly attach Subnet 1 to the default route table
resource "aws_route_table_association" "subnet_1_assoc" {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = data.aws_route_table.default.id
}

# 3. Explicitly attach Subnet 2 to the default route table
resource "aws_route_table_association" "subnet_2_assoc" {
  subnet_id      = aws_subnet.subnet_2.id
  route_table_id = data.aws_route_table.default.id
}