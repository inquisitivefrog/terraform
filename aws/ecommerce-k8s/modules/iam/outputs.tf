# modules/iam/outputs.tf
output "alb_controller_role_arn" {
  description = "ARN of the ALB controller IAM role"
  value       = aws_iam_role.alb_controller.arn
}

output "node_group_elb_policy_arn" {
  description = "ARN of the ELB policy for the node group"
  value       = aws_iam_policy.node_group_elb.arn
}
