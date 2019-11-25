# ---------------------------------------------------------------------------------------------------------------------
# API GATEWAY
# ---------------------------------------------------------------------------------------------------------------------

  resource "aws_api_gateway_rest_api" "ipfs_ens_api" {
    name        = "ipfs-ens-${var.subdomain}"
    description = "Proxy to handle requests to the IPFS-ENS Deploy API"
  }

# ---------------------------------------------------------------------------------------------------------------------
# API GATEWAY CUSTOM AUTHORIZER
# ---------------------------------------------------------------------------------------------------------------------
  resource "aws_api_gateway_authorizer" "ipfs_ens_github_auth" {
    name = "ipfs_ens_github_auth"
    rest_api_id = aws_api_gateway_rest_api.ipfs_ens_api.id
    authorizer_uri = aws_lambda_function.token_check_lambda.invoke_arn
    authorizer_credentials = aws_iam_role.ipfs_ens_lambda_iam.arn
  }

# ---------------------------------------------------------------------------------------------------------------------
# API GATEWAY: `/deployments/` API
# ---------------------------------------------------------------------------------------------------------------------

  resource "aws_api_gateway_resource" "ipfs_ens_deployments" {
    rest_api_id = aws_api_gateway_rest_api.ipfs_ens_api.id
    parent_id   = aws_api_gateway_rest_api.ipfs_ens_api.root_resource_id
    path_part   = "deployment"
  }

  resource "aws_api_gateway_method" "ipfs_ens_deployments_get" {
    rest_api_id = aws_api_gateway_rest_api.ipfs_ens_api.id
    resource_id = aws_api_gateway_resource.ipfs_ens_deployments.id
    http_method = "GET"

    authorization = "CUSTOM"
    authorizer_id = aws_api_gateway_authorizer.ipfs_ens_github_auth.id
  }

  resource "aws_api_gateway_method_response" "ipfs_ens_deployments_get" {
    rest_api_id = aws_api_gateway_rest_api.ipfs_ens_api.id
    resource_id = aws_api_gateway_resource.ipfs_ens_deployments.id
    http_method = aws_api_gateway_method.ipfs_ens_deployments_get.http_method
    status_code = "200"
    response_parameters = {
      "method.response.header.Access-Control-Allow-Origin" = true
    }

    depends_on = [aws_api_gateway_method.ipfs_ens_deployments_get]
  }

  resource "aws_api_gateway_integration" "ipfs_ens_deployments_get" {
    rest_api_id = aws_api_gateway_rest_api.ipfs_ens_api.id
    resource_id = aws_api_gateway_resource.ipfs_ens_deployments.id
    http_method = aws_api_gateway_method.ipfs_ens_deployments_get.http_method

    integration_http_method = "POST"
    type                    = "AWS_PROXY"
    uri                     = local.start_deploy_lambda_uri

    depends_on = [
      aws_api_gateway_method.ipfs_ens_deployments_get,
      aws_lambda_function.start_deploy_lambda
    ]
  }

# ---------------------------------------------------------------------------------------------------------------------
# API GATEWAY: `/deployments/{proxy}` API
# ---------------------------------------------------------------------------------------------------------------------

  resource "aws_api_gateway_resource" "ipfs_ens_deployments_proxy" {
    rest_api_id = aws_api_gateway_rest_api.ipfs_ens_api.id
    parent_id   = aws_api_gateway_resource.ipfs_ens_deployments.id
    path_part   = "{proxy+}"
  }

  resource "aws_api_gateway_method" "ipfs_ens_deployments_proxy_any" {
    rest_api_id = aws_api_gateway_rest_api.ipfs_ens_api.id
    resource_id = aws_api_gateway_resource.ipfs_ens_deployments_proxy.id
    http_method = "ANY"

    authorization = "CUSTOM"
    authorizer_id = aws_api_gateway_authorizer.ipfs_ens_github_auth.id

    request_parameters = {
      "method.request.path.proxy" = true
    }
  }

  resource "aws_api_gateway_method_response" "ipfs_ens_deployments_proxy_any" {
    rest_api_id = aws_api_gateway_rest_api.ipfs_ens_api.id
    resource_id = aws_api_gateway_resource.ipfs_ens_deployments_proxy.id
    http_method = aws_api_gateway_method.ipfs_ens_deployments_proxy_any.http_method
    status_code = "200"
    response_parameters = {
      "method.response.header.Access-Control-Allow-Origin" = true
    }

    depends_on = [aws_api_gateway_method.ipfs_ens_deployments_proxy_any]
  }

  resource "aws_api_gateway_integration" "ipfs_ens_deployments_proxy_any" {
    rest_api_id = aws_api_gateway_rest_api.ipfs_ens_api.id
    resource_id = aws_api_gateway_resource.ipfs_ens_deployments_proxy.id
    http_method = aws_api_gateway_method.ipfs_ens_deployments_proxy_any.http_method

    integration_http_method = "POST"
    type                    = "AWS_PROXY"
    uri                     = local.start_deploy_lambda_uri

    request_parameters = {
      "integration.request.path.proxy" = "method.request.path.proxy"
    }

    depends_on = [
      aws_api_gateway_method.ipfs_ens_deployments_proxy_any,
      aws_lambda_function.start_deploy_lambda
    ]
  }


