variable "project"          { default = "todoapp" }
variable "region"           { default = "me-central-1" }
variable "vpc_cidr"         { default = "10.0.0.0/16" }
variable "public_subnets"   { default = ["10.0.1.0/24", "10.0.2.0/24"] }
variable "private_subnets"  { default = ["10.0.11.0/24", "10.0.12.0/24"] }
variable "azs"              { default = ["me-central-1a", "me-central-1b"] }
variable "ssh_ingress_cidr" {
  description = "Where you’ll SSH from"
  default     = "0.0.0.0/0"
}

