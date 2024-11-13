variable "alb_config" {
  type = any
}

variable "tags" {
  type = map(string)
}

variable "vpc_id" {
  type = string
}

variable "subnets" {
  type = list(string)
}