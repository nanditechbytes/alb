locals {
  iam_role_output_properties = ["arn", "id", "name"]
  module_output = {
    for alb_key, alb_config in module.alb : alb_key => {
      for albs, data in alb_config : albs => {
        for key, value in data : key => value if contains(local.iam_role_output_properties, key)
      }
    }
  }
}

output "outputs" {
  value = local.module_output
}    