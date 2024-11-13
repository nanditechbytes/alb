data "aws_iam_policy_document" "main_bucket_policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::127311923021:root"]
    }
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = try(["${aws_s3_bucket.main_alb_logs[0].arn}/*"], null)
  }
}

data "aws_ssm_parameter" "application_id" {
  name = "hccp-app-id"
}

data "aws_ssm_parameter" "application_name" {
  name = "hccp-app"
}

data "aws_ssm_parameter" "cost_center" {
  name = "hccp-cost-center"
}

data "aws_ssm_parameter" "env" {
  name = "hccp-environment"
}

data "aws_ssm_parameter" "owner_email" {
  name = "hccp-owner"
}