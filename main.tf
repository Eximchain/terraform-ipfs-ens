terraform {
  required_version = ">= 0.12"
}

# ---------------------------------------------------------------------------------------------------------------------
# PROVIDERS
# ---------------------------------------------------------------------------------------------------------------------

  provider "aws" {
    region  = var.aws_region
    version = "~> 2.2"
  }

  provider "null" {
    version = "~> 2.1"
  }

  locals {
    stage = var.root_domain == "dapp.bot" ? var.subdomain == "ipfs-api" ? "prod" : "staging" : "dev"

    default_tags = {
      Application = "IPFS-ENS"
      ManagedBy   = "Terraform"
    }
    created_dns_root   = ".${var.root_domain}"
    api_domain         = "${var.subdomain}.${var.root_domain}"
    provision_api_cert = var.existing_cert_domain == ""

    // Remove invalid characters from names
    sanitized_subdomain = replace(var.subdomain, ".", "-")

    alternate_api_cert_aliases = [local.deployment_website_dns]
    all_api_cert_aliases       = concat([local.api_domain], local.alternate_api_cert_aliases)
    api_cert_arn               = element(
      coalescelist(
        data.aws_acm_certificate.api_cert.*.arn,
        aws_acm_certificate.api_cert.*.arn,
        [""],
      ),
      0,
    )

    deployment_website_dns = var.deployment_website_subdomain == "" ? var.root_domain : "${var.deployment_website_subdomain}.${var.root_domain}"

    s3_artifact_bucket_arn_pattern = "arn:aws:s3:::ipfs-ens-artifacts-*"

    api_gateway_source_arn = "${aws_api_gateway_rest_api.ipfs_ens_api.execution_arn}/*/*/*"

    base_lambda_uri         = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions"
    start_deploy_lambda_uri = "${local.base_lambda_uri}/${aws_lambda_function.start_deploy_lambda.arn}/invocations"
    token_fetch_lambda_uri = "${local.base_lambda_uri}/${aws_lambda_function.token_fetch_lambda.arn}/invocations"
  }

# ---------------------------------------------------------------------------------------------------------------------
# DATA SOURCES
# ---------------------------------------------------------------------------------------------------------------------

  data "aws_caller_identity" "current" {
  }

  data "aws_route53_zone" "hosted_zone" {
    name = "${var.root_domain}."
  }

# ---------------------------------------------------------------------------------------------------------------------
# SHARED S3 BUCKETS & KEY
# ---------------------------------------------------------------------------------------------------------------------

  resource "aws_s3_bucket" "artifact_bucket" {
    bucket        = "ipfs-ens-artifacts-${var.subdomain}"
    acl           = "private"
    force_destroy = true

    tags = local.default_tags
  }

  resource "aws_s3_bucket" "lambda_deployment_packages" {
    bucket        = "ipfs-ens-lambda-packages-${var.subdomain}"
    acl           = "private"
    force_destroy = true

    tags = local.default_tags
  }

  resource "aws_s3_bucket_object" "default_function" {
    bucket = aws_s3_bucket.lambda_deployment_packages.bucket
    key    = "default-lambda.zip"
    source = "${path.module}/default-lambda.zip"
  }