# ---------------------------------------------------------------------------------------------------------------------
# API GATEWAY: `/login/` API
# ---------------------------------------------------------------------------------------------------------------------

  resource "aws_api_gateway_resource" "ipfs_ens_login" {
    rest_api_id = aws_api_gateway_rest_api.ipfs_ens_api.id
    parent_id   = aws_api_gateway_rest_api.ipfs_ens_api.root_resource_id
    path_part   = "login"
  }

  resource "aws_api_gateway_method" "ipfs_ens_login_post" {
    rest_api_id = aws_api_gateway_rest_api.ipfs_ens_api.id
    resource_id = aws_api_gateway_resource.ipfs_ens_login.id
    http_method = "POST"

    authorization = "NONE"

    request_parameters = {
      "method.request.path.proxy" = true
    }
  }

  resource "aws_api_gateway_method_response" "ipfs_ens_login_post" {
    rest_api_id = aws_api_gateway_rest_api.ipfs_ens_api.id
    resource_id = aws_api_gateway_resource.ipfs_ens_login.id
    http_method = aws_api_gateway_method.ipfs_ens_login_post.http_method
    status_code = "200"
    response_parameters = {
      "method.response.header.Access-Control-Allow-Origin" = true
    }

    depends_on = [aws_api_gateway_method.ipfs_ens_login_post]
  }

  resource "aws_api_gateway_integration" "ipfs_ens_login_post" {
    rest_api_id = aws_api_gateway_rest_api.ipfs_ens_api.id
    resource_id = aws_api_gateway_resource.ipfs_ens_login.id
    http_method = aws_api_gateway_method.ipfs_ens_login_post.http_method

    integration_http_method = "POST"
    type                    = "AWS_PROXY"
    uri                     = local.token_fetch_lambda_uri

    request_parameters = {
      "integration.request.path.proxy" = "method.request.path.proxy"
    }

    depends_on = [
      aws_api_gateway_method.ipfs_ens_login_post,
      aws_lambda_function.token_fetch_lambda
    ]
  }


