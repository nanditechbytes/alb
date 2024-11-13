locals {
  tags = merge(var.tags, {
    application-id = data.aws_ssm_parameter.application_id.value
    application    = data.aws_ssm_parameter.application_name.value
    cost-center    = data.aws_ssm_parameter.cost_center.value
    env            = data.aws_ssm_parameter.env.value
    owner-email    = data.aws_ssm_parameter.owner_email.value
  })
}

resource "aws_lb" "main_alb" {
  name_prefix                = var.name_prefix
  internal                   = var.internal
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.main_alb_security_group.id]
  drop_invalid_header_fields = var.drop_invalid_header_fields
  preserve_host_header       = var.preserve_host_header
  subnets                    = var.subnets
  idle_timeout               = var.idle_timeout
  enable_deletion_protection = var.enable_deletion_protection
  enable_http2               = var.enable_http2
  enable_waf_fail_open       = var.enable_waf_fail_open
  customer_owned_ipv4_pool   = var.customer_owned_ipv4_pool
  ip_address_type            = var.ip_address_type
  desync_mitigation_mode     = var.desync_mitigation_mode
  tags                       = merge(local.tags, { "resource-name" : "Application Load Balancer Service" })
  dynamic "access_logs" {
    for_each = var.access_logs_required ? [1] : []
    content {
      bucket  = aws_s3_bucket.main_alb_logs[0].bucket
      prefix  = "alb-logs"
      enabled = true
    }
  }
}


resource "aws_security_group" "main_alb_security_group" {
  name_prefix = "${var.name_prefix}-alb-sg-"
  vpc_id      = var.vpc_id
  tags        = merge(local.tags, { "resource-name" : "Application Load Balancer Service" })
}

resource "aws_security_group_rule" "main_alb_security_group_ingress" {
  security_group_id        = aws_security_group.main_alb_security_group.id
  for_each                 = { for index, ingress in var.ingress : index => ingress }
  type                     = "ingress"
  description              = each.value.description
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  cidr_blocks              = each.value.cidr_blocks
  source_security_group_id = each.value.security_group
}


resource "aws_security_group_rule" "main_alb_security_group_egress" {
  security_group_id        = aws_security_group.main_alb_security_group.id
  for_each                 = { for index, egress in var.egress : index => egress }
  type                     = "egress"
  description              = each.value.description
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  cidr_blocks              = each.value.cidr_blocks
  source_security_group_id = each.value.security_group
}

resource "aws_s3_bucket" "main_alb_logs" {
  bucket = "${var.name_prefix}-alb-logs"
  count  = var.access_logs_required ? 1 : 0
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main_encryption_alb_logs" {
  bucket = aws_s3_bucket.main_alb_logs[0].bucket
  count  = var.access_logs_required ? 1 : 0
  rule {
    bucket_key_enabled = false
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


resource "aws_s3_bucket_public_access_block" "main_block_public_access_alb_logs" {
  bucket                  = aws_s3_bucket.main_alb_logs[0].bucket
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
  count                   = var.access_logs_required ? 1 : 0
}

resource "aws_s3_bucket_policy" "main_policy_alb_logs" {
  bucket = aws_s3_bucket.main_alb_logs[0].bucket
  count  = var.access_logs_required ? 1 : 0
  policy = data.aws_iam_policy_document.main_bucket_policy.json
}

resource "aws_lb_listener" "main_lb_listener" {
  for_each          = { for index, lb_listener in var.lb_listener : index => lb_listener }
  load_balancer_arn = aws_lb.main_alb.arn
  port              = each.value.port
  protocol          = each.value.protocol
  certificate_arn   = each.value.certificate_arn
  default_action {
    type             = each.value.default_action.type
    target_group_arn = each.value.default_action.type == "forward" ? aws_lb_target_group.main_lb_target_group[each.value.target_group_key].arn : null
    dynamic "redirect" {
      for_each = each.value.default_action.type == "redirect" ? [1] : []
      content {
        port        = each.value.default_action.redirect.port
        protocol    = each.value.default_action.redirect.protocol
        status_code = each.value.default_action.redirect.status_code
      }
    }
    dynamic "fixed_response" {
      for_each = each.value.default_action.type == "fixed_response" ? [1] : []
      content {
        message_body = each.value.default_action.fixed_response.message_body
        content_type = each.value.default_action.fixed_response.content_type
        status_code  = each.value.default_action.fixed_response.status_code
      }
    }
  }
  tags = merge(local.tags, { "resource-name" : "Application Load Balancer Service" })
}

resource "aws_alb_listener_rule" "path_rule" {
  for_each     = var.lb_listener_path_rule != null ? { for index, lb_listener_path_rule in var.lb_listener_path_rule : index => lb_listener_path_rule } : {}
  listener_arn = aws_lb_listener.main_lb_listener[0].arn
  priority     = each.value.priority

  dynamic "action" {
    for_each = each.value.action != null ? [each.value.action] : []
    content {
      type             = action.value.type
      target_group_arn = aws_lb_target_group.main_lb_target_group[action.value.target_group_key].arn
    }
  }
  dynamic "condition" {
    for_each = each.value.condition != null ? [each.value.condition] : []
    content {
      path_pattern {
        values = [condition.value.path]
      }
    }


  }
}

resource "aws_lb_target_group_attachment" "test" {
  for_each          = var.target_group_attachement != null ? { for index, target_group_attachement in var.target_group_attachement : index => target_group_attachement } : {}
  target_group_arn  = aws_lb_target_group.main_lb_target_group[each.value.target_group_key].arn
  target_id         = each.value.target_id
  port              = each.value.port
  availability_zone = each.value.availability_zone
}

resource "aws_lb_target_group" "main_lb_target_group" {
  for_each           = { for index, lb_target_group in var.lb_target_group : lb_target_group.name_prefix => lb_target_group }
  name_prefix        = each.value.name_prefix
  port               = each.value.port
  protocol           = each.value.protocol
  vpc_id             = var.vpc_id
  target_type        = each.value.target_type
  preserve_client_ip = each.value.preserve_client_ip
  dynamic "health_check" {
    for_each = each.value.health_check != null ? [each.value.health_check] : []
    content {
      interval            = try(health_check.value.interval, 30)
      path                = try(health_check.value.path, null)
      protocol            = try(health_check.value.protocol, null)
      healthy_threshold   = try(health_check.value.healthy_threshold, 5)
      unhealthy_threshold = try(health_check.value.unhealthy_threshold, 2)
      timeout             = try(health_check.value.timeout, 5)
      matcher             = try(health_check.value.matcher, 200)
    }
  }
  lifecycle {
    create_before_destroy = true
  }
  tags = merge(local.tags, { "resource-name" : "Application Load Balancer Service" })
}
