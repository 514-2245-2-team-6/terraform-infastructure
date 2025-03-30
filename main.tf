# AWS Provider used for creating AWS resources
provider "aws" {
  region = "us-east-1"
}

# Amplify App
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

# SNS Topic for email notifications
resource "aws_sns_topic" "email_notification_topic" {
  name = var.sns_email_notification_topic_name
}

resource "aws_sns_topic_subscription" "email_subscribers" {
  count = length(var.email_addresses)
  topic_arn = aws_sns_topic.email_notification_topic.arn
  protocol = "email"
  endpoint = var.email_addresses[count.index]
}

resource "aws_sns_topic_policy" "sns_allow_publish_policy" {
  arn = aws_sns_topic.email_notification_topic.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Principal = "*"
        Action   = "sns:Publish"
        Resource = aws_sns_topic.email_notification_topic.arn
      }
    ]
  })
}

# Lambda Functions
resource "aws_lambda_function" "update_current_image_function" {
  function_name = "updateCurrentImage"
  role = "arn:aws:iam::982081052963:role/service-role/waldoS3ReadWriteRole"
  handler = "lambda_function.lambda_handler"
  runtime = "python3.10"

  filename = "./lambda-functions/updateCurrentImage.zip"
	source_code_hash = filebase64sha256("./lambda-functions/updateCurrentImage.zip")

	environment {
		variables = {
			SNS_TOPIC_ARN = aws_sns_topic.email_notification_topic.arn
		}
	}
}

resource "aws_lambda_function" "get_random_cropped_face_in_current_image_function" {
	function_name = "getRandomCroppedFaceInCurrentImage"
	role = "arn:aws:iam::982081052963:role/service-role/lambdaRekognitionS3FullAccessRole"
	handler = "lambda_function.lambda_handler"
	runtime = "python3.10"

	filename = "./lambda-functions/getRandomCroppedFaceInCurrentImage.zip"
	source_code_hash = filebase64sha256("./lambda-functions/getRandomCroppedFaceInCurrentImage.zip")
}

resource "aws_lambda_function" "verify_face_selection_function" {
	function_name = "verifyFaceSelection"
	role = "arn:aws:iam::982081052963:role/service-role/waldoS3ReadWriteRole"
	handler = "lambda_function.lambda_handler"
	runtime = "python3.10"

	filename = "./lambda-functions/verifyFaceSelection.zip"
	source_code_hash = filebase64sha256("./lambda-functions/verifyFaceSelection.zip")
}

# CloudWatch Daily Reccurring Update Current Image Trigger
resource "aws_cloudwatch_event_rule" "update_current_image_rule" {
  name = "UpdateCurrentImage"
  description = "Triggers the update current image lambda function every day at 12:00 UTC"
  schedule_expression = "cron(0 12 * * ? *)"
}

resource "aws_lambda_permission" "update_current_image_target" {
  statement_id = "AllowExecutionFromCloudWatch"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_current_image_function.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.update_current_image_rule.arn
}

resource "aws_cloudwatch_event_target" "update_current_image_target" {
  rule = aws_cloudwatch_event_rule.update_current_image_rule.name
  target_id = "LambdaTarget"
  arn = aws_lambda_function.update_current_image_function.arn
}

# API Gateway
resource "aws_api_gateway_rest_api" "lambda_api" {
  name = "lambda-api"
  description = "API for accessing Lambda functions"
}

resource "aws_api_gateway_resource" "update_current_image" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  parent_id = aws_api_gateway_rest_api.lambda_api.root_resource_id
  path_part = "updateCurrentImage"
}

resource "aws_api_gateway_resource" "get_random_cropped_face" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  parent_id = aws_api_gateway_rest_api.lambda_api.root_resource_id
  path_part = "getRandomCroppedFace"
}

resource "aws_api_gateway_resource" "verify_face_selection" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  parent_id = aws_api_gateway_rest_api.lambda_api.root_resource_id
  path_part = "verifyFaceSelection"
}

resource "aws_api_gateway_method" "get_update_current_image" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.update_current_image.id
  http_method = "POST"  # or "GET" depending on your requirement
  authorization = "NONE"
}

resource "aws_api_gateway_method" "get_random_cropped_face" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.get_random_cropped_face.id
  http_method = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "get_verify_face_selection" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.verify_face_selection.id
  http_method = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "options_update_current_image" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.update_current_image.id
  http_method = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "options_get_random_cropped_face" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.get_random_cropped_face.id
  http_method = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "options_verify_face_selection" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.verify_face_selection.id
  http_method = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration_update_current_image" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.update_current_image.id
  http_method = aws_api_gateway_method.get_update_current_image.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"  # Use AWS_PROXY for proxy integration with Lambda
  uri = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/${aws_lambda_function.update_current_image_function.arn}/invocations"
}

resource "aws_api_gateway_integration" "lambda_integration_get_random_cropped_face" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.get_random_cropped_face.id
  http_method = aws_api_gateway_method.get_random_cropped_face.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/${aws_lambda_function.get_random_cropped_face_in_current_image_function.arn}/invocations"
}

