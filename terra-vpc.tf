resource "aws_instance" "arvind" {
  ami           = "ami-05a5bb48beb785bf1"
  instance_type = "t2.micro"
  key_name = "deploykey"
  subnet_id = aws_subnet.pub.id
  vpc_security_group_ids = [aws_security_group.sg.id]
  associate_public_ip_address = true
  user_data = <<-EOF
   #!/bin/bash
   yum install -y httpd
   systemctl enable --now httpd
   echo "i am arvind barphani and i am doing terraform project" >> /var/www/html/index.html
   EOF

  tags = {
    Name = "webserver"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "IGW"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    name = "public"
  }
}

resource "aws_route_table_association" "association" {
  subnet_id      = aws_subnet.pub.id
  route_table_id = aws_route_table.public.id
}


resource "aws_vpc" "vpc" {
  cidr_block = "100.0.0.0/16"
}

resource "aws_subnet" "pub" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "100.0.1.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "public"
  }
}

resource "aws_subnet" "pvt" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "100.0.2.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "private"
  }
}

resource "aws_security_group" "sg" {
  name        = "sg"
  description = "inbound http ssh database"
  vpc_id      = aws_vpc.vpc.id

  ingress {
  description    = "http"
  from_port      = 80
  to_port        = 80
  protocol       = "tcp"
  cidr_blocks    = ["0.0.0.0/0"]
  }


  ingress {
  description    = "ssh"
  from_port      = 22
  to_port        = 22
  protocol       = "tcp"
  cidr_blocks    = ["0.0.0.0/0"]
  }


  ingress {
  description    = "database"
  from_port      = 3306
  to_port        = 3306
  protocol       = "tcp"
  cidr_blocks    = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "barphani" {
  ami           = "ami-05a5bb48beb785bf1"
  instance_type = "t2.micro"
  key_name = "deploykey"
  subnet_id = aws_subnet.pvt.id
  vpc_security_group_ids = [aws_security_group.sg.id]
  associate_public_ip_address = false
  user_data = <<-EOF
   #!/bin/bash
   yum install -y mariadb*
   systemctl enable --now mariadb
   EOF

  tags = {
    Name = "database"
  }
}

resource "aws_eip" "elastic" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.elastic.id
  subnet_id     = aws_subnet.pub.id

  tags = {
    Name = "gw NAT"
  }
}

resource "aws_route_table" "example" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "example"
  }
}

resource "aws_route_table_association" "association2" {
  subnet_id      = aws_subnet.pvt.id
  route_table_id = aws_route_table.example.id
}


resource "aws_ebs_volume" "ebs" {
  availability_zone = "ap-south-1b"
  size              = 4

  tags = {
    Name = "HelloWorld"
  }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.ebs.id
  instance_id = aws_instance.arvind.id
}


resource "aws_key_pair" "terrakay" {
  key_name   = "deploykey"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC89Eu+5fLhPD7eCTrKk2iAm7LpLDz1yQ7HhE0nF7ZmZkQ5kw6rGQPP1p4c7UJGnwNHt0OT97+UefPvCfva8E+VhFEAl8BUDkjN3EfEHxdHmiNvv4rl5DLt7O9xmOmPvG4LKeG8rlqHxmGWR3V8GhDZMe8yAaTpX6a42WaugUg0u9Sjw4hgHVF+5Yd4m4JFnyusy2h+qAG01OVsRXcyg+VQPseAIqMYqYsl/SGTevcFMkJ9GlIj7HgqyxxvVmzTZ5lBWPIqAOx3rYv0FKQ4W+aqrv2NNcbuTEIIeY7wTPFcn146OzfB0OIHKHAIWc4zi2hlo48f0XIu7dHhXS9Tx4CgfpMpt9m+0ydBMNaLvq9JCG3gkTBU8lNXAK64oj1XaREl1aAAlB2VFHsuugPW+B8XNu8PC6VFq+Ts0VdcxD643Ogb+xpSg10atCyVCraK65VjYTtvnJy9Wh8aJd6zB6rkR3xcn4MVTUWqoPwfks/YrIfGphyi/6JVnjBWSBY0Et8= root@terra-machine"
}

output "instance_ip" {
   value = aws_instance.arvind.public_ip
}

