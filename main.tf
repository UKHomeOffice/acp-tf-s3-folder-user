data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_kms_key" "s3_bucket_kms_key" {
  description = "A kms key for encrypting/decrypting S3 bucket ${var.bucket_name} within path ${var.bucket_path}"
  policy      = "${data.aws_iam_policy_document.kms_key_policy_document.json}"
}

resource "aws_kms_alias" "s3_bucket_kms_alias" {
  name          = "alias/${var.kms_alias}"
  target_key_id = "${aws_kms_key.s3_bucket_kms_key.key_id}"
}

resource "aws_iam_user" "s3_bucket_iam_user" {
  name = "${var.iam_user}"
  path = "/"
}

data "aws_iam_policy_document" "kms_key_policy_document" {
  policy_id = "${var.kms_alias}KMSPolicy"

  statement {
    sid    = "IAMPermissions"
    effect = "Allow"

    resources = ["*"]

    actions = [
      "kms:*",
    ]

    principals {
      type = "AWS"

      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
      ]
    }
  }
}

data "aws_iam_policy_document" "s3_folder_policy_document" {
  policy_id = "${var.iam_user}-S3BucketPolicy"

  statement {
    sid    = "IAMS3BucketPermissions1"
    effect = "Allow"

    resources = [
      "${var.bucket_arn}",
    ]

    actions = [
      "s3:ListBucket",
    ]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"

      values = [
        "${var.bucket_path}*",
      ]
    }
  }

  statement {
    sid    = "IAMS3ObjectPermissions2"
    effect = "Allow"

    resources = [
      "${var.bucket_arn}/${var.bucket_path}*",
    ]

    actions = [
      "s3:PutObject",
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["aws:kms"]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
      values   = ["${aws_kms_key.s3_bucket_kms_key.arn}"]
    }
  }

  statement {
    sid    = "IAMS3ObjectPermissions3"
    effect = "Allow"

    resources = [
      "${var.bucket_arn}/${var.bucket_path}*",
    ]

    actions = [
      "s3:AbortMultipartUpload",
      "s3:CreateMultipartUpload",
      "s3:DeleteObject",
      "s3:DeleteObjectTagging",
      "s3:DeleteObjectVersion",
      "s3:DeleteObjectVersionTagging",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:GetObjectTagging",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListBucketVersions",
      "s3:ListMultipartUploadParts",
      "s3:PutObjectAcl",
      "s3:PutObjectTagging",
      "s3:RestoreObject",
    ]
  }
}

resource "aws_iam_user_policy_attachment" "attach_s3_folder_iam_policy" {
  user       = "${aws_iam_user.s3_bucket_iam_user.name}"
  policy_arn = "${aws_iam_policy.s3_folder_iam_policy.arn}"
}

resource "aws_iam_policy" "s3_folder_iam_policy" {
  name        = "${var.iam_user}-S3FolderIamPolicy"
  policy      = "${data.aws_iam_policy_document.s3_folder_policy_document.json}"
  description = "Policy for bucket and object permissions"
}

data "aws_iam_policy_document" "s3_folder_kms_policy_document" {
  policy_id = "${var.iam_user}KMSPolicy"

  statement {
    sid    = "KMSPermissions"
    effect = "Allow"

    resources = [
      "${aws_kms_key.s3_bucket_kms_key.arn}",
      "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:alias/${var.kms_alias}",
    ]

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:GenerateRandom",
      "kms:GetKeyPolicy",
      "kms:GetKeyRotationStatus",
      "kms:ReEncrypt*",
    ]
  }
}

resource "aws_iam_policy" "s3_folder_kms_iam_policy" {
  name        = "${var.iam_user}-S3FolderKMSIamPolicy"
  policy      = "${data.aws_iam_policy_document.s3_folder_kms_policy_document.json}"
  description = "Policy for kms key permissions"
}

resource "aws_iam_user_policy_attachment" "attach_s3_bucket_kms_iam_policy" {
  user       = "${aws_iam_user.s3_bucket_iam_user.name}"
  policy_arn = "${aws_iam_policy.s3_folder_kms_iam_policy.arn}"
}
