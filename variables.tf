# --------------------------------------------------------
# REQUIRED VARIABLES
# --------------------------------------------------------

variable "eth_key" {
  description = "Private key for the ETH account which deploys to ENS"
  // TODO remove and make required
  default = ""
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