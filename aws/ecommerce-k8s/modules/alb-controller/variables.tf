# modules/alb-controller/variables.tf

variable "cluster_name" { type = string }

variable "alb_controller_role_arn" {
  type        = string
  description = "IAM role ARN for the ALB controller service account (IRSA)"
}
