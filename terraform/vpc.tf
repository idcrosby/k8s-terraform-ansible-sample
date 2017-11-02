############
## VPC
############


############
## Subnets
############

# Subnet (public)
resource "aws_subnet" "kubernetes" {
  vpc_id = "${var.vpc_id}"
  cidr_block = "${var.subnet_cidr}"
  availability_zone = "${var.zone}"

  tags {
    Name = "kubernetes"
    Owner = "${var.owner}"
  }
}


############
## Security
############

resource "aws_security_group" "kubernetes" {
  vpc_id = "${var.vpc_id}"
  name = "kubernetes"

  # Allow all outbound
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow ICMP from control host IP
  ingress {
    from_port = 8
    to_port = 0
    protocol = "icmp"
    cidr_blocks = ["${var.control_cidr}"]
  }

  # Allow all internal
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  # Allow all traffic from the API ELB
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    security_groups = ["${aws_security_group.kubernetes_api.id}"]
  }

  # Allow all traffic from control host IP
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["${var.control_cidr}"]
  }

  tags {
    Owner = "${var.owner}"
    Name = "kubernetes"
  }
}
