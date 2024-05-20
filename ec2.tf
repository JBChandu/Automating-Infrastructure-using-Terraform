#create Ec2 instance
resource "aws_instance" "my_ec2" {
  ami             = var.ami_id
  instance_type   = var.instance_type
  key_name        = aws_key_pair.deployer.key_name
  security_groups = ["${aws_security_group.secGrp1.name}"]
  user_data       = <<-EOF
                    #!/bin/bash
                    sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
                    sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
                    sudo amazon-linux-extras install epel -y
                    sudo amazon-linux-extras install java-openjdk11 -y
                    sudo yum install jenkins -y
                    sudo systemctl start jenkins
                    sudo systemctl enable jenkins
                    sudo amazon-linux-extras install ansible2 -y
                    EOF

  tags = {
    Name = "MyEC2-instance"
  }
}

# create a security group and assign it to EC2, by default it won't
resource "aws_security_group" "secGrp1" {
  name        = "securityGroup-1"
  description = "Allow ssh connection"

  ingress {
    description      = "ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SecGrp-1"
  }
}

# Generate an Ed25519 key pair
resource "tls_private_key" "example" {
  algorithm = "ED25519"
}

# Save the private key locally
resource "local_file" "private_key" {
  content         = tls_private_key.example.private_key_openssh
  filename        = "${path.module}/deployer-key.pem"
  file_permission = "0600"
}

# Create an AWS key pair using the generated public key
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = tls_private_key.example.public_key_openssh
}

# Output the EC2 instance ID and public IP
output "instance_id" {
  value = aws_instance.my_ec2.id
}

output "instance_public_ip" {
  value = aws_instance.my_ec2.public_ip
}