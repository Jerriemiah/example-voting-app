data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default_vpc" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_subnet" "selected" {
  for_each = toset(data.aws_subnets.default_vpc.ids)
  id       = each.value
}

locals {
  subnet_ids_by_az = {
    for subnet_id, subnet in data.aws_subnet.selected :
    subnet.availability_zone => subnet_id
  }

  eks_subnet_ids = values(local.subnet_ids_by_az)
}