# ---------------------------------------------------------------------------------------------------------------------
# DEFINE MINIMUM TERRAFORM VERSION
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 0.10.3"
}

# ---------------------------------------------------------------------------------------------------------------------
# ATTACH AN ELASTIC IP
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_eip" "bastion" {
  instance = "${aws_instance.instance.id}"
  vpc      = true

  #depends_on = ["aws_instance.instance"]

  # Workaround for an eventual consistency bug where Terraform doesn't wait long enough for an EIP to be created, which
  # can occasionally cause an 'Failure associating EIP: InvalidAllocationID.NotFound: The allocation ID 'eipalloc-XXX'
  # does not exist' error. For more info, see: https://github.com/hashicorp/terraform/issues/1815
  provisioner "local-exec" {
    command = "echo 'Sleeping 15 seconds to work around EIP propagation bug in Terraform' && sleep 15"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE EC2 INSTANCE TO RUN THE BASTION NODE
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_instance" "instance" {
  # used the supplied AMI or fallback to a recent Ubuntu 16.04 image.
  ami           = "${coalesce(var.ami_id, data.aws_ami.ubuntu.id)}"
  instance_type = "${var.instance_type}"

  # deploy the instance into the first availability zone
  subnet_id = "${var.subnet_id}"

  # add security groups to allow ssh & vpn access
  vpc_security_group_ids = ["${aws_security_group.bastion.id}"]

  key_name          = "${var.key_pair_name}"
  user_data         = "${var.user_data}"
  source_dest_check = false

  # add tags
  tags = "${merge(
    var.tags,
    map(
      "Name", "${var.name}"
    )
  )}"

  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A SECURITY GROUP TO CONTROL WHAT REQUESTS CAN GO IN AND OUT OF EACH EC2 INSTANCE
# We export the ID of the security group as an output variable so users can attach custom rules.
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "bastion" {
  description = "Security group for the Bastion instance"
  vpc_id      = "${var.vpc_id}"

  # add tags
  tags = "${merge(
    var.tags,
    map(
      "Name", "${var.name}"
    )
  )}"
}

resource "aws_security_group_rule" "allow_ssh_inbound" {
  count       = "${length(var.allowed_ssh_cidr_blocks) >= 1 ? 1 : 0}"
  type        = "ingress"
  from_port   = "${var.ssh_port}"
  to_port     = "${var.ssh_port}"
  protocol    = "tcp"
  cidr_blocks = ["${var.allowed_ssh_cidr_blocks}"]

  security_group_id = "${aws_security_group.bastion.id}"
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.bastion.id}"
}

# ---------------------------------------------------------------------------------------------------------------------
# LOOKUP THE LATEST UBUNTU 16.04 AMI
# ---------------------------------------------------------------------------------------------------------------------

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}
