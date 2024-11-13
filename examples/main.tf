terraform {
  required_version = "~> 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

module "alb" {
  source                   = "../"
  for_each                 = var.alb_config
  name_prefix              = each.value.name_prefix
  subnets                  = var.subnets
  ingress                  = [for data in each.value.ingress : can(data.cidr_blocks) ? merge(data, { security_group = null }) : merge(data, { security_group = "sg-0d304d804b3003c27" })] #merge(data, { security_group = module.ce-ecs-service["import-nginx"].ecs_security_group.id })]
  egress                   = lookup(each.value, "egress", null)
  lb_listener              = lookup(each.value, "lb_listener", null)
  lb_target_group          = lookup(each.value, "lb_target_group", null)
  target_group_attachement = lookup(each.value, "target_group_attachement", null)
  lb_listener_path_rule    = lookup(each.value, "lb_listener_path_rule", null)
  vpc_id                   = var.vpc_id
  access_logs_required     = lookup(each.value, "access_logs_required", false)
  tags                     = var.tags # Mandatory tags
}