resource "aws_api_gateway_integration" "lambda_integration_verify_face_selection" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.verify_face_selection.id
  http_method = aws_api_gateway_method.get_verify_face_selection.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/${aws_lambda_function.verify_face_selection_function.arn}/invocations"
}

resource "aws_api_gateway_method_response" "update_current_image_response" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.update_current_image.id
  http_method = "POST"
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Headers" = true
  }
}

resource "aws_api_gateway_integration_response" "update_current_image_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.update_current_image.id
  http_method = aws_api_gateway_method.get_update_current_image.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST, OPTIONS'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type, X-Amz-Date, Authorization, X-Api-Key'"
  }
}

resource "aws_api_gateway_method_response" "get_random_cropped_face_response" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.get_random_cropped_face.id
  http_method = "POST"
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Headers" = true
  }
}

resource "aws_api_gateway_integration_response" "get_random_cropped_face_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.get_random_cropped_face.id
  http_method = aws_api_gateway_method.get_random_cropped_face.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST, OPTIONS'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type, X-Amz-Date, Authorization, X-Api-Key'"
  }
}

resource "aws_api_gateway_method_response" "verify_face_selection_response" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.verify_face_selection.id
  http_method = "POST"
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Headers" = true
  }
}

resource "aws_api_gateway_integration_response" "verify_face_selection_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.verify_face_selection.id
  http_method = aws_api_gateway_method.get_verify_face_selection.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST, OPTIONS'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type, X-Amz-Date, Authorization, X-Api-Key'"
  }
}

resource "aws_lambda_permission" "allow_api_gateway_to_invoke_update_current_image" {
  statement_id = "AllowAPIGatewayInvokeUpdateCurrentImage"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_current_image_function.function_name
  principal = "apigateway.amazonaws.com"
}

resource "aws_lambda_permission" "allow_api_gateway_to_invoke_get_random_cropped_face" {
  statement_id = "AllowAPIGatewayInvokeGetRandomCroppedFace"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_random_cropped_face_in_current_image_function.function_name
  principal = "apigateway.amazonaws.com"
}

resource "aws_lambda_permission" "allow_api_gateway_to_invoke_verify_face_selection" {
  statement_id = "AllowAPIGatewayInvokeVerifyFaceSelection"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.verify_face_selection_function.function_name
  principal = "apigateway.amazonaws.com"
}

resource "aws_api_gateway_deployment" "lambda_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id

  depends_on = [
    aws_api_gateway_method.get_update_current_image,
    aws_api_gateway_method.get_random_cropped_face,
    aws_api_gateway_method.get_verify_face_selection,
    aws_api_gateway_method.options_update_current_image,
    aws_api_gateway_method.options_get_random_cropped_face,
    aws_api_gateway_method.options_verify_face_selection,
		aws_api_gateway_method_response.update_current_image_response,
		aws_api_gateway_method_response.get_random_cropped_face_response,
		aws_api_gateway_method_response.verify_face_selection_response,
    aws_api_gateway_integration.lambda_integration_update_current_image,
    aws_api_gateway_integration.lambda_integration_get_random_cropped_face,
    aws_api_gateway_integration.lambda_integration_verify_face_selection,
		aws_api_gateway_integration_response.update_current_image_integration_response,
		aws_api_gateway_integration_response.get_random_cropped_face_integration_response,
		aws_api_gateway_integration_response.verify_face_selection_integration_response
  ]
}


# S3 Bucket
resource "aws_s3_bucket" "crowd_images" {
  bucket = "projectawscrowdimages3buckettest"
}

resource "aws_s3_bucket_ownership_controls" "crowd_images" {
  bucket = aws_s3_bucket.crowd_images.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "crowd_images" {
  bucket = aws_s3_bucket.crowd_images.id

  block_public_acls = false
  block_public_policy = false
  ignore_public_acls = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "crowd_images" {
  depends_on = [
    aws_s3_bucket_ownership_controls.crowd_images,
    aws_s3_bucket_public_access_block.crowd_images,
  ]

  bucket = aws_s3_bucket.crowd_images.id
  acl = "public-read"
}

resource "aws_s3_bucket_cors_configuration" "crowd_images" {
  bucket = aws_s3_bucket.crowd_images.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    expose_headers  = []
    max_age_seconds = 3000
  }
}

resource "aws_s3_object" "crowd_image_1" {
  bucket = aws_s3_bucket.crowd_images.bucket
  key = "crowd-images/crowd-image1.png"
  source = "./crowd-images/crowdimage1.png"  # Local file path
}

resource "aws_s3_object" "crowd_image_2" {
  bucket = aws_s3_bucket.crowd_images.bucket
  key = "crowd-images/crowd-image2.png"
  source = "./crowd-images/crowdimage2.png"
}

resource "aws_s3_object" "crowd_image_3" {
  bucket = aws_s3_bucket.crowd_images.bucket
  key = "crowd-images/crowd-image3.png"
  source = "./crowd-images/crowdimage3.png"
}

output "s3_bucket_url" {
  value = "https://${aws_s3_bucket.crowd_images.bucket}.s3.amazonaws.com/crowd-images/"
}