# ---------------------------------------------------------------------------------------------------------------------
# IPFS ENS LAMBDA ROLE
# ---------------------------------------------------------------------------------------------------------------------
  resource "aws_iam_role" "ipfs_ens_lambda_iam" {
    name = "ipfs-ens-lambda-iam-${var.subdomain}"

    assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

    tags = local.default_tags
  }

  # Cloudwatch (Logs)
  resource "aws_iam_role_policy_attachment" "ipfs_ens_api_cloudwatch" {
    role       = aws_iam_role.ipfs_ens_lambda_iam.id
    policy_arn = aws_iam_policy.lambda_allow_write_cloudwatch_logs.arn
  }

  # DynamoDB
  resource "aws_iam_role_policy_attachment" "ipfs_ens_api_dynamodb_deployments" {
    role       = aws_iam_role.ipfs_ens_lambda_iam.id
    policy_arn = aws_iam_policy.dynamodb_deployments_table_read_write.arn
  }

  resource "aws_iam_role_policy_attachment" "ipfs_ens_api_dynamodb_users" {
    role       = aws_iam_role.ipfs_ens_lambda_iam.id
    policy_arn = aws_iam_policy.dynamodb_users_table_read_write.arn
  }

  resource "aws_iam_role_policy_attachment" "ipfs_ens_api_dynamodb_nonce" {
    role       = aws_iam_role.ipfs_ens_lambda_iam.id
    policy_arn = aws_iam_policy.dynamodb_nonce_table_read_write.arn
  }

  # CodePipeline
  resource "aws_iam_role_policy_attachment" "ipfs_ens_api_create_codepipeline" {
    role       = aws_iam_role.ipfs_ens_lambda_iam.id
    policy_arn = aws_iam_policy.codepipeline_create_delete_pipeline.arn
  }

  resource "aws_iam_role_policy_attachment" "ipfs_ens_api_put_codepipeline_result" {
    role       = aws_iam_role.ipfs_ens_lambda_iam.id
    policy_arn = aws_iam_policy.codepipeline_put_job_result.arn
  }

  resource "aws_iam_role_policy_attachment" "ipfs_ens_api_pass_role" {
    role       = aws_iam_role.ipfs_ens_lambda_iam.id
    policy_arn = aws_iam_policy.iam_pass_role_to_codepipeline.arn
  }

# ---------------------------------------------------------------------------------------------------------------------
# CODEPIPELINE IAM ROLE
# ---------------------------------------------------------------------------------------------------------------------
  resource "aws_iam_role" "ipfs_ens_codepipeline_iam" {
    name = "ipfs-ens-codepipeline-role-${var.subdomain}"

    assume_role_policy = data.aws_iam_policy_document.codepipeline_assume_role.json

    tags = local.default_tags
  }

  # Cloudwatch (Logs)
  resource "aws_iam_role_policy_attachment" "ipfs_ens_codepipeline_cloudwatch_logs" {
    role       = aws_iam_role.ipfs_ens_codepipeline_iam.id
    policy_arn = aws_iam_policy.lambda_allow_write_cloudwatch_logs.arn
  }

  # Lambda (Invoke)
  resource "aws_iam_role_policy_attachment" "ipfs_ens_codepipeline_invoke" {
    role       = aws_iam_role.ipfs_ens_codepipeline_iam.id
    policy_arn = aws_iam_policy.lambda_invoke.arn
  }

  # S3
  resource "aws_iam_role_policy_attachment" "ipfs_ens_codepipeline_s3" {
    role       = aws_iam_role.ipfs_ens_codepipeline_iam.id
    policy_arn = aws_iam_policy.s3_full_access_managed_buckets.arn
  }

  # Codebuild
  resource "aws_iam_role_policy_attachment" "ipfs_ens_codepipeline_codebuild" {
    role       = aws_iam_role.ipfs_ens_codepipeline_iam.id
    policy_arn = aws_iam_policy.codebuild_build_part.arn
  }

  # ECR
  resource "aws_iam_role_policy_attachment" "ipfs_ens_codepipeline_ecr" {
    role       = aws_iam_role.ipfs_ens_codepipeline_iam.id
    policy_arn = aws_iam_policy.ecr_read_only.arn
  }

# ---------------------------------------------------------------------------------------------------------------------
# API GATEWAY AUTHORIZER ROLE
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "ipfs_ens_gateway_authorizer" {
  name = "ipfs-ens-gateway-authorizer-role-${var.subdomain}"

  assume_role_policy = data.aws_iam_policy_document.api_gateway_assume_role.json

  tags = local.default_tags
}

resource "aws_iam_role_policy_attachment" "ipfs_ens_gateway_authorizer_invoke" {
  role = aws_iam_role.ipfs_ens_gateway_authorizer.id
  policy_arn = aws_iam_policy.lambda_invoke.arn
}