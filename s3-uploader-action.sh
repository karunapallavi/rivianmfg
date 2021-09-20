#!/bin/bash

set -o errexit
# set credentials in the env
source aws-credentials.sh
# Add your S3 Bucket URI here. 
aws s3 sync /var/file-writer/data <s3URI>