# ---------------------------------------------------------------------------------------------------------------------
# LAMBDA FUNCTiONS
# ---------------------------------------------------------------------------------------------------------------------

  # Wait ensures that the role is fully created when Lambda tries to assume it.
  resource "null_resource" "ipfs_ens_lambda_wait" {
    provisioner "local-exec" {
      command = "sleep 10"
    }
    depends_on = [aws_iam_role.ipfs_ens_lambda_iam]
  }

  module "dappbot_ipfs_ens_lambda_pipeline" {
    source = "git@github.com:Eximchain/terraform-aws-lambda-cd-pipeline.git"

    id = "ipfs-ens-lambda-${local.sanitized_subdomain}"

    github_lambda_repo    = "ipfs-ens-lambda"
    github_lambda_branch  = var.ipfs_ens_lambda_branch_override != "" ? var.ipfs_ens_lambda_branch_override : var.lambda_default_branch
    build_command         = "npm install && npm run build"

    deployment_package_filename    = "ipfs-ens-lambda.zip"
    deployment_package_bucket_name = aws_s3_bucket.lambda_deployment_packages.bucket

    deployment_target_lambdas = [
      aws_lambda_function.start_deploy_lambda.function_name,
      aws_lambda_function.ipfs_deploy_lambda.function_name,
      aws_lambda_function.ens_deploy_lambda.function_name,
      aws_lambda_function.token_fetch_lambda.function_name,
      aws_lambda_function.token_check_lambda.function_name,
      aws_lambda_function.pipeline_transition_lambda.function_name
    ]

    npm_user  = var.npm_user
    npm_pass  = var.npm_pass
    npm_email = var.npm_email

    aws_region            = var.aws_region
    force_destroy_buckets = true
  }

  resource "aws_lambda_function" "start_deploy_lambda" {
    s3_bucket        = aws_s3_bucket.lambda_deployment_packages.bucket
    s3_key           = aws_s3_bucket_object.default_function.key
    function_name    = "ipfs-ens-start-deploy-lambda-${local.sanitized_subdomain}"
    role             = aws_iam_role.ipfs_ens_lambda_iam.arn
    handler          = "index.deployStartHandler"
    source_code_hash = filebase64sha256(aws_s3_bucket_object.default_function.source)
    runtime          = "nodejs10.x"
    timeout          = 10

    environment {
      variables = {
        GITHUB_CLIENT_ID           = var.github_client_id
        GITHUB_CLIENT_SECRET       = var.github_client_secret
        DEPLOY_TABLE_NAME          = aws_dynamodb_table.deployments_table.id
        ARTIFACT_BUCKET            = aws_s3_bucket.artifact_bucket.bucket
        PIPELINE_ROLE_ARN          = aws_iam_role.ipfs_ens_codepipeline_iam.arn
        CODEBUILD_BUILD_ID         = aws_codebuild_project.ipfs_builder.id
        SERVICES_LAMBDA_FUNCTION   = aws_lambda_function.ipfs_deploy_lambda.function_name
        TRANSITION_LAMBDA_FUNCTION = aws_lambda_function.pipeline_transition_lambda.function_name
        ENS_DEPLOY_QUEUE           = aws_sqs_queue.ens_deploy_queue.id
      }
    }

    depends_on = [null_resource.ipfs_ens_lambda_wait]

    tags = local.default_tags

    lifecycle {
      ignore_changes = [
        source_code_hash,
        last_modified
      ]
    }
  }

  resource "aws_lambda_function" "ipfs_deploy_lambda" {
    s3_bucket        = aws_s3_bucket.lambda_deployment_packages.bucket
    s3_key           = aws_s3_bucket_object.default_function.key
    function_name    = "ipfs-deploy-lambda-${local.sanitized_subdomain}"
    role             = aws_iam_role.ipfs_ens_lambda_iam.arn
    handler          = "index.deployIpfsHandler"
    source_code_hash = filebase64sha256(aws_s3_bucket_object.default_function.source)
    runtime          = "nodejs10.x"
    timeout          = 10

    environment {
      variables = {
        GITHUB_CLIENT_ID      = var.github_client_id
        GITHUB_CLIENT_SECRET  = var.github_client_secret
        IPFS_ENDPOINT         = var.ipfs_endpoint
        DEPLOY_TABLE_NAME     = aws_dynamodb_table.deployments_table.id
        ENS_DEPLOY_QUEUE      = aws_sqs_queue.ens_deploy_queue.id
      }
    }

    depends_on = [null_resource.ipfs_ens_lambda_wait]

    tags = local.default_tags

    lifecycle {
      ignore_changes = [
        source_code_hash,
        last_modified
      ]
    }
  }

  resource "aws_lambda_function" "ens_deploy_lambda" {
    s3_bucket        = aws_s3_bucket.lambda_deployment_packages.bucket
    s3_key           = aws_s3_bucket_object.default_function.key
    function_name    = "ens-deploy-lambda-${local.sanitized_subdomain}"
    role             = aws_iam_role.ipfs_ens_lambda_iam.arn
    handler          = "index.deployEnsHandler"
    source_code_hash = filebase64sha256(aws_s3_bucket_object.default_function.source)
    runtime          = "nodejs10.x"
    timeout          = 10

    environment {
      variables = {
        GITHUB_CLIENT_ID      = var.github_client_id
        GITHUB_CLIENT_SECRET  = var.github_client_secret
        ETH_KEY               = var.eth_key
        ENS_CONTRACT_ADDRESS  = var.ens_contract_address
        ENS_ROOT_DOMAIN       = var.ens_root_domain
        DEFAULT_GAS_PRICE     = var.default_gas_price
        DEPLOY_TABLE_NAME     = aws_dynamodb_table.deployments_table.id
        NONCE_TABLE_NAME      = aws_dynamodb_table.nonce_table.name
        ENS_DEPLOY_QUEUE      = aws_sqs_queue.ens_deploy_queue.id
      }
    }

    depends_on = [null_resource.ipfs_ens_lambda_wait]

    tags = local.default_tags

    lifecycle {
      ignore_changes = [
        source_code_hash,
        last_modified
      ]
    }
  }

  resource "aws_lambda_function" "token_fetch_lambda" {
    s3_bucket        = aws_s3_bucket.lambda_deployment_packages.bucket
    s3_key           = aws_s3_bucket_object.default_function.key
    function_name    = "token-fetch-lambda-${local.sanitized_subdomain}"
    role             = aws_iam_role.ipfs_ens_lambda_iam.arn
    handler          = "index.tokenFetchHandler"
    source_code_hash = filebase64sha256(aws_s3_bucket_object.default_function.source)
    runtime          = "nodejs10.x"
    timeout          = 10

    environment {
      variables = {
        GITHUB_CLIENT_ID      = var.github_client_id
        GITHUB_CLIENT_SECRET  = var.github_client_secret
      }
    }

    depends_on = [null_resource.ipfs_ens_lambda_wait]

    tags = local.default_tags

    lifecycle {
      ignore_changes = [
        source_code_hash,
        last_modified
      ]
    }
  }

  resource "aws_lambda_function" "token_check_lambda" {
    s3_bucket        = aws_s3_bucket.lambda_deployment_packages.bucket
    s3_key           = aws_s3_bucket_object.default_function.key
    function_name    = "token-check-lambda-${local.sanitized_subdomain}"
    role             = aws_iam_role.ipfs_ens_lambda_iam.arn
    handler          = "index.tokenCheckHandler"
    source_code_hash = filebase64sha256(aws_s3_bucket_object.default_function.source)
    runtime          = "nodejs10.x"
    timeout          = 10

    environment {
      variables = {
        GITHUB_CLIENT_ID      = var.github_client_id
        GITHUB_CLIENT_SECRET  = var.github_client_secret
      }
    }

    depends_on = [null_resource.ipfs_ens_lambda_wait]

    tags = local.default_tags

    lifecycle {
      ignore_changes = [
        source_code_hash,
        last_modified
      ]
    }
  }

  resource "aws_lambda_function" "pipeline_transition_lambda" {
    s3_bucket        = aws_s3_bucket.lambda_deployment_packages.bucket
    s3_key           = aws_s3_bucket_object.default_function.key
    function_name    = "pipeline-transition-lambda-${local.sanitized_subdomain}"
    role             = aws_iam_role.ipfs_ens_lambda_iam.arn
    handler          = "index.pipelineTransitionHandler"
    source_code_hash = filebase64sha256(aws_s3_bucket_object.default_function.source)
    runtime          = "nodejs10.x"
    timeout          = 10

    environment {
      variables = {
        GITHUB_CLIENT_ID      = var.github_client_id
        GITHUB_CLIENT_SECRET  = var.github_client_secret
        DEPLOY_TABLE_NAME     = aws_dynamodb_table.deployments_table.id
      }
    }

    depends_on = [null_resource.ipfs_ens_lambda_wait]

    tags = local.default_tags

    lifecycle {
      ignore_changes = [
        source_code_hash,
        last_modified
      ]
    }
  }

