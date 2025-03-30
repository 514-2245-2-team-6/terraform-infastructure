variable "amplify_app_name" {
	type = string
	description = "Amplify App Name"
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
  default = "awsamplifyapp.com"
  description = "AWS Amplify Domain Name"
}

variable "update_current_image_lambda_function_name" {
  type = string
  default = "awsamplifyapp.com"
  description = "The name of the lambda function for updating the current image used on the app"
}