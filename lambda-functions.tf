resource "aws_lambda_function" "update_current_image_function" {
  function_name = "updateCurrentImage"
  role = "arn:aws:iam::982081052963:role/service-role/waldoS3ReadWriteRole"
  handler = "lambda_function.lambda_handler"
  runtime = "python3.10"

  filename = "./assets/lambda-functions/updateCurrentImage.zip"
	source_code_hash = filebase64sha256("./assets/lambda-functions/updateCurrentImage.zip")

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

	filename = "./assets/lambda-functions/getRandomCroppedFaceInCurrentImage.zip"
	source_code_hash = filebase64sha256("./assets/lambda-functions/getRandomCroppedFaceInCurrentImage.zip")
}

resource "aws_lambda_function" "verify_face_selection_function" {
	function_name = "verifyFaceSelection"
	role = "arn:aws:iam::982081052963:role/service-role/waldoS3ReadWriteRole"
	handler = "lambda_function.lambda_handler"
	runtime = "python3.10"

	filename = "./assets/lambda-functions/verifyFaceSelection.zip"
	source_code_hash = filebase64sha256("./assets/lambda-functions/verifyFaceSelection.zip")
}