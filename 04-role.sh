#!/bin/bash

set -e

source variables

AWS_ACCOUNT=$(aws sts get-caller-identity --query "Account" --output text)
AWS_USER_ARN=$(aws sts get-caller-identity | jq -r ".Arn")
AWS_USER_ARN_ESCAPED=$(echo $AWS_USER_ARN | sed -e 's/\//\\\//')
mkdir terraform
cat role.tf.template | sed -e "s/AWS_USER_ARN/${AWS_USER_ARN_ESCAPED}/" > terraform/role.tf
pushd terraform
terraform init
terraform apply --auto-approve
popd
rm -rf terraform

