data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name  = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

locals {
  instance_type = "t2.micro"
}

resource "aws_instance" "app" {
  count = 2

  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = local.instance_type

  # Use modulo to place instances into subnets.
  # e.g count.index = 2, sns = [1, 2, 3]
  #   => sn_id = 2 % 3 = 2
  subnet_id              = var.subnet_ids[count.index % length(var.subnet_ids)]
  vpc_security_group_ids = var.security_group_ids

  # Install apache server and create simple HTML landing page
  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install httpd -y

    sudo systemctl enable httpd
    sudo systemctl start httpd

    cat <<-HTML > /var/www/html/index.html
      <html>
        <body>
          <h1>Hello, World!</h1>
        </body>
      </html>
    HTML
  EOF

  tags = var.tags
}