# ---------------------------------------------------------------------------------------------------------------------
# API GATEWAY: `/deployments/` CORS PREFLIGHT HANDLING
# ---------------------------------------------------------------------------------------------------------------------

  resource "aws_api_gateway_method" "ipfs_ens_deployments_cors" {
    rest_api_id = aws_api_gateway_rest_api.ipfs_ens_api.id
    resource_id = aws_api_gateway_resource.ipfs_ens_deployments.id
    http_method = "OPTIONS"

    authorization = "NONE"
  }

  resource "aws_api_gateway_method_response" "ipfs_ens_deployments_cors" {
    rest_api_id = aws_api_gateway_rest_api.ipfs_ens_api.id
    resource_id = aws_api_gateway_resource.ipfs_ens_deployments.id
    http_method = aws_api_gateway_method.ipfs_ens_deployments_cors.http_method
    status_code = "200"

    response_parameters = {
      "method.response.header.Access-Control-Allow-Headers" = true
      "method.response.header.Access-Control-Allow-Methods" = true
      "method.response.header.Access-Control-Allow-Origin"  = true
    }

    response_models = {
      "application/json" = "Empty"
    }

    depends_on = [
      aws_api_gateway_method.ipfs_ens_deployments_cors
    ]
  }

  resource "aws_api_gateway_integration" "ipfs_ens_deployments_cors" {
    rest_api_id = aws_api_gateway_rest_api.ipfs_ens_api.id
    resource_id = aws_api_gateway_resource.ipfs_ens_deployments.id
    http_method = aws_api_gateway_method.ipfs_ens_deployments_cors.http_method

    type = "MOCK"

    request_templates = { 
      "application/json" = "{ \"statusCode\": 200   }"
    }

    depends_on = [
      aws_api_gateway_method.ipfs_ens_deployments_cors
    ]
  }

  resource "aws_api_gateway_integration_response" "ipfs_ens_deployments_cors" {
    rest_api_id = aws_api_gateway_rest_api.ipfs_ens_api.id
    resource_id = aws_api_gateway_resource.ipfs_ens_deployments.id
    http_method = aws_api_gateway_method.ipfs_ens_deployments_cors.http_method
    status_code = aws_api_gateway_method_response.ipfs_ens_deployments_cors.status_code

    response_parameters = {
      "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
      "method.response.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
      "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    }

    depends_on = [
      aws_api_gateway_integration.ipfs_ens_deployments_cors,
      aws_api_gateway_method.ipfs_ens_deployments_cors
    ]
  }

# ---------------------------------------------------------------------------------------------------------------------
# API GATEWAY: `/deployments/{proxy}` CORS PREFLIGHT HANDLING
# ---------------------------------------------------------------------------------------------------------------------

  resource "aws_api_gateway_method" "ipfs_ens_deployments_proxy_cors" {
    rest_api_id = aws_api_gateway_rest_api.ipfs_ens_api.id
    resource_id = aws_api_gateway_resource.ipfs_ens_deployments_proxy.id
    http_method = "OPTIONS"

    authorization = "NONE"
  }

  resource "aws_api_gateway_method_response" "ipfs_ens_deployments_proxy_cors" {
    rest_api_id = aws_api_gateway_rest_api.ipfs_ens_api.id
    resource_id = aws_api_gateway_resource.ipfs_ens_deployments_proxy.id
    http_method = aws_api_gateway_method.ipfs_ens_deployments_proxy_cors.http_method
    status_code = "200"

    response_parameters = {
      "method.response.header.Access-Control-Allow-Headers" = true
      "method.response.header.Access-Control-Allow-Methods" = true
      "method.response.header.Access-Control-Allow-Origin"  = true
    }

    response_models = {
      "application/json" = "Empty"
    }

    depends_on = [aws_api_gateway_method.ipfs_ens_deployments_proxy_cors]
  }

  resource "aws_api_gateway_integration" "ipfs_ens_deployments_proxy_cors" {
    rest_api_id = aws_api_gateway_rest_api.ipfs_ens_api.id
    resource_id = aws_api_gateway_resource.ipfs_ens_deployments_proxy.id
    http_method = aws_api_gateway_method.ipfs_ens_deployments_proxy_cors.http_method

    type = "MOCK"

    request_templates = { 
      "application/json" = "{ \"statusCode\": 200 }"
    }

    depends_on = [aws_api_gateway_method.ipfs_ens_deployments_proxy_cors]
  }

  resource "aws_api_gateway_integration_response" "ipfs_ens_deployments_proxy_cors" {
    rest_api_id = aws_api_gateway_rest_api.ipfs_ens_api.id
    resource_id = aws_api_gateway_resource.ipfs_ens_deployments_proxy.id
    http_method = aws_api_gateway_method.ipfs_ens_deployments_proxy_cors.http_method
    status_code = aws_api_gateway_method_response.ipfs_ens_deployments_proxy_cors.status_code

    response_parameters = {
      "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
      "method.response.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
      "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    }

    depends_on = [
      aws_api_gateway_integration.ipfs_ens_deployments_proxy_cors, 
      aws_api_gateway_method_response.ipfs_ens_deployments_proxy_cors
    ]
  }

# ---------------------------------------------------------------------------------------------------------------------
# API GATEWAY: `/login/` CORS PREFLIGHT HANDLING
# ---------------------------------------------------------------------------------------------------------------------

  resource "aws_api_gateway_method" "ipfs_ens_login_cors" {
    rest_api_id = aws_api_gateway_rest_api.ipfs_ens_api.id
    resource_id = aws_api_gateway_resource.ipfs_ens_login.id
    http_method = "OPTIONS"

    authorization = "NONE"
  }

  resource "aws_api_gateway_method_response" "ipfs_ens_login_cors" {
    rest_api_id = aws_api_gateway_rest_api.ipfs_ens_api.id
    resource_id = aws_api_gateway_resource.ipfs_ens_login.id
    http_method = aws_api_gateway_method.ipfs_ens_login_cors.http_method
    status_code = "200"

    response_parameters = {
      "method.response.header.Access-Control-Allow-Headers" = true
      "method.response.header.Access-Control-Allow-Methods" = true
      "method.response.header.Access-Control-Allow-Origin"  = true
    }

    response_models = {
      "application/json" = "Empty"
    }

    depends_on = [
      aws_api_gateway_method.ipfs_ens_login_cors
    ]
  }

  resource "aws_api_gateway_integration" "ipfs_ens_login_cors" {
    rest_api_id = aws_api_gateway_rest_api.ipfs_ens_api.id
    resource_id = aws_api_gateway_resource.ipfs_ens_login.id
    http_method = aws_api_gateway_method.ipfs_ens_login_cors.http_method

    type = "MOCK"

    request_templates = { 
      "application/json" = "{ \"statusCode\": 200   }"
    }

    depends_on = [
      aws_api_gateway_method.ipfs_ens_login_cors
    ]
  }

  resource "aws_api_gateway_integration_response" "ipfs_ens_login_cors" {
    rest_api_id = aws_api_gateway_rest_api.ipfs_ens_api.id
    resource_id = aws_api_gateway_resource.ipfs_ens_login.id
    http_method = aws_api_gateway_method.ipfs_ens_login_cors.http_method
    status_code = aws_api_gateway_method_response.ipfs_ens_login_cors.status_code

    response_parameters = {
      "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
      "method.response.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
      "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    }

    depends_on = [
      aws_api_gateway_integration.ipfs_ens_login_cors,
      aws_api_gateway_method.ipfs_ens_login_cors
    ]
  }

# ---------------------------------------------------------------------------------------------------------------------
# API GATEWAY RESPONSES
# ---------------------------------------------------------------------------------------------------------------------
  resource "aws_api_gateway_gateway_response" "access_denied" {
    rest_api_id   = aws_api_gateway_rest_api.ipfs_ens_api.id
    response_type = "ACCESS_DENIED"
    status_code   = "403"

    response_parameters = {
      "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
      "gatewayresponse.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
      "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
    }

    response_templates = {
      "application/json" = "{\"message\":$context.error.messageString}"
    }
  }

  resource "aws_api_gateway_gateway_response" "api_configuration_error" {
    rest_api_id   = aws_api_gateway_rest_api.ipfs_ens_api.id
    response_type = "API_CONFIGURATION_ERROR"
    status_code   = "500"

    response_parameters = {
      "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
      "gatewayresponse.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
      "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
    }

    response_templates = {
      "application/json" = "{\"message\":$context.error.messageString}"
    }
  }

  resource "aws_api_gateway_gateway_response" "authorizer_configuration_error" {
    rest_api_id   = aws_api_gateway_rest_api.ipfs_ens_api.id
    response_type = "AUTHORIZER_CONFIGURATION_ERROR"
    status_code   = "500"

    response_parameters = {
      "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
      "gatewayresponse.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
      "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
    }

    response_templates = {
      "application/json" = "{\"message\":$context.error.messageString}"
    }
  }

  resource "aws_api_gateway_gateway_response" "authorizer_failure" {
    rest_api_id   = aws_api_gateway_rest_api.ipfs_ens_api.id
    response_type = "AUTHORIZER_FAILURE"
    status_code   = "500"

    response_parameters = {
      "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
      "gatewayresponse.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
      "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
    }

    response_templates = {
      "application/json" = "{\"message\":$context.error.messageString}"
    }
  }

  resource "aws_api_gateway_gateway_response" "bad_request_parameters" {
    rest_api_id   = aws_api_gateway_rest_api.ipfs_ens_api.id
    response_type = "BAD_REQUEST_PARAMETERS"
    status_code   = "400"

    response_parameters = {
      "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
      "gatewayresponse.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
      "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
    }

    response_templates = {
      "application/json" = "{\"message\":$context.error.messageString}"
    }
  }

  resource "aws_api_gateway_gateway_response" "bad_request_body" {
    rest_api_id   = aws_api_gateway_rest_api.ipfs_ens_api.id
    response_type = "BAD_REQUEST_BODY"
    status_code   = "400"

    response_parameters = {
      "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
      "gatewayresponse.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
      "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
    }

    response_templates = {
      "application/json" = "{\"message\":$context.error.messageString}"
    }
  }

  resource "aws_api_gateway_gateway_response" "default_4xx" {
    rest_api_id   = aws_api_gateway_rest_api.ipfs_ens_api.id
    response_type = "DEFAULT_4XX"

    response_parameters = {
      "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
      "gatewayresponse.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
      "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
    }

    response_templates = {
      "application/json" = "{\"message\":$context.error.messageString}"
    }
  }

  resource "aws_api_gateway_gateway_response" "default_5xx" {
    rest_api_id   = aws_api_gateway_rest_api.ipfs_ens_api.id
    response_type = "DEFAULT_5XX"

    response_parameters = {
      "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
      "gatewayresponse.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
      "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
    }

    response_templates = {
      "application/json" = "{\"message\":$context.error.messageString}"
    }
  }

  resource "aws_api_gateway_gateway_response" "expired_token" {
    rest_api_id   = aws_api_gateway_rest_api.ipfs_ens_api.id
    response_type = "EXPIRED_TOKEN"
    status_code   = "403"

    response_parameters = {
      "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
      "gatewayresponse.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
      "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
    }

    response_templates = {
      "application/json" = "{\"message\":$context.error.messageString}"
    }
  }

  resource "aws_api_gateway_gateway_response" "integration_failure" {
    rest_api_id   = aws_api_gateway_rest_api.ipfs_ens_api.id
    response_type = "INTEGRATION_FAILURE"
    status_code   = "504"

    response_parameters = {
      "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
      "gatewayresponse.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
      "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
    }

    response_templates = {
      "application/json" = "{\"message\":$context.error.messageString}"
    }
  }

  resource "aws_api_gateway_gateway_response" "integration_timeout" {
    rest_api_id   = aws_api_gateway_rest_api.ipfs_ens_api.id
    response_type = "INTEGRATION_TIMEOUT"
    status_code   = "504"

    response_parameters = {
      "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
      "gatewayresponse.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
      "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
    }

    response_templates = {
      "application/json" = "{\"message\":$context.error.messageString}"
    }
  }

  resource "aws_api_gateway_gateway_response" "invalid_api_key" {
    rest_api_id   = aws_api_gateway_rest_api.ipfs_ens_api.id
    response_type = "INVALID_API_KEY"
    status_code   = "403"

    response_parameters = {
      "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
      "gatewayresponse.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
      "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
    }

    response_templates = {
      "application/json" = "{\"message\":$context.error.messageString}"
    }
  }

  resource "aws_api_gateway_gateway_response" "invalid_signature" {
    rest_api_id   = aws_api_gateway_rest_api.ipfs_ens_api.id
    response_type = "INVALID_SIGNATURE"
    status_code   = "403"

    response_parameters = {
      "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
      "gatewayresponse.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
      "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
    }

    response_templates = {
      "application/json" = "{\"message\":$context.error.messageString}"
    }
  }

  resource "aws_api_gateway_gateway_response" "missing_authentication_token" {
    rest_api_id   = aws_api_gateway_rest_api.ipfs_ens_api.id
    response_type = "MISSING_AUTHENTICATION_TOKEN"
    status_code   = "403"

    response_parameters = {
      "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
      "gatewayresponse.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
      "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
    }

    response_templates = {
      "application/json" = "{\"message\":$context.error.messageString}"
    }
  }

  resource "aws_api_gateway_gateway_response" "quota_exceeded" {
    rest_api_id   = aws_api_gateway_rest_api.ipfs_ens_api.id
    response_type = "QUOTA_EXCEEDED"
    status_code   = "429"

    response_parameters = {
      "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
      "gatewayresponse.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
      "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
    }

    response_templates = {
      "application/json" = "{\"message\":$context.error.messageString}"
    }
  }

  resource "aws_api_gateway_gateway_response" "request_too_large" {
    rest_api_id   = aws_api_gateway_rest_api.ipfs_ens_api.id
    response_type = "REQUEST_TOO_LARGE"
    status_code   = "413"

    response_parameters = {
      "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
      "gatewayresponse.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
      "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
    }

    response_templates = {
      "application/json" = "{\"message\":$context.error.messageString}"
    }
  }

  resource "aws_api_gateway_gateway_response" "resource_not_found" {
    rest_api_id   = aws_api_gateway_rest_api.ipfs_ens_api.id
    response_type = "RESOURCE_NOT_FOUND"
    status_code   = "404"

    response_parameters = {
      "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
      "gatewayresponse.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
      "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
    }

    response_templates = {
      "application/json" = "{\"message\":$context.error.messageString}"
    }
  }

  resource "aws_api_gateway_gateway_response" "throttled" {
    rest_api_id   = aws_api_gateway_rest_api.ipfs_ens_api.id
    response_type = "THROTTLED"
    status_code   = "429"

    response_parameters = {
      "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
      "gatewayresponse.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
      "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
    }

    response_templates = {
      "application/json" = "{\"message\":$context.error.messageString}"
    }
  }

  resource "aws_api_gateway_gateway_response" "unauthorized" {
    rest_api_id   = aws_api_gateway_rest_api.ipfs_ens_api.id
    response_type = "UNAUTHORIZED"
    status_code   = "401"

    response_parameters = {
      "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
      "gatewayresponse.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
      "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
    }

    response_templates = {
      "application/json" = "{\"message\":$context.error.messageString}"
    }
  }

  resource "aws_api_gateway_gateway_response" "unsupported_media_type" {
    rest_api_id   = aws_api_gateway_rest_api.ipfs_ens_api.id
    response_type = "UNSUPPORTED_MEDIA_TYPE"
    status_code   = "415"

    response_parameters = {
      "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
      "gatewayresponse.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
      "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
    }

    response_templates = {
      "application/json" = "{\"message\":$context.error.messageString}"
    }
  }

  resource "aws_api_gateway_gateway_response" "waf_filtered" {
    rest_api_id   = aws_api_gateway_rest_api.ipfs_ens_api.id
    response_type = "WAF_FILTERED"
    status_code   = "403"

    response_parameters = {
      "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
      "gatewayresponse.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
      "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
    }

    response_templates = {
      "application/json" = "{\"message\":$context.error.messageString}"
    }
  }

# ---------------------------------------------------------------------------------------------------------------------
# API GATEWAY DOMAIN
# ---------------------------------------------------------------------------------------------------------------------
  resource "aws_api_gateway_domain_name" "domain" {
    certificate_arn = local.api_cert_arn
    domain_name     = local.api_domain

    depends_on = [aws_acm_certificate_validation.api_cert]
  }

  resource "aws_api_gateway_base_path_mapping" "base_path_mapping" {
    api_id = aws_api_gateway_rest_api.ipfs_ens_api.id

    domain_name = aws_api_gateway_domain_name.domain.domain_name
  }

  resource "aws_route53_record" "api" {
    name    = aws_api_gateway_domain_name.domain.domain_name
    type    = "A"
    zone_id = data.aws_route53_zone.hosted_zone.zone_id

    alias {
      evaluate_target_health = true
      name                   = aws_api_gateway_domain_name.domain.cloudfront_domain_name
      zone_id                = aws_api_gateway_domain_name.domain.cloudfront_zone_id
    }
  }

# ---------------------------------------------------------------------------------------------------------------------
# API GATEWAY LAMBDA INVOCATION PERMISSIONS
# ---------------------------------------------------------------------------------------------------------------------
  # Start Deploy API
  resource "aws_lambda_permission" "api_gateway_invoke_start_deploy_lambda" {
    statement_id  = "AllowExecutionFromAPIGateway"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.start_deploy_lambda.function_name
    principal     = "apigateway.amazonaws.com"

    # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
    source_arn = local.api_gateway_source_arn
  }

  resource "aws_lambda_permission" "api_gateway_invoke_token_fetch_lambda" {
    statement_id  = "AllowExecutionFromAPIGateway"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.token_fetch_lambda.function_name
    principal     = "apigateway.amazonaws.com"

    # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
    source_arn = local.api_gateway_source_arn
  }

  resource "aws_lambda_permission" "api_gateway_invoke_token_check_lambda" {
    statement_id  = "AllowExecutionFromAPIGateway"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.token_check_lambda.function_name
    principal     = "apigateway.amazonaws.com"

    # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
    source_arn = local.api_gateway_source_arn
  }

