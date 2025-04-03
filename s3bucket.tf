# Resources Built
resource "aws_s3_bucket" "crowd_images" {
  bucket = "projectawscrowdimages3bucket"

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
  key = "crowd-images/crowd-image1.png"
  source = "./assets/crowd-images/crowdimage1.png"  # Local file path
}

resource "aws_s3_object" "crowd_image_2" {
  bucket = aws_s3_bucket.crowd_images.bucket
  key = "crowd-images/crowd-image2.png"
  source = "./assets/crowd-images/crowdimage2.png"
}

resource "aws_s3_object" "crowd_image_3" {
  bucket = aws_s3_bucket.crowd_images.bucket
  key = "crowd-images/crowd-image3.png"
  source = "./assets/crowd-images/crowdimage3.png"
}

resource "aws_s3_object" "current_image" {
  bucket = aws_s3_bucket.crowd_images.bucket
  key = "current-image.png"
  source = "./assets/crowd-images/crowdimage3.png"
}


# Outputs
output "s3_bucket_url" {
  value = "https://${aws_s3_bucket.crowd_images.bucket}.s3.amazonaws.com/"
}