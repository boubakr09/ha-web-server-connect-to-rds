#My default region
provider "aws" {
  region = "eu-west-1"  
}

#Custom VPC creation
resource "aws_vpc" "VPC" {
   cidr_block = "${var.vpc}"
   tags = {
       Name = "My Custom VPC"
   }
}

#Internet Gateway creation
resource "aws_internet_gateway" "IGW" {
   vpc_id = "${aws_vpc.VPC.id}"

   tags = {
     Name = "My Custom VPC IG"
   }
}

#Create remote bucket to store the state of our infra
resource "aws_s3_bucket" "tf-state-storage" {
   bucket = "my-ha-web-server-rds-tf-state-storage"
   versioning {
     enabled = true
   }
   lifecycle {
     prevent_destroy = true
   }
}
terraform {
  backend "s3" {
    encrypt = true
    bucket = "my-ha-web-server-rds-tf-state-storage"
    key = "terraform.tfstate"
    region = "eu-west-1"
  }
}

data "terraform_remote_state" "my-state-data" {
  backend = "s3"
  config = {
    bucket = "my-ha-web-server-rds-tf-state-storage"
    key    = "terraform.tfstate"
    region = "eu-west-1"
  }
}

#Public subnet1 creation
resource "aws_subnet" "PublicSubnet1" {
  vpc_id     = "${aws_vpc.VPC.id}"
  cidr_block = "${var.pubsub1}"
  availability_zone = "eu-west-1a"
  tags = {
    Name = "My Public Subnet1"
  }
}

#Private subnet1 creation
resource "aws_subnet" "PrivateSubnet1" {
  vpc_id     = "${aws_vpc.VPC.id}"
  cidr_block = "${var.privsub1}"
  availability_zone = "eu-west-1a"
  tags = {
    Name = "My Private Subnet1"
  }
}

#Public subnet2 creation
resource "aws_subnet" "PublicSubnet2" {
  vpc_id     = "${aws_vpc.VPC.id}"
  cidr_block = "${var.pubsub2}"
  availability_zone = "eu-west-1b"
  tags = {
    Name = "My Public Subnet2"
  }
}

#Private subnet2 creation
resource "aws_subnet" "PrivateSubnet2" {
  vpc_id     = "${aws_vpc.VPC.id}"
  cidr_block = "${var.privsub2}"
  availability_zone = "eu-west-1b"
  tags = {
    Name = "My Private Subnet2"
  }
}

#Public subnet security group
resource "aws_security_group" "MyPubSubSG" {
  depends_on = ["aws_vpc.VPC"]
  name = "My Public Subnet Security Group"
  description = "Allow HTTP and SSH traffic"
  vpc_id = "${aws_vpc.VPC.id}"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["your_corporate_subnet"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "MyPublicSubnetSG"
  }
}

#RDS security group
resource "aws_security_group" "MyRDSSG" {
  depends_on = ["aws_vpc.VPC"]
  name = "My RDS Security Group"
  description = "Allow MySQL traffic"
  vpc_id = "${aws_vpc.VPC.id}"

  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = ["10.0.1.0/24","10.0.3.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "RDS_SG"
  }
}

#Create RDS DB subnet group
resource "aws_db_subnet_group" "MyRDSDBSubnetGroup" {
  name = "my rds db subnet group"
  subnet_ids = ["${aws_subnet.PrivateSubnet1.id}", "${aws_subnet.PrivateSubnet2.id}"]

  tags = {
    Name = "MyRDSDBSubnetGroup"
  }
  
}

#Create Public Route Table
resource "aws_route_table" "MyPubRT" {
  vpc_id = "${aws_vpc.VPC.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.IGW.id}"
  }

  tags = {
    Name = "Public Subnet RT"
  }
  
}

#Public RT association with PubSub1
resource "aws_route_table_association" "PublicRTassociationWithPubSub1" {
  subnet_id = "${aws_subnet.PublicSubnet1.id}"
  route_table_id = "${aws_route_table.MyPubRT.id}"
}
#Public RT association with PubSub2
resource "aws_route_table_association" "PublicRTassociationWithPubSub2" {
  subnet_id = "${aws_subnet.PublicSubnet2.id}"
  route_table_id = "${aws_route_table.MyPubRT.id}"
}

#Create EIP
resource "aws_eip" "MyEIP" {
  vpc = true  
}

#Create NAT Gateway
resource "aws_nat_gateway" "MyNGW" {
  allocation_id = "${aws_eip.MyEIP.id}"
  subnet_id = "${aws_subnet.PublicSubnet1.id}"
  tags = {
    Name = "MyNGW"
  }
}

