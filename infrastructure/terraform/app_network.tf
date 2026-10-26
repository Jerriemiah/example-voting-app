locals {
  node_security_group_id = module.eks.node_security_group_id
}

resource "aws_vpc_security_group_ingress_rule" "node_to_node_http" {
  security_group_id = local.node_security_group_id
  description       = "Allow cross-node Pod traffic to vote app"

  referenced_security_group_id = local.node_security_group_id
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
}

resource "aws_vpc_security_group_ingress_rule" "vote_nodeport" {
  security_group_id = local.node_security_group_id
  description       = "Allow admin access to Vote NodePort"

  cidr_ipv4   = var.allowed_admin_cidr
  ip_protocol = "tcp"
  from_port   = 31000
  to_port     = 31000
}

resource "aws_vpc_security_group_ingress_rule" "result_nodeport" {
  security_group_id = local.node_security_group_id
  description       = "Allow admin access to Result NodePort"

  cidr_ipv4   = var.allowed_admin_cidr
  ip_protocol = "tcp"
  from_port   = 31001
  to_port     = 31001
}