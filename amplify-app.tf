# Variables
variable "amplify_app_name" {
	type = string
	description = "Amplify App Name"
	default = "Waldo App"
}

variable "amplify_repository_url" {
	type = string
	description = "Amplify Repository URL"
	default = "https://github.com/514-2245-2-team-6/514-2245-2-team-6"
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

variable "github_access_token" {
	type = string
	description = "GitHub Personal Access Token"
}


# Resources
resource "aws_amplify_app" "amplify_app" {
	depends_on = [
		aws_api_gateway_rest_api.lambda_api,
		aws_api_gateway_stage.lambda_api_stage
	]

  name = var.amplify_app_name
  repository = var.amplify_repository_url
  platform   = "WEB"

  oauth_token = var.github_access_token

	enable_auto_branch_creation = true
	enable_branch_auto_build = true

  auto_branch_creation_patterns = [
    "*",
    "*/**",
  ]

  auto_branch_creation_config {
    enable_auto_build = true
  }

  build_spec = <<-EOT
    version: 1
    frontend:
      phases:
        preBuild:
          commands:
            - nvm install 20
            - nvm alias default 20
            - nvm use 20
            - yarn install
        build:
          commands:
            - yarn build
      artifacts:
        baseDirectory: dist
        files:
          - '**/*'
    cache:
      paths:
        - node_modules/**/*
  EOT

  # The default rewrites and redirects added by the Amplify Console.
  custom_rule {
    source = "/<*>"
    status = "404"
    target = "/index.html"
  }

  environment_variables = {
    NODE_OPTIONS = "--max-old-space-size=4096"
    VITE_API_GATEWAY_BASE_URL = "https://${aws_api_gateway_rest_api.lambda_api.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.lambda_api_stage.stage_name}"
  }
}

resource "aws_amplify_branch" "amplify_branch" {
	depends_on = [
		aws_amplify_app.amplify_app
	]

  app_id = aws_amplify_app.amplify_app.id
  branch_name = var.amplify_repo_branch_name
  enable_auto_build = true
}

resource "aws_amplify_domain_association" "domain_association" {
  app_id                = aws_amplify_app.amplify_app.id
  domain_name           = var.app_domain_name
  wait_for_verification = false

  sub_domain {
    branch_name = aws_amplify_branch.amplify_branch.branch_name
    prefix      = var.amplify_repo_branch_name
  }

}

# Trigger Amplify Deployment once Amplify Branch is Created
resource "null_resource" "trigger_amplify_deployment" {
  depends_on = [
		aws_amplify_app.amplify_app,
		aws_amplify_branch.amplify_branch,
		aws_amplify_domain_association.domain_association
	]

  # Force this command to be triggered every time this terraform file is ran
  triggers = {
    always_run = "${timestamp()}"
  }

  # The command to be ran
  provisioner "local-exec" {
    command = "aws amplify start-job --app-id ${aws_amplify_app.amplify_app.id} --branch-name ${aws_amplify_branch.amplify_branch.branch_name} --job-type RELEASE"
  }
}


output "amplify_app_url" {
  value = "https://${var.amplify_repo_branch_name}.${aws_amplify_app.amplify_app.default_domain}"
}