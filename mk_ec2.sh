#!/bin/bash
#

source variables

REGION="us-east-1"
KEY_NAME="my-ubuntu-key2"  # Change this to your preferred key name
PRIVATE_KEY_PATH="~/.ssh/${KEY_NAME}.pem"  # Where to save the private key

# Expand tilde to full path
PRIVATE_KEY_PATH="${PRIVATE_KEY_PATH/#\~/$HOME}"

echo "================================"
echo "Creating EC2 Instance"
echo "================================"

# Generate new key pair and save private key locally
echo "Generating new SSH key pair..."
aws ec2 create-key-pair \
  --region $REGION \
  --key-name $KEY_NAME \
  --query 'KeyMaterial' \
  --output text > $PRIVATE_KEY_PATH

# Check if key creation was successful
if [ $? -eq 0 ]; then
  echo "Key pair created: $KEY_NAME"
  echo "Private key saved to: $PRIVATE_KEY_PATH"
  # Set correct permissions on private key (required by SSH)
  chmod 400 $PRIVATE_KEY_PATH
  echo "Private key permissions set to 400"
else
  echo "Error: Key pair may already exist. Delete it first or use a different name."
  exit 1
fi

# Find default VPC
echo "Finding default VPC..."
DEFAULT_VPC_ID=$(aws ec2 describe-vpcs \
  --region $REGION \
  --filters "Name=isDefault,Values=true" \
  --query "Vpcs[0].VpcId" \
  --output text)
echo "Default VPC: $DEFAULT_VPC_ID"

# Find public subnet
echo "Finding public subnet..."
SUBNET_ID=$(aws ec2 describe-subnets \
  --region $REGION \
  --filters "Name=vpc-id,Values=$DEFAULT_VPC_ID" \
            "Name=map-public-ip-on-launch,Values=true" \
  --query "Subnets[0].SubnetId" \
  --output text)
echo "Public Subnet: $SUBNET_ID"

# Get default security group
echo "Getting default security group..."
DEFAULT_SG_ID=$(aws ec2 describe-security-groups \
  --region $REGION \
  --filters "Name=vpc-id,Values=$DEFAULT_VPC_ID" \
            "Name=group-name,Values=default" \
  --query "SecurityGroups[0].GroupId" \
  --output text)
echo "Default Security Group: $DEFAULT_SG_ID"

# Add SSH rule
echo "Adding SSH access rule to security group..."
aws ec2 authorize-security-group-ingress \
  --region $REGION \
  --group-id $DEFAULT_SG_ID \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0 \
  2>/dev/null && echo "SSH rule added" || echo "SSH rule already exists"

# Get Ubuntu 24.04 AMI
echo "Finding latest Ubuntu 24.04 LTS AMI..."
UBUNTU_AMI=$(aws ec2 describe-images \
  --region $REGION \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd*/ubuntu-noble-24.04-amd64-server-*" \
            "Name=state,Values=available" \
  --query "Images | sort_by(@, &CreationDate) | [-1].ImageId" \
  --output text)
echo "Ubuntu AMI: $UBUNTU_AMI"

# Launch instance
echo "Launching EC2 instance..."
INSTANCE_ID=$(aws ec2 run-instances \
  --region $REGION \
  --image-id $UBUNTU_AMI \
  --instance-type t3.medium \
  --key-name $KEY_NAME \
  --subnet-id $SUBNET_ID \
  --security-group-ids $DEFAULT_SG_ID \
  --associate-public-ip-address \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Ubuntu-T3-Medium}]' \
  --query "Instances[0].InstanceId" \
  --output text)

echo "Instance launching: $INSTANCE_ID"
echo "Waiting for instance to get public IP..."

# Wait for public IP (with timeout)
COUNTER=0
MAX_ATTEMPTS=30
PUBLIC_IP=""

while [ $COUNTER -lt $MAX_ATTEMPTS ]; do
  sleep 5
  PUBLIC_IP=$(aws ec2 describe-instances \
    --region $REGION \
    --instance-ids $INSTANCE_ID \
    --query "Reservations[0].Instances[0].PublicIpAddress" \
    --output text)
  
  if [ "$PUBLIC_IP" != "None" ] && [ -n "$PUBLIC_IP" ]; then
    break
  fi
  
  COUNTER=$((COUNTER+1))
  echo "Waiting... (attempt $COUNTER/$MAX_ATTEMPTS)"
done

if [ "$PUBLIC_IP" = "None" ] || [ -z "$PUBLIC_IP" ]; then
  echo "Error: Failed to get public IP address"
  exit 1
fi

echo ""
echo "================================"
echo "Instance Created Successfully!"
echo "================================"
echo "Instance ID: $INSTANCE_ID"
echo "Public IP: $PUBLIC_IP"
echo "Private Key: $PRIVATE_KEY_PATH"
echo ""
echo "Wait a minute for instance to finish initializing, then connect with:"
echo "ssh -i $PRIVATE_KEY_PATH ubuntu@$PUBLIC_IP"
echo "================================"
