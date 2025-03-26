provider "aws" {
  region = "us-east-1"
}

resource "aws_amplify_app" "amplify_app" {
  name = var.amplify_app_name
  repository = var.amplify_repository_url
  platform   = "WEB"

  oauth_token = var.github_access_token

  enable_auto_branch_creation = true

  auto_branch_creation_patterns = [
    "main"
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
  }
}

resource "aws_amplify_branch" "amplify_branch" {
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