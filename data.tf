data "aws_iam_policy_document" "allow_access_from_owner_read" {
  statement {
    actions   = ["s3:BucketOwnerRead"]
    resources = [aws_s3_bucket.history.arn, aws_s3_bucket.iot.arn]
    effect    = "Allow"
  }
}