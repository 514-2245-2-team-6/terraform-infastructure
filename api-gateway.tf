variable "api_gateway_name" {
	type = string
	description = "The name of the API Gateway"
	default = "lambda-api"
}

# Resources Built
resource "aws_api_gateway_rest_api" "lambda_api" {
  name = var.api_gateway_name
  description = "API for accessing Lambda functions"
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

# API Gateway Methods
resource "aws_api_gateway_method" "post_get_random_cropped_face" {
	depends_on = [
		aws_api_gateway_resource.get_random_cropped_face
	]

  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.get_random_cropped_face.id
  http_method = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "options_get_random_cropped_face" {
	depends_on = [
		aws_api_gateway_resource.get_random_cropped_face
	]

  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.get_random_cropped_face.id
  http_method = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "post_verify_face_selection" {
	depends_on = [
		aws_api_gateway_resource.verify_face_selection
	]

  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.verify_face_selection.id
  http_method = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "options_verify_face_selection" {
	depends_on = [
		aws_api_gateway_resource.verify_face_selection
	]

  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.verify_face_selection.id
  http_method = "OPTIONS"
  authorization = "NONE"
}

# API Gateway Integrations
resource "aws_api_gateway_integration" "post_get_random_cropped_face" {
	depends_on = [
		aws_api_gateway_method.post_get_random_cropped_face
	]

  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.get_random_cropped_face.id
  http_method = aws_api_gateway_method.post_get_random_cropped_face.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.get_random_cropped_face_in_current_image_function.arn}/invocations"
}

resource "aws_api_gateway_integration" "options_get_random_cropped_face" {
	depends_on = [
		aws_api_gateway_method.options_get_random_cropped_face
	]

  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.get_random_cropped_face.id
  http_method = "OPTIONS"
	integration_http_method = "OPTIONS"
  type = "MOCK"
	request_templates = {
		"application/json" = jsonencode(
      {
        statusCode = 200
      }
    )
	}
}

resource "aws_api_gateway_integration" "post_verify_face_selection" {
	depends_on = [
		aws_api_gateway_method.post_verify_face_selection
	]

  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.verify_face_selection.id
  http_method = aws_api_gateway_method.post_verify_face_selection.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.verify_face_selection_function.arn}/invocations"
}

resource "aws_api_gateway_integration" "options_verify_face_selection" {
	depends_on = [
		aws_api_gateway_method.options_verify_face_selection
	]

  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.verify_face_selection.id
  http_method = "OPTIONS"
	integration_http_method = "OPTIONS"
  type = "MOCK"
	request_templates = {
		    "application/json" = <<EOF
{
	"statusCode": 200,
  "left": "$input.path('$.left')",
  "top": "$input.path('$.top')",
  "bounding_box": {
    "Width": "$input.path('$.bounding_box.width')",
    "Height": "$input.path('$.bounding_box.height')",
    "Left": "$input.path('$.bounding_box.left')",
    "Top": "$input.path('$.bounding_box.top')"
  }
}
EOF
	}
}

# API Gateway Method Responses
resource "aws_api_gateway_method_response" "post_get_random_cropped_face" {
	depends_on = [
		aws_api_gateway_method.post_get_random_cropped_face
	]

  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.get_random_cropped_face.id
  http_method = aws_api_gateway_method.post_get_random_cropped_face.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Headers" = true
  }
}

resource "aws_api_gateway_method_response" "options_get_random_cropped_face" {
	depends_on = [
		aws_api_gateway_method.options_get_random_cropped_face
	]

  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.get_random_cropped_face.id
  http_method = "OPTIONS"
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Headers" = true
  }
}

resource "aws_api_gateway_method_response" "post_verify_face_selection" {
	depends_on = [
		aws_api_gateway_method.post_verify_face_selection
	]

  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.verify_face_selection.id
  http_method = aws_api_gateway_method.post_verify_face_selection.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Headers" = true
  }
}

resource "aws_api_gateway_method_response" "options_verify_face_selection" {
	depends_on = [
		aws_api_gateway_method.options_verify_face_selection
	]

  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.verify_face_selection.id
  http_method = "OPTIONS"
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Headers" = true
  }
}

# API Gateway Integration Responses
resource "aws_api_gateway_integration_response" "post_get_random_cropped_face" {
	depends_on = [
		aws_api_gateway_integration.post_get_random_cropped_face,
		aws_api_gateway_method_response.post_get_random_cropped_face
	]

  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.get_random_cropped_face.id
  http_method = aws_api_gateway_method.post_get_random_cropped_face.http_method
  status_code = aws_api_gateway_method_response.post_get_random_cropped_face.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
  }
}

resource "aws_api_gateway_integration_response" "options_get_random_cropped_face" {
	depends_on = [
		aws_api_gateway_integration.options_get_random_cropped_face,
		aws_api_gateway_method_response.options_get_random_cropped_face
	]

  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.get_random_cropped_face.id
  http_method = "OPTIONS"
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
  }
}

resource "aws_api_gateway_integration_response" "post_verify_face_selection" {
	depends_on = [
		aws_api_gateway_integration.post_verify_face_selection,
		aws_api_gateway_method_response.post_verify_face_selection
	]

  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.verify_face_selection.id
  http_method = aws_api_gateway_method.post_verify_face_selection.http_method
  status_code = aws_api_gateway_method_response.post_verify_face_selection.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
  }
}

resource "aws_api_gateway_integration_response" "options_verify_face_selection" {
	depends_on = [
		aws_api_gateway_integration.options_verify_face_selection,
		aws_api_gateway_method_response.options_verify_face_selection
	]

  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.verify_face_selection.id
  http_method = "OPTIONS"
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
  }
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
    aws_api_gateway_method.post_get_random_cropped_face,
    aws_api_gateway_method.options_get_random_cropped_face,
    aws_api_gateway_method.post_verify_face_selection,
    aws_api_gateway_method.options_verify_face_selection,

    aws_api_gateway_integration.post_get_random_cropped_face,
    aws_api_gateway_integration.options_get_random_cropped_face,
    aws_api_gateway_integration.post_verify_face_selection,
    aws_api_gateway_integration.options_verify_face_selection,

		aws_api_gateway_method_response.post_get_random_cropped_face,
		aws_api_gateway_method_response.options_get_random_cropped_face,
		aws_api_gateway_method_response.post_verify_face_selection,
		aws_api_gateway_method_response.options_get_random_cropped_face,

		aws_api_gateway_integration_response.post_get_random_cropped_face,
		aws_api_gateway_integration_response.options_get_random_cropped_face,
		aws_api_gateway_integration_response.post_verify_face_selection,
		aws_api_gateway_integration_response.options_get_random_cropped_face,

		aws_lambda_permission.allow_api_gateway_to_invoke_get_random_cropped_face,
		aws_lambda_permission.allow_api_gateway_to_invoke_verify_face_selection,
  ]
}

resource "aws_api_gateway_stage" "lambda_api_stage" {
  stage_name = "prod"
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  deployment_id = aws_api_gateway_deployment.lambda_api_deployment.id
}


# Outputs
output "api_base_url" {
  value = "https://${aws_api_gateway_rest_api.lambda_api.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.lambda_api_stage.stage_name}/"
  description = "The base URL of the API Gateway"
}