# ---------------------------------------------------------------------------------------------------------------------
# DYNAMODB TABLES
# ---------------------------------------------------------------------------------------------------------------------
  resource "aws_dynamodb_table" "deployments_table" {
    name         = "ipfs-ens-deployments-${var.subdomain}"
    billing_mode = "PAY_PER_REQUEST"
    hash_key     = "EnsName"

    global_secondary_index {
      name     = "UsernameIndex"
      hash_key = "Username"

      projection_type = "ALL"
    }

    attribute {
      name = "EnsName"
      type = "S"
    }

    attribute {
      name = "Username"
      type = "S"
    }

    tags = local.default_tags
  }

  resource "aws_dynamodb_table" "users_table" {
    name         = "ipfs-ens-users-${var.subdomain}"
    billing_mode = "PAY_PER_REQUEST"
    hash_key     = "UserEmail"

    attribute {
      name = "UserEmail"
      type = "S"
    }

    tags = local.default_tags
  }

  resource "aws_dynamodb_table" "nonce_table" {
    name         = "ipfs-ens-nonce-${var.subdomain}"
    billing_mode = "PAY_PER_REQUEST"
    hash_key     = "Chain"

    attribute {
      name = "Chain"
      type = "S"
    }

    tags = local.default_tags
  }

  resource "aws_dynamodb_table_item" "current_nonce" {
    table_name = aws_dynamodb_table.nonce_table.name
    hash_key   = aws_dynamodb_table.nonce_table.hash_key

    item = jsonencode({
        "Chain"={"S"="Ethereum"}
        "NextNonce"={"N"=lookup(var.initial_nonces, "Ethereum")}
      })
    }

