data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_key_pair" "default" {
  key_name   = "${var.project}-key"
  public_key = "ssh-rsa AAAAB3NzaC1REPLACE_ME" # <--- replace with your RSA/ECDSA public key
}

resource "aws_instance" "builder" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public["0"].id
  vpc_security_group_ids      = [aws_security_group.builder.id]
  key_name                    = aws_key_pair.default.key_name
  associate_public_ip_address = true
  tags = { Name = "${var.project}-builder" }

  user_data = <<-EOF
              #!/bin/bash
                apt-get update
                apt-get upgrade -y
                for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do  apt-get remove $pkg; done
                apt-get update
                apt-get install ca-certificates curl
                install -m 0755 -d /etc/apt/keyrings
                curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
                chmod a+r /etc/apt/keyrings/docker.asc
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > dev/null
                apt-get update
                apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose -y
                echo "Use: docker login; docker build; docker tag; docker push ${aws_ecr_repository.frontend.repository_url}"
              EOF
}