#Create Private Route Table
resource "aws_route_table" "MyPrivateRT" {
  vpc_id = "${aws_vpc.VPC.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.MyNGW.id}" 
  }

  tags = {
    Name = "Private Subnet RT"
  }
  
}

#Create Private RT association with Pub Sub1
resource "aws_route_table_association" "PrivateRTassociationWithPrivSub1" {
  subnet_id = "${aws_subnet.PrivateSubnet1.id}"
  route_table_id = "${aws_route_table.MyPrivateRT.id}"
}

#Create Private RT association with Pub Sub2
resource "aws_route_table_association" "PrivateRTassociationWithPrivSub2" {
  subnet_id = "${aws_subnet.PrivateSubnet2.id}"
  route_table_id = "${aws_route_table.MyPrivateRT.id}"
}

#Create launch configuration
resource "aws_launch_configuration" "MyEC2instanceInstall3" {
  image_id = "${var.ec2-id}"
  instance_type = "${var.ec2-type}"
  name = "MyASLC3"
  
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y httpd24 php56 php56-mysqlnd
              sudo service httpd start
              sudo chkconfig httpd on
              cd /var/www/html
              echo "<html><h1>Welcome to my Web Server!</h1></html>" > index.html
              EOF
  
  associate_public_ip_address = "true"
  security_groups = ["${aws_security_group.MyPubSubSG.id}"]
  key_name = "myEC2key"

}

#Create auto scaling group
resource "aws_autoscaling_group" "MyASG" {
  name = "MyASG"
  launch_configuration = "${aws_launch_configuration.MyEC2instanceInstall3.id}"
  min_size = "1"
  max_size = "2"
  desired_capacity = "1"
  vpc_zone_identifier = ["${aws_subnet.PublicSubnet1.id}", "${aws_subnet.PublicSubnet2.id}"]
  
}
#Create scaling policy for MyASG
resource "aws_autoscaling_policy" "MyASGPolicy" {
  name = "MyASGPolicy"
  policy_type = "TargetTrackingScaling"
  autoscaling_group_name = "${aws_autoscaling_group.MyASG.id}"
  estimated_instance_warmup = "60"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = "5"
  }
}

#ALB Security Group 
resource "aws_security_group" "MyALBSG" {
  name = "My Application Load Balancer Security Group"
  description = "Allow HTTP traffic"
  vpc_id = "${aws_vpc.VPC.id}"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "MyALBSG"
  }
}

#Create Application Load Balancer
resource "aws_lb" "MyALB" {
  name = "MyALB"
  internal = false
  load_balancer_type = "application"
  subnets = ["${aws_subnet.PublicSubnet1.id}", "${aws_subnet.PublicSubnet2.id}"]
  security_groups = ["${aws_security_group.MyALBSG.id}"]

  tags = {
    name = "MyALB"
  }
}

#Create ALB target group
resource "aws_lb_target_group" "MyALB_target_group" {
  name = "myalbtargetgroup"
  port = "${var.listener_port}"
  protocol = "${var.listener_protocol}"
  vpc_id = "${aws_vpc.VPC.id}"

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 3
    timeout = 5
    interval = 6
    path = "${var.health_check_path}"
    port = "${var.listener_port}"
  }
}

#Create ALB Listener
resource "aws_alb_listener" "MyALB_listener" {
  load_balancer_arn = "${aws_lb.MyALB.arn}"
  port = "${var.listener_port}"
  protocol = "${var.listener_protocol}"

  default_action {
    target_group_arn = "${aws_lb_target_group.MyALB_target_group.arn}"
    type = "forward"
  }
}

#Autoscaling Attachment
resource "aws_autoscaling_attachment" "MyALB_ASG_external" {
  alb_target_group_arn = "${aws_lb_target_group.MyALB_target_group.arn}"
  autoscaling_group_name = "${aws_autoscaling_group.MyASG.id}"
}

#Create DB instance
resource "aws_db_instance" "MyRDSInstance" {
  license_model = "general-public-license"
  engine = "MySQL"
  engine_version = "5.7.22"
  allocated_storage = 20
  storage_type = "gp2"
  instance_class = "db.t2.micro"
  identifier = "${var.identifier}"
  username = "${var.username}"
  #in a prod. env. it's more secure to store your DB PWD in AWS Systems Manager Parameter Store, Secret Manager or encrypt the password
  password = "${var.password}"
  db_subnet_group_name = "${aws_db_subnet_group.MyRDSDBSubnetGroup.id}"
  multi_az = true
  vpc_security_group_ids = ["${aws_security_group.MyRDSSG.id}"]
  name = "myWebServerDBinstance"
  backup_retention_period = "1"
}








