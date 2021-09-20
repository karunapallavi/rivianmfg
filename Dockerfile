FROM ubuntu:18.04 AS s3-uploader
RUN apt-get update \
    && apt-get install -y curl unzip 

# Install aws cli tool to run the S3 action
RUN curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf aws awscliv2.zip
COPY ./s3-uploader-action.sh ./s3-uploader-action.sh
# Note that the aws credentials need to be in the same working directory as the Dockerfile. 
# or else the COPY command will fail and find no file argument
COPY /path/to/.aws /destination/path/
CMD chmod +x ./s3-uploader-action.sh && ./s3-uploader-action.sh