# ---------------------------------------------------------------------------------------------------------------------
# SQS QUEUE
# ---------------------------------------------------------------------------------------------------------------------
  resource "aws_sqs_queue" "ens_deploy_queue" {
    name                       = "ens-deploy-queue-${local.sanitized_subdomain}"
    message_retention_seconds  = 3600
    visibility_timeout_seconds = 60

    redrive_policy = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.ens_deploy_queue_deadletter.arn}\",\"maxReceiveCount\":3}"

    tags = local.default_tags
  }

  resource "aws_sqs_queue" "ens_deploy_queue_deadletter" {
    name                       = "ens-deploy-queue-deadletter-${local.sanitized_subdomain}"
    message_retention_seconds  = 1209600
    visibility_timeout_seconds = 30

    tags = local.default_tags
  }

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOYMENT WEBSITE
# ---------------------------------------------------------------------------------------------------------------------
  module "deployment_website" {
    source = "git@github.com:Eximchain/terraform-aws-static-website.git"

    dns_name    = local.deployment_website_dns
    domain_root = var.root_domain

    website_bucket_name = "ipfs-ens-deploy-website-${var.subdomain}"
    log_bucket_name     = "ipfs-ens-deploy-website-logs-${var.subdomain}"

    acm_cert_arn = local.api_cert_arn

    github_website_repo   = "ipfs-ens-spa"
    github_website_branch = var.deployment_website_branch
    deployment_directory  = "build"
    build_command         = "npm install && npm run build"

    force_destroy_buckets = true

    npm_user  = var.npm_user
    npm_pass  = var.npm_pass
    npm_email = var.npm_email

    env = {
      REACT_APP_IPFS_ENS_API_URL          = "https://${local.api_domain}"
      REACT_APP_WEB3_URL                  = "https://gamma-tx-executor-us-east.eximchain-dev.com"
      REACT_APP_SEGMENT_BROWSER_WRITE_KEY = var.segment_browser_write_key
      REACT_APP_OAUTH_CLIENT_ID           = var.github_client_id
    }
  }

# ---------------------------------------------------------------------------------------------------------------------
# ACM CERT for API
# ---------------------------------------------------------------------------------------------------------------------
  data "aws_acm_certificate" "api_cert" {
    count = local.provision_api_cert ? 0 : 1

    domain      = var.existing_cert_domain
    most_recent = true
  }

  resource "aws_acm_certificate" "api_cert" {
    count = local.provision_api_cert ? 1 : 0

    domain_name               = local.api_domain
    subject_alternative_names = local.alternate_api_cert_aliases
    validation_method         = "DNS"
  }

  resource "aws_acm_certificate_validation" "api_cert" {
    count = local.provision_api_cert ? 1 : 0

    certificate_arn         = element(coalescelist(aws_acm_certificate.api_cert.*.arn, [""]), 0)
    validation_record_fqdns = aws_route53_record.api_cert_validation.*.fqdn

    provisioner "local-exec" {
      command = "sleep 20"
    }
  }

  resource "aws_route53_record" "api_cert_validation" {
    count = local.provision_api_cert ? length(local.all_api_cert_aliases) : 0

    name    = aws_acm_certificate.api_cert.0.domain_validation_options[count.index]["resource_record_name"]
    type    = aws_acm_certificate.api_cert.0.domain_validation_options[count.index]["resource_record_type"]
    zone_id = data.aws_route53_zone.hosted_zone.zone_id
    records = [aws_acm_certificate.api_cert.0.domain_validation_options[count.index]["resource_record_value"]]
    ttl     = 60
  }

# ---------------------------------------------------------------------------------------------------------------------
# CODEBUILD PROJECT
# ---------------------------------------------------------------------------------------------------------------------
  resource "aws_codebuild_project" "ipfs_builder" {
    name          = "ipfs-builder-${local.sanitized_subdomain}"
    build_timeout = 10
    service_role  = aws_iam_role.ipfs_ens_codepipeline_iam.arn

    environment {
      type         = "LINUX_CONTAINER"
      compute_type = "BUILD_GENERAL1_SMALL"
      image        = "aws/codebuild/standard:2.0"
    }

    artifacts {
      type                = "CODEPIPELINE"
      encryption_disabled = true
    }

    source {
      type      = "CODEPIPELINE"
      buildspec = file("${path.module}/buildspec.yml")
    }
  }