#VPC cidr block
variable "vpc" {
    default = "10.0.0.0/16"
    description = "My Custom VPC"
}

#Public subnet1 cidr block
variable "pubsub1" {
    default = "10.0.1.0/24"
    description = "My Public Subnet1 cidr block"
}

#Private subnet1 cidr block
variable "privsub1" {
    default = "10.0.2.0/24"
    description = "My Private Subnet1 cidr block"
}

#Public subnet2 cidr block
variable "pubsub2" {
    default = "10.0.3.0/24"
    description = "My Public Subnet2 cidr block"
}

#Private subnet2 cidr block
variable "privsub2" {
    default = "10.0.4.0/24"
    description = "My Private Subnet2 cidr block"
}

#AMI reference used to install ec2 instances (for web server)
variable "ec2-id" {
  default = "ami-0862aabda3fb488b5"
}

#AMI type
variable "ec2-type" {
  default = "t2.micro"
}

#variable "public_key_path" {
#  description = "Path to the SSH Publc Key for ec2 instances"
#  default = ""
#}

#Port for autoscaling group
variable "listener_port" {
  default = "80"
}

#Listener protocol
variable "listener_protocol" {
  default = "HTTP"
}

#Path to the web server index file
variable "health_check_path" {
  default = "/index.php"
}

#RDS instance name
variable "identifier" {
  default = "webserverdb"
}

#Username for master DB user (must be personal)
variable "username" {
  default = "masterUser"
}

#Password for the master DB user(In a prod. env. it's more secure to store your DB PWD in AWS Systems Manager Parameter Store)
variable "password" {
  default = "supersecret"
}
