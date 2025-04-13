# Variables
variable "s3_bucket_name" {
	type = string
	description = "The name of the S3 bucket"
	default = "projectawscrowdimages3bucket2"
}

variable "s3_crowd_images_directory" {
	type = string
	description = "The name the directory that contains the crowd images"
	default = "crowd-images"
}

variable "s3_current_image_file_name" {
	type = string
	description = "The name of the file that contains the current image"
	default = "current-image.png"
}

variable "s3_cropped_image_file_name" {
	type = string
	description = "The name of the file that contains the cropped face image"
	default = "cropped-face-image.png"
}

# Resources Built
resource "aws_s3_bucket" "crowd_images" {
  bucket = var.s3_bucket_name

	force_destroy = true

	lifecycle {
		prevent_destroy = false
	}
}

resource "aws_s3_bucket_policy" "crowd_images_public_access" {
  bucket = aws_s3_bucket.crowd_images.id

  policy = data.aws_iam_policy_document.crowd_images_public_access.json
}

data "aws_iam_policy_document" "crowd_images_public_access" {
  statement {
    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.crowd_images.arn}/*"
    ]

    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = ["*"]
    }
  }
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
	depends_on = [
		aws_s3_bucket.crowd_images
	]

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
  key = "${var.s3_crowd_images_directory}/crowd-image1.png"
  source = "./assets/crowd-images/crowdimage1.png"  # Local file path
}

resource "aws_s3_object" "crowd_image_2" {
  bucket = aws_s3_bucket.crowd_images.bucket
  key = "${var.s3_crowd_images_directory}/crowd-image2.png"
  source = "./assets/crowd-images/crowdimage2.png"
}

resource "aws_s3_object" "crowd_image_3" {
  bucket = aws_s3_bucket.crowd_images.bucket
  key = "${var.s3_crowd_images_directory}/crowd-image3.png"
  source = "./assets/crowd-images/crowdimage3.png"
}

resource "aws_s3_object" "current_image" {
  bucket = aws_s3_bucket.crowd_images.bucket
  key = var.s3_current_image_file_name
  source = "./assets/crowd-images/crowdimage3.png"
}