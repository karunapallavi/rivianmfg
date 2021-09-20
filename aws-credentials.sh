#!/bin/bash
# this script sets the env with the correct credentials to perform the required AWS tasks

command -v aws >/dev/null 2>&1   || { echo >&2 "I require aws but it's not installed.  Aborting."; exit 1; }

# This will set the environment with the AWS ACCESS KEY, SECRET and SESSION
# TOKEN of "uploadAssumeRole" Role. This role has limited permissions.  This
# role is set temporarily (for one hour) to perform the upload tasks.
read -r id secret token <<<$(
  aws sts assume-role --role-arn arn:aws:iam::0123456789:role/uploadAssumeRole \
                      --role-session-name unitySetupSession \
                      --duration-seconds 3600 \
                      --query 'Credentials.[AccessKeyId,SecretAccessKey, SessionToken]' \
                      --output text)

# Set env
export AWS_ACCESS_KEY_ID=$id
export AWS_SECRET_ACCESS_KEY=$secret
export AWS_SESSION_TOKEN=$token

# returns the AWS user that is currently being used
aws sts get-caller-identity --query Arn --output text
