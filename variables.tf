variable "amplify_app_name" {
	type = string
	description = "Amplify App Name"
	default = "Amplify App"
}

variable "amplify_repository_url" {
	type = string
	description = "Amplify Repository URL"
}

variable "github_access_token" {
	type = string
	description = "GitHub Personal Access Token"
}

variable "amplify_repo_branch_name" {
  type = string
  description = "AWS Amplify App Repo Branch Name"
  default = "main"
}

variable "app_domain_name" {
  type = string
  description = "AWS Amplify Domain Name"
  default = "awsamplifyapp.com"
}

variable "update_current_image_lambda_function_name" {
  type = string
  description = "The name of the lambda function for updating the current image used on the app"
  default = "updateCurrentImage"
}

variable "email_addresses" {
	type = list(string)
	description = "List of email addresses to subscribe to the SNS topic"
	default = []
}

variable sns_email_notification_topic_name {
	type = string
	description = "The name of the SNS topic for email notifications"
	default = "WheresWaldoUpdate"
}

variable github_organization {
	type = string
	description = "The name of the GitHub organization"
	default = "514-2245-2-team-6"
}