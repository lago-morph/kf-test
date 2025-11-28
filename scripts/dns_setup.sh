#!/bin/bash

# DNS Setup Script
# Purpose: Automate DNS subdomain zone creation across multiple cloud providers

set -euo pipefail

# Default values
PROVIDER="aws"
DOMAIN=""

# Usage function
usage() {
    cat << EOF
Usage: $(basename "$0") DOMAIN [--provider PROVIDER]

Creates a public DNS zone in a cloud provider and returns nameserver information.

Arguments:
  DOMAIN              The fully qualified domain name for the DNS zone
                      Example: sub.example.com

Options:
  --provider PROVIDER Cloud provider to use (default: aws)
                      Valid values: aws, azure, gcp

Examples:
  $(basename "$0") sub.example.com
  $(basename "$0") sub.example.com --provider aws
  $(basename "$0") sub.example.com --provider azure
  $(basename "$0") sub.example.com --provider gcp

EOF
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        --provider)
            PROVIDER="$2"
            shift 2
            ;;
        -*)
            echo "Error: Unknown option $1"
            usage
            ;;
        *)
            if [[ -z "$DOMAIN" ]]; then
                DOMAIN="$1"
            else
                echo "Error: Unexpected argument $1"
                usage
            fi
            shift
            ;;
    esac
done

# Validate required arguments
if [[ -z "$DOMAIN" ]]; then
    echo "Error: Missing required DOMAIN argument"
    echo ""
    usage
fi

# Basic domain validation
if [[ ! "$DOMAIN" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
    echo "Error: Invalid domain format: $DOMAIN"
    exit 1
fi

# Validate provider
if [[ "$PROVIDER" != "aws" && "$PROVIDER" != "azure" && "$PROVIDER" != "gcp" ]]; then
    echo "Error: Invalid provider '$PROVIDER'. Valid options: aws, azure, gcp"
    exit 1
fi

# Print header
echo "================================"
echo "DNS Zone Creation"
echo "================================"
echo "Domain:      $DOMAIN"
echo "Provider:    $PROVIDER"

case $PROVIDER in
    aws)
        echo "Service:     Route 53"
        ;;
    azure)
        echo "Service:     Azure DNS"
        ;;
    gcp)
        echo "Service:     Cloud DNS"
        ;;
esac

echo "================================"
echo ""

