variable "project" {
  default     = "terraform-vpc"
  description = "project name"
}
variable "environment" {
  default     = "production"
  description = "project environment"
}
variable "region" {
  default     = "ap-south-1"
  description = "project region"
}
variable "access_key" {
  default     = "XXXXXXXXXXXXXXXXXXXXX"
  description = "project accesskey"
}
variable "secret_key" {
  default     = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
  description = "project secret key"
}
locals {
  common_tags = {
    "project"     = var.project
    "environemnt" = var.environment
  }
}
variable "vpc_cidr" {
  default = "172.16.0.0/16"
}
locals {
  subnets = length(data.aws_availability_zones.available.names)
}
variable "instance_ami" {
  default = "ami-0cca134ec43cf708f"
}

variable "instance_type" {
  default = "t2.micro"
}
