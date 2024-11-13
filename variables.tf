variable "name_prefix" {
  type        = string
  description = "name of the resources"
}

variable "internal" {
  type        = bool
  default     = true
  description = "To choose if alb should be internet or intranet facing"
}

variable "subnets" {
  type        = list(string)
  description = "Required subnets"
}

variable "access_logs_required" {
  type        = bool
  default     = false
  description = "Collect access logs"
}

variable "idle_timeout" {
  type        = number
  default     = 60
  description = "Set alb time-out"
}

variable "drop_invalid_header_fields" {
  type        = bool
  default     = null
  description = "header setting on alb"
}

variable "preserve_host_header" {
  type        = bool
  default     = false
  description = "Allow to hold host header"
}

variable "enable_deletion_protection" {
  type    = bool
  default = false
}

variable "enable_http2" {
  type    = bool
  default = true
}

variable "enable_waf_fail_open" {
  type    = bool
  default = false
}

variable "customer_owned_ipv4_pool" {
  type    = string
  default = null
}

variable "ip_address_type" {
  type    = string
  default = null
}

variable "desync_mitigation_mode" {
  type    = string
  default = "defensive"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to add to the alb. By default, the module will add application-id, application, cost-center, env, service, version, and owner-email"
  default     = {}
}

variable "vpc_id" {
  type        = string
  description = "vpc id"
}

variable "ingress" {
  type = list(object({
    description    = optional(string)
    from_port      = number
    to_port        = number
    protocol       = string
    cidr_blocks    = optional(list(string))
    security_group = optional(string)
  }))
  description = "Ingress rules for ALB security group"
}

variable "egress" {
  type = list(object({
    description    = optional(string)
    from_port      = number
    to_port        = number
    protocol       = string
    cidr_blocks    = optional(list(string))
    security_group = optional(string)
  }))
  description = "Egress rules for ALB security group"
}

variable "lb_target_group" {
  type = list(object({
    name_prefix        = string
    port               = number
    protocol           = string
    target_type        = optional(string)
    preserve_client_ip = optional(bool)
    health_check = optional(object({
      interval            = optional(number)
      path                = optional(string)
      protocol            = optional(string)
      healthy_threshold   = optional(number)
      unhealthy_threshold = optional(number)
      timeout             = optional(number)
      matcher             = optional(number)
    }))
  }))
  description = "Target group configuration which can be attached to ALB via listener"
}

variable "lb_listener" {
  type = list(object({
    target_group_key = optional(string)
    port             = number
    protocol         = string
    certificate_arn  = optional(string)
    default_action = object({
      type = string
      redirect = optional(object({
        port        = number
        protocol    = string
        status_code = string
      }))
    })

  }))
  description = "Add listener configuration for ALB"
}

variable "lb_listener_path_rule" {
  type = list(object({
    priority = optional(number)
    action = object({
      type             = optional(string)
      target_group_key = optional(string)
    })
    condition = object({
      path = optional(string)
    })

  }))
  description = "Add listener rule for Path based routing"
  default     = null
}

variable "target_group_attachement" {
  type = list(object({
    target_group_key  = optional(string)
    port              = optional(number)
    target_id         = optional(string)
    availability_zone = optional(string)
  }))
  description = "Attach IP to the target group ALB"
  default     = null
}

