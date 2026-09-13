variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.123.0.0/16"
}

variable "pub_subnet_cidr_blocks" {
  type    = list(string)
  default = ["10.123.1.0/24", "10.123.3.0/24"]
}

variable "priv_subnet_cidr_block" {
  description = "The CIDR block for the private subnet"
  type        = string
  default     = "10.123.2.0/24"
}


variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

