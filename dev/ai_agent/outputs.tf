
output "primary_file_system_id" {
  value = module.main.primary_file_system_id
}

output "demo_app_access_point_id" {
  value = module.main.demo_app_access_point_id
}

output "ec2_demo_mount_target_iam_role_arn" {
  value = module.ec2_demo.mount_target_iam_role_arn
}

output "ec2_demo_access_point_iam_role_arn" {
  value = module.ec2_demo.access_point_iam_role_arn
}

output "ecs_demo_task_role_arn" {
  value = module.ecs_demo.ecs_demo_task_role_arn
}

