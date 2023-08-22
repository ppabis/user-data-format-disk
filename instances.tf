data "aws_ami" "amazonlinux" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["al2023-ami-2023.1.*arm64"]
  }
}

resource "aws_instance" "amazonlinux" {
  instance_type               = "t4g.micro"
  ami                         = data.aws_ami.amazonlinux.id
  key_name                    = aws_key_pair.kp.id
  associate_public_ip_address = true
  availability_zone           = "eu-central-1a"
  vpc_security_group_ids      = [aws_security_group.ssh.id]
  user_data                   = file("./user_data.sh")
}

resource "aws_key_pair" "kp" {
  key_name   = "kp"
  public_key = file("~/.ssh/id_rsa.pub")
}

data "aws_vpc" "default" { default = true }

resource "aws_security_group" "ssh" {
  name   = "sshsg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ebs_volume" "disk" {
  type              = "gp3"
  size              = 8
  availability_zone = "eu-central-1a"
}

resource "aws_volume_attachment" "disk-mount" {
  instance_id = aws_instance.amazonlinux.id
  volume_id = aws_ebs_volume.disk.id
  device_name = "/dev/sdf"
}

output "public_ip" {
  value = aws_instance.amazonlinux.public_ip
}