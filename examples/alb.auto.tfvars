vpc_id  = "vpc-051daff633545b9b3"
subnets = ["subnet-06987e8d789146f32", "subnet-079b72465e4b449fe", "subnet-01f4572fbc0bf4e58", "subnet-0795062e888affb77"]

alb_config = {
  import-alb = {
    name_prefix = "imp"
    ingress = [
      {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      },
      {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }
    ]
    egress = [{
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }]

    lb_target_group = [
      {
        name_prefix = "i-cli"
        port        = 3000
        protocol    = "HTTP"
        target_type = "ip"
        health_check = {
          path                = "/"
          unhealthy_threshold = 4
          healthy_threshold   = 2
          timeout             = 29
        }
      },
      {
        name_prefix = "i-ngx"
        port        = 443
        protocol    = "HTTPS"
        target_type = "ip"
        health_check = {
          path                = "/"
          protocol            = "HTTPS"
          unhealthy_threshold = 2
          healthy_threshold   = 5
          timeout             = 29
        }
      }
    ]

    lb_listener = [
      {
        target_group_key = "i-cli"
        port             = 3000
        protocol         = "HTTPS"
        certificate_arn  = ""
        default_action = {
          type = "forward"
        }
      },
      {
        target_group_key = "i-ngx"
        port             = 443
        protocol         = "HTTPS"
        certificate_arn  = ""
        default_action = {
          type = "forward"
        }
      },
      {
        port     = 80
        protocol = "HTTP"
        default_action = {
          type = "redirect"
          redirect = {
            port        = 443
            protocol    = "HTTPS"
            status_code = "HTTP_301"
          }
        }
      }
    ]
  }
}

tags = {
  businessunit = "businessunit"
  location     = "us-east-1"
}