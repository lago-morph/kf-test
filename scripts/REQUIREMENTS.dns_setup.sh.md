# DNS Setup Script Requirements

This document was produced by Claude sonnet 4.5 using a less nicely formatted prompt.  This document was then used to generate the `dns_setup.sh` script.

## Script Information
- **Script Name:** `dns_setup.sh`
- **Purpose:** Automate DNS subdomain zone creation across multiple cloud providers

## Functional Overview
Creates a public DNS zone in a cloud provider and returns the nameserver information needed to configure domain delegation at the registrar level.

---

## Arguments

### Required Arguments
- **DOMAIN** (positional argument, position 1)
  - The fully qualified domain name for the DNS zone
  - Example: `sub.example.com`

### Optional Arguments
- **--provider PROVIDER**
  - Specifies the cloud provider to use
  - Valid values: `aws`, `azure`, `gcp`
  - Default: `aws`
  - Example: `dns_setup.sh sub.example.com --provider azure`

---

## Cloud Provider Services

### AWS
- **Service:** Route 53
- **Resource Type:** Public Hosted Zone
- **CLI Tool:** `aws` (AWS CLI)

### Azure
- **Service:** Azure DNS
- **Resource Type:** Public DNS Zone
- **CLI Tool:** `az` (Azure CLI)

### GCP
- **Service:** Cloud DNS
- **Resource Type:** Managed Public Zone
- **CLI Tool:** `gcloud` (Google Cloud SDK)

---

## Pre-requisites Validation

The script must verify that the selected cloud provider's CLI is properly configured before executing any commands.

### AWS Requirements
- **Environment Variables:**
  - `AWS_ACCESS_KEY_ID` (must be set and non-empty)
  - `AWS_SECRET_ACCESS_KEY` (must be set and non-empty)
  - `AWS_DEFAULT_REGION` (must be set and non-empty)
- **CLI Tool:** `aws` command must be available in PATH

### Azure Requirements
- **Authentication:** User must be logged in via `az login`
  - Verify with: `az account show`
- **Subscription:** Active Azure subscription must be set
- **CLI Tool:** `az` command must be available in PATH

### GCP Requirements
- **Authentication:** User must be authenticated via `gcloud auth login`
  - Verify with: `gcloud auth list`
- **Project:** Default project must be configured
  - Verify with: `gcloud config get-value project`
- **CLI Tool:** `gcloud` command must be available in PATH

---

## Expected Behavior

### Successful Execution
1. Validate all pre-requisites for the specified provider
2. Create the DNS zone for the specified domain
3. Retrieve and display nameserver information
4. Provide clear instructions for next steps (registrar configuration)

### Output Information
The script must return:
- **Nameserver Records:** List of nameservers assigned to the DNS zone
- **Next Steps:** Instructions on how to configure these nameservers at the domain registrar
- **Zone Identifier:** Cloud provider-specific zone ID or resource name

### Error Handling
- Exit with informative error messages if:
  - Required CLI tool is not installed
  - Authentication/credentials are not properly configured
  - Required environment variables are missing
  - DNS zone creation fails
  - Invalid provider is specified
  - Domain argument is missing or invalid
- Include usage examples in error messages

---

## Usage Examples

### Basic usage (AWS default):
```bash
dns_setup.sh sub.example.com
```

### Specify provider explicitly:
```bash
dns_setup.sh sub.example.com --provider aws
dns_setup.sh sub.example.com --provider azure
dns_setup.sh sub.example.com --provider gcp
```

### Invalid invocations:
```bash
dns_setup.sh
# Error: Missing required DOMAIN argument

dns_setup.sh sub.example.com --provider digitalocean
# Error: Invalid provider 'digitalocean'. Valid options: aws, azure, gcp
```

---

## Example Output

```
================================
DNS Zone Creation
================================
Domain:      sub.example.com
Provider:    aws
Service:     Route 53
================================

✓ AWS CLI detected
✓ AWS credentials configured
✓ Region set to: us-east-1

Creating DNS zone...
✓ DNS zone created successfully

================================
Nameserver Configuration
================================
Zone ID: Z1234567890ABC

Configure the following NS records at your domain registrar for sub.example.com:

  ns-123.awsdns-12.com
  ns-456.awsdns-45.net
  ns-789.awsdns-78.org
  ns-012.awsdns-01.co.uk

================================
Next Steps
================================
1. Log in to your domain registrar (where example.com is registered)
2. Navigate to DNS settings for example.com
3. Add NS records for 'sub' pointing to the nameservers listed above
4. Wait for DNS propagation (typically 5-60 minutes)
5. Verify delegation with: dig NS sub.example.com

================================
```

---

## Additional Requirements

### Error Handling Standards
- Use `set -euo pipefail` for strict error handling
- Provide actionable error messages with troubleshooting guidance
- Exit with non-zero status codes on failure

### Input Validation
- Verify domain format is valid (basic DNS name validation)
- Check that provider value is one of the three supported options
- Validate all required arguments are present

### Code Quality
- Include usage/help function (triggered by `-h` or `--help`)
- Use clear variable names matching the requirement names
- Include comments explaining provider-specific commands
