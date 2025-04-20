resource "aws_iam_policy" "rekognition_detect_faces" {
  name = "rekognition_detect_faces_policy"
  description = "Policy for Lambda to use Rekognition to detect faces"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "rekognition:DetectFaces",
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy" "read_write_s3" {
  name = "read_write_s3_policy"
  description = "Policy for Lambda to read and write to S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "arn:aws:s3:::${var.s3_bucket_name}/*"
      },
      {
        Effect = "Allow"
        Action = "s3:ListBucket"
        Resource = "arn:aws:s3:::${var.s3_bucket_name}"
      }

    ]
  })
}

resource "aws_iam_role" "lambda_read_write_s3" {
  name = "lambda_read_write_s3_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "role1_lambda_basic_execution" {
  role = aws_iam_role.lambda_read_write_s3.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "role1_read_write_s3" {
	role = aws_iam_role.lambda_read_write_s3.name
	policy_arn = aws_iam_policy.read_write_s3.arn
}


resource "aws_iam_role" "lambda_rekognition_and_read_write_s3" {
  name = "lambda_rekognition_and_read_write_s3_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "role2_lambda_basic_execution" {
  role = aws_iam_role.lambda_rekognition_and_read_write_s3.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "role2_rekognition_detect_faces" {
	role = aws_iam_role.lambda_rekognition_and_read_write_s3.name
	policy_arn = aws_iam_policy.rekognition_detect_faces.arn
}

resource "aws_iam_role_policy_attachment" "role2_read_write_s3" {
	role = aws_iam_role.lambda_rekognition_and_read_write_s3.name
	policy_arn = aws_iam_policy.read_write_s3.arn
}


resource "aws_lambda_function" "update_current_image_function" {
  function_name = "updateCurrentImage"
  role = aws_iam_role.lambda_read_write_s3.arn
  handler = "lambda_function.lambda_handler"
  runtime = "python3.10"

  filename = "./assets/lambda-functions/updateCurrentImage.zip"
	source_code_hash = filebase64sha256("./assets/lambda-functions/updateCurrentImage.zip")
	timeout = 500

	environment {
		variables = {
			SNS_TOPIC_ARN = aws_sns_topic.email_notification_topic.arn
			S3_BUCKET_NAME = aws_s3_bucket.crowd_images.bucket
			PATH_TO_CROWD_IMAGES = var.s3_crowd_images_directory
			PATH_TO_CURRENT_IMAGE = var.s3_current_image_file_name
		}
	}
}

resource "aws_lambda_function" "get_random_cropped_face_in_current_image_function" {
	function_name = "getRandomCroppedFaceInCurrentImage"
	role = aws_iam_role.lambda_rekognition_and_read_write_s3.arn
	handler = "lambda_function.lambda_handler"
	runtime = "python3.10"
	timeout = 500

	filename = "./assets/lambda-functions/getRandomCroppedFaceInCurrentImage.zip"
	source_code_hash = filebase64sha256("./assets/lambda-functions/getRandomCroppedFaceInCurrentImage.zip")

	environment {
		variables = {
			S3_BUCKET_NAME = aws_s3_bucket.crowd_images.bucket
			PATH_TO_CURRENT_IMAGE = var.s3_current_image_file_name
			PATH_TO_CROPPED_IMAGE = var.s3_cropped_image_file_name
		}
	}
}

resource "aws_lambda_function" "upload_image" {
	function_name = "uploadImage"
	role = aws_iam_role.lambda_read_write_s3.arn
	handler = "lambda_function.lambda_handler"
	runtime = "python3.10"

	filename = "./assets/lambda-functions/uploadImage.zip"
	source_code_hash = filebase64sha256("./assets/lambda-functions/uploadImage.zip")
	timeout = 500

	environment {
		variables = {
			S3_BUCKET_NAME = aws_s3_bucket.crowd_images.bucket
			PATH_TO_CURRENT_IMAGE = var.s3_current_image_file_name
		}
	}
}