# Validate prerequisites and create DNS zone based on provider
case $PROVIDER in
    aws)
        # Check if AWS CLI is installed
        if ! command -v aws &> /dev/null; then
            echo "Error: AWS CLI is not installed"
            echo "Install it from: https://aws.amazon.com/cli/"
            exit 1
        fi
        echo "✓ AWS CLI detected"

        # Validate AWS credentials
        if [[ -z "${AWS_ACCESS_KEY_ID:-}" ]]; then
            echo "Error: AWS_ACCESS_KEY_ID environment variable is not set"
            echo "Configure AWS credentials before running this script"
            exit 1
        fi

        if [[ -z "${AWS_SECRET_ACCESS_KEY:-}" ]]; then
            echo "Error: AWS_SECRET_ACCESS_KEY environment variable is not set"
            echo "Configure AWS credentials before running this script"
            exit 1
        fi

        if [[ -z "${AWS_DEFAULT_REGION:-}" ]]; then
            echo "Error: AWS_DEFAULT_REGION environment variable is not set"
            echo "Set your default AWS region before running this script"
            exit 1
        fi

        echo "✓ AWS credentials configured"
        echo "✓ Region set to: $AWS_DEFAULT_REGION"
        echo ""

        # Check if zone already exists
        ZONE_ID=$(aws route53 list-hosted-zones --query "HostedZones[?Name=='${DOMAIN}.'].Id" --output text 2>/dev/null | sed 's|/hostedzone/||')

        if [[ -n "$ZONE_ID" ]]; then
            echo "ℹ DNS zone already exists (Zone ID: $ZONE_ID)"
            echo "Retrieving existing nameserver information..."
            echo ""
        else
            # Create DNS zone
            echo "Creating DNS zone..."
            CALLER_REF="dns-setup-$(date +%s)"

            if ! aws route53 create-hosted-zone \
                --name "$DOMAIN" \
                --caller-reference "$CALLER_REF" \
                --hosted-zone-config Comment="Created by dns_setup.sh" \
                --output json > /tmp/zone_output.json 2>&1; then
                echo "Error: Failed to create DNS zone"
                cat /tmp/zone_output.json
                rm -f /tmp/zone_output.json
                exit 1
            fi

            echo "✓ DNS zone created successfully"
            echo ""

            # Get the zone ID of the newly created zone
            ZONE_ID=$(aws route53 list-hosted-zones --query "HostedZones[?Name=='${DOMAIN}.'].Id" --output text | sed 's|/hostedzone/||')

            if [[ -z "$ZONE_ID" ]]; then
                echo "Error: Failed to retrieve Zone ID"
                rm -f /tmp/zone_output.json
                exit 1
            fi

            rm -f /tmp/zone_output.json
        fi

        # Get nameservers for the zone
        NAMESERVERS=$(aws route53 get-hosted-zone --id "$ZONE_ID" --query 'DelegationSet.NameServers' --output text 2>&1 | tr '\t' '\n')

        if [[ -z "$NAMESERVERS" ]]; then
            echo "Error: Failed to retrieve nameservers"
            exit 1
        fi

        # Display nameserver configuration
        echo "================================"
        echo "Nameserver Configuration"
        echo "================================"
        echo "Zone ID: $ZONE_ID"
        echo ""
        echo "Configure the following NS records at your domain registrar for $DOMAIN:"
        echo ""
        echo "$NAMESERVERS" | sed 's/^/  /'
        ;;

    azure)
        # Check if Azure CLI is installed
        if ! command -v az &> /dev/null; then
            echo "Error: Azure CLI is not installed"
            echo "Install it from: https://docs.microsoft.com/cli/azure/install-azure-cli"
            exit 1
        fi
        echo "✓ Azure CLI detected"

        # Check if user is logged in
        if ! az account show &> /dev/null; then
            echo "Error: Not logged in to Azure"
            echo "Run 'az login' to authenticate"
            exit 1
        fi
        echo "✓ Azure authentication verified"

        # Get subscription info
        SUBSCRIPTION=$(az account show --query name -o tsv 2>&1) || {
            echo "Error: Failed to get Azure subscription"
            exit 1
        }
        echo "✓ Active subscription: $SUBSCRIPTION"
        echo ""

        # Create resource group if it doesn't exist
        RESOURCE_GROUP="dns-zones-rg"

        # Ensure resource group exists
        az group create --name "$RESOURCE_GROUP" --location eastus &> /dev/null || true

        # Check if zone already exists
        ZONE_EXISTS=$(az network dns zone show \
            --resource-group "$RESOURCE_GROUP" \
            --name "$DOMAIN" \
            --query id \
            -o tsv 2>/dev/null || echo "")

        if [[ -n "$ZONE_EXISTS" ]]; then
            echo "ℹ DNS zone already exists in resource group: $RESOURCE_GROUP"
            echo "Retrieving existing nameserver information..."
            echo ""
        else
            # Create DNS zone
            echo "Creating DNS zone..."
            if ! az network dns zone create \
                --resource-group "$RESOURCE_GROUP" \
                --name "$DOMAIN" \
                --output json > /tmp/zone_output.json 2>&1; then
                echo "Error: Failed to create DNS zone"
                cat /tmp/zone_output.json
                rm -f /tmp/zone_output.json
                exit 1
            fi

            echo "✓ DNS zone created successfully"
            echo ""

            rm -f /tmp/zone_output.json
        fi

        # Get nameservers
        NAMESERVERS=$(az network dns zone show \
            --resource-group "$RESOURCE_GROUP" \
            --name "$DOMAIN" \
            --query nameServers \
            -o tsv 2>&1)

        if [[ -z "$NAMESERVERS" ]]; then
            echo "Error: Failed to retrieve nameservers"
            exit 1
        fi

        # Display nameserver configuration
        echo "================================"
        echo "Nameserver Configuration"
        echo "================================"
        echo "Resource Group: $RESOURCE_GROUP"
        echo "Zone Name: $DOMAIN"
        echo ""
        echo "Configure the following NS records at your domain registrar for $DOMAIN:"
        echo ""
        echo "$NAMESERVERS" | sed 's/^/  /'
        ;;

    gcp)
        # Check if gcloud CLI is installed
        if ! command -v gcloud &> /dev/null; then
            echo "Error: Google Cloud SDK is not installed"
            echo "Install it from: https://cloud.google.com/sdk/docs/install"
            exit 1
        fi
        echo "✓ gcloud CLI detected"

        # Check if user is authenticated
        if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>&1 | grep -q "@"; then
            echo "Error: Not authenticated with Google Cloud"
            echo "Run 'gcloud auth login' to authenticate"
            exit 1
        fi
        echo "✓ GCP authentication verified"

        # Check if default project is set
        PROJECT=$(gcloud config get-value project 2>&1)
        if [[ -z "$PROJECT" || "$PROJECT" == "(unset)" ]]; then
            echo "Error: No default GCP project configured"
            echo "Run 'gcloud config set project PROJECT_ID' to set a project"
            exit 1
        fi
        echo "✓ Default project: $PROJECT"
        echo ""

        # Create DNS zone
        ZONE_NAME=$(echo "$DOMAIN" | tr '.' '-')

        # Check if zone already exists
        ZONE_EXISTS=$(gcloud dns managed-zones describe "$ZONE_NAME" \
            --format="value(name)" 2>/dev/null || echo "")

        if [[ -n "$ZONE_EXISTS" ]]; then
            echo "ℹ DNS zone already exists (Zone Name: $ZONE_NAME)"
            echo "Retrieving existing nameserver information..."
            echo ""
        else
            # Create DNS zone
            echo "Creating DNS zone..."
            if ! gcloud dns managed-zones create "$ZONE_NAME" \
                --dns-name="$DOMAIN." \
                --description="Created by dns_setup.sh" \
                --visibility=public 2>&1; then
                echo "Error: Failed to create DNS zone"
                exit 1
            fi

            echo "✓ DNS zone created successfully"
            echo ""
        fi

        # Get nameservers
        NAMESERVERS=$(gcloud dns managed-zones describe "$ZONE_NAME" \
            --format="value(nameServers)" 2>&1)

        if [[ -z "$NAMESERVERS" ]]; then
            echo "Error: Failed to retrieve nameservers"
            exit 1
        fi

        # Format nameservers (gcloud returns them in list format or semicolon-separated)
        NAMESERVERS=$(echo "$NAMESERVERS" | tr ';' '\n' | sed 's/^\[//; s/\]$//; s/,/\n/g' | tr -d "'" | tr -d '"' | grep -v '^$')

        # Display nameserver configuration
        echo "================================"
        echo "Nameserver Configuration"
        echo "================================"
        echo "Zone Name: $ZONE_NAME"
        echo "Project: $PROJECT"
        echo ""
        echo "Configure the following NS records at your domain registrar for $DOMAIN:"
        echo ""
        echo "$NAMESERVERS" | sed 's/^/  /'
        ;;
esac

# Common next steps
echo ""
echo "================================"
echo "Next Steps"
echo "================================"

# Extract parent domain
PARENT_DOMAIN=$(echo "$DOMAIN" | sed 's/^[^.]*\.//')

echo "1. Log in to your domain registrar (where $PARENT_DOMAIN is registered)"
echo "2. Navigate to DNS settings for $PARENT_DOMAIN"
echo "3. Add NS records for '$(echo "$DOMAIN" | sed "s/\.$PARENT_DOMAIN//")' pointing to the nameservers listed above"
echo "4. Wait for DNS propagation (typically 5-60 minutes)"
echo "5. Verify delegation with: dig NS $DOMAIN"
echo ""
echo "================================"
