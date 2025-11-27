#!/bin/bash

set -e

source variables

AWS_ACCOUNT=$(aws sts get-caller-identity --query "Account" --output text)

mkdir ~/.ssh || echo "~/.ssh already exists"
ssh-keyscan github.com >> ~/.ssh/known_hosts

CRED_JSON=$(aws sts assume-role --role-arn "arn:aws:iam::${AWS_ACCOUNT}:role/KubernetesAdmin" --role-session-name "kubefirst-platform-creation" --duration-seconds 3600)

# doesn't work on cloud sandbox? ## AWS_ACCESS_KEY_ID=$( echo ${CRED_JSON} | jq -r '.Credentials.AccessKeyId')
# doesn't work on cloud sandbox? ## AWS_SECRET_ACCESS_KEY=$( echo ${CRED_JSON} | jq -r '.Credentials.SecretAccessKey')
AWS_SESSION_TOKEN=$( echo ${CRED_JSON} | jq -r '.Credentials.SessionToken')

kubefirst aws create \
      --alerts-email kubefirst@${DOMAIN} \
      --domain-name ${DOMAIN} \
      --cluster-name kubefirst-mgmt \
      --github-org ${GITHUB_ORG}
