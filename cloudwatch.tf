variable "update_current_image_cron_expression" {
	type = string
	description = "Cron expression for when to trigger the update current image lambda function"
	default = "cron(30 22 * * ? *)"
}

resource "aws_cloudwatch_event_rule" "update_current_image_rule" {
  name = "UpdateCurrentImage"
  description = "Triggers the update current image lambda function every day at 12:00 UTC"
  schedule_expression = var.update_current_image_cron_expression
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