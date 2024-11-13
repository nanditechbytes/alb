output "alb_outputs" {
  value = aws_lb.main_alb
}

output "sg_outputs" {
  value = aws_security_group.main_alb_security_group
}

output "listener_outputs" {
  value = aws_lb_listener.main_lb_listener
}

output "target_groups_outputs" {
  value = aws_lb_target_group.main_lb_target_group
}
