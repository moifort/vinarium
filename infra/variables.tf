variable "project_id" {
  description = "Globally unique GCP project id (e.g. cave-a-vin-prod)"
  type        = string
}

variable "project_name" {
  description = "Human-readable project name shown in the GCP console"
  type        = string
  default     = "Cave-a-Vin"
}

variable "org_id" {
  description = "GCP organization id (mutually exclusive with folder_id)"
  type        = string
  default     = null
}

variable "folder_id" {
  description = "GCP folder id (mutually exclusive with org_id)"
  type        = string
  default     = null
}

variable "billing_account_id" {
  description = "GCP billing account id (e.g. AAAA-BBBB-CCCC-DDDD)"
  type        = string
}

variable "region" {
  description = "Region for the Cloud Function (Gen 2)"
  type        = string
  default     = "europe-west3"
}

variable "firestore_location" {
  description = "Firestore multi-region or region (e.g. eur3, europe-west3)"
  type        = string
  default     = "eur3"
}

variable "ios_bundle_id" {
  description = "iOS app bundle identifier"
  type        = string
  default     = "com.polyforms.cavevin.app"
}

# Apple Sign-In — all required, comes from Apple Developer
variable "apple_team_id" {
  description = "Apple Developer Team ID (10-char alphanum)"
  type        = string
}

variable "apple_services_id" {
  description = "Apple Sign-In Services ID (acts as OAuth client_id)"
  type        = string
}

variable "apple_key_id" {
  description = "Apple private key ID (10-char alphanum, matches the .p8 filename)"
  type        = string
}

variable "apple_private_key_path" {
  description = "Path to the AuthKey_XXXXXXXXXX.p8 file from Apple Developer"
  type        = string
}

# Backend secrets
variable "anthropic_api_key" {
  description = "Anthropic API key for the wine label scan (Claude Sonnet 4.6)"
  type        = string
  sensitive   = true
}

variable "google_api_key" {
  description = "Google AI API key for scan enrichment (Gemini 2.0 Flash)"
  type        = string
  sensitive   = true
}

variable "sentry_dsn" {
  description = "Sentry DSN for error reporting (empty disables Sentry)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "admin_token" {
  description = "Bearer token guarding /admin/* routes. Auto-generated if null."
  type        = string
  sensitive   = true
  default     = null
}
