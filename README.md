# acp-tf-s3-folder-user
Create a user/kms key with access to a single s3 bucket folder

## Module Usage

```
module "example_bucket_example_folder_user" {
  source      = "git::https://github.com/UKHomeOffice/acp-tf-s3-folder-user?ref=0.0.1"
  bucket_arn  = "${module.example_bucket.s3_bucket_arn}"
  bucket_name = "${module.example_bucket.s3_bucket_id}"
  bucket_path = "example/folder/"
  iam_user    = "example-bucket-example-folder-user"
  kms_alias   = "example-bucket-example-folder-kms"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| bucket\_arn |  | string | n/a | yes |
| bucket\_name |  | string | n/a | yes |
| bucket\_path |  | string | `""` | no |
| iam\_user |  | string | n/a | yes |
| kms\_alias |  | string | n/a | yes |