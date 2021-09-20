#!/bin/bash

set -o errexit
source aws-credentials.sh
aws s3 sync /var/file-writer/data <s3URI>