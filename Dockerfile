FROM ubuntu:18.04 AS s3-uploader
RUN apt-get update \
    && apt-get install -y curl unzip 
RUN curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf aws awscliv2.zip
COPY ./s3-uploader-action.sh ./s3-uploader-action.sh
# RUN mkdir ~/.aws
# COPY /path/to/aws/credentials/and/config ~/.aws/
COPY /Users/karunapallavi/.aws /root/
CMD chmod +x ./s3-uploader-action.sh && ./s3-uploader-action.sh
