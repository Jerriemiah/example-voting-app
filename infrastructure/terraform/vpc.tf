# 1. Dynamically fetch available AZs in eu-north-1
data "aws_availability_zones" "available" {
  state = "available"
}

# 2. Create Subnet 1 in the first Availability Zone (e.g., eu-north-1a)
resource "aws_subnet" "subnet_1" {
  vpc_id                  = "vpc-0317844e007672437"
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
  vpc_id                  = "vpc-0317844e007672437"
  cidr_block              = "172.31.48.0/20"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name                               = "voting-app-subnet-2"
    "kubernetes.io/cluster/voting-app" = "shared"
  }
}