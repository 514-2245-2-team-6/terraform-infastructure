# Variables
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


# Resources Built
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