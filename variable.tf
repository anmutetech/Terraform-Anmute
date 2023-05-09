variable "region" {
default = "us-east-1"
}
variable "instance_type" {
default = "t2.micro"
}
variable "instance_key" {
default = "my-first-server"
}
variable "vpc_cidr" {
default = "178.0.0.0/16"
}
variable "public_subnet_cidr" {
default = "178.0.10.0/24"
}
