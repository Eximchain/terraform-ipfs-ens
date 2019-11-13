# ---------------------------------------------------------------------------------------------------------------------
# API GATEWAY INITIAL DEPLOYMENT
# ---------------------------------------------------------------------------------------------------------------------
  resource "aws_api_gateway_deployment" "ipfs_ens_api_deploy_v1" {
    depends_on = [
      aws_api_gateway_integration.ipfs_ens_deployments_get,
      aws_api_gateway_method.ipfs_ens_deployments_get,

      aws_api_gateway_integration.ipfs_ens_deployments_proxy_any,
      aws_api_gateway_method.ipfs_ens_deployments_proxy_any,

      aws_api_gateway_integration.ipfs_ens_deployments_cors,
      aws_api_gateway_method.ipfs_ens_deployments_cors,

      aws_api_gateway_integration.ipfs_ens_deployments_proxy_cors,
      aws_api_gateway_method.ipfs_ens_deployments_proxy_cors
    ]

    rest_api_id = aws_api_gateway_rest_api.ipfs_ens_api.id
    stage_name  = "v1"
  }