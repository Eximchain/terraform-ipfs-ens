# --------------------------------------------------------
# REQUIRED VARIABLES
# --------------------------------------------------------

variable "github_client_id" {
  description = "Client ID for GitHub OAuth app; publicly visible"
  // TODO: Remove default once we have a value
  default = ""
}

variable "github_client_secret" {
  description = "Client secret for GitHub OAuth app; secret, server-only"
  // TODO: Remove default once we have a value
  default = ""
}

variable "eth_key" {
  description = "Private key for the ETH account which deploys to ENS"
  // TODO: remove default and make required
  default = ""
}

variable "ipfs_endpoint" {
  description = "Endpoint for IPFS requests"
  // TODO: Remove default once we have a value
  default = ""
}

variable "ens_contract_address" {
  description = "Address of ENS contract for registering names"
  // TODO: Remove default once we have a value
  default = ""
}

variable "ens_root_domain" {
  description = "Our root domain which users register under"
  // TODO: Remove default once we have a value
  default = ""
}

variable "default_gas_price" {
  description = "Default amount of gas per txn (2 per registration)"
  // TODO: Remove default once we have a value
  default = ""
}

variable "npm_user" {
  description = "Username for the NPM account which the builder should log into before installing dependencies."
}

variable "npm_pass" {
  description = "Password for the NPM account which the builder should log into before installing dependencies."
}

variable "npm_email" {
  description = "Email for the NPM account which the builder should log into before installing dependencies."
}

# --------------------------------------------------------
# OPTIONAL VARIABLES
# --------------------------------------------------------

variable "aws_region" {
  description = "AWS Region to use"
  default     = "us-east-1"
}

variable "root_domain" {
  description = "Root domain on Route 53 on which to host the API"
  default     = "eximchain-dev.com"
}

variable "subdomain" {
  description = "subdomain on which to host the API. The API DNS will be {subdomain}.{root_domain}"
  default     = "ipfs-api"
}

variable "deployment_website_subdomain" {
  description = "subdomain on which to host the IPFS-ENS Deployment SPA. The IPFS-ENS Deployment SPA will be {ipfs_ens_spa_subdomain}.{root_domain}"
  default     = "ipfs"
}

variable "deployment_website_branch" {
  description = "branch of the 'ipfs-ens-spa' repository to deploy to the IPFS-ENS Deployment SPA"
  default     = "master"
}

variable "existing_cert_domain" {
  description = "The Domain of an existing ACM certificate that is valid for all domains the api or any other single-domain resources. Will provision one if not provided."
  default     = ""
}

variable "lambda_default_branch" {
  description = "Branch to use for Lambda repositories if no override is specified"
  default     = "master"
}

variable "ipfs_ens_lambda_branch_override" {
  description = "An override for the ipfs-ens-lambda repository branch. Will use Lambda default if left blank."
  default     = ""
}

variable "segment_nodejs_write_key" {
  description = "Publishable key to send analytics calls to Segment.io from Lambdas.  Must be set in order to get usage analytics."
  default     = ""
}

variable "segment_browser_write_key" {
  description = "Publishable key to send analytics calls to Segment.io from the browser.  Must be set in order to get usage analytics."
  default     = ""
}

variable "initial_nonces" {
    description = "Mapping from chain name to initial nonce.  Should be set if the key has been used before."
    default     = {
        Ethereum = "0"
    }
}