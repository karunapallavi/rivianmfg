# Solution 

Pika, I hope this solution here makes your work easier!

## Local setup
Prerequisites: 
- Docker
- minikube
- kubectl 
- aws cli

- Make sure docker is running
-  `minikube start` to get minikube running
- Build the docker image with the Dockerfile provided
`docker build -t s3-uploader:latest .`
- start the deployment
`kubectl apply -f file-writer-deploy.yaml `

## Description
Here in this solution, I've updated the file-writer-deploy.yaml so that the s3upload container also starts up when the file-writer does. So whenever the file-writer starts up and writes into /var/file-writer/data, s3-uploader will sync the same. 

I've also attached a file-writer-pod that can be improved on its end where you will use a common volume between file-writer and s3-uploader containers. 

s3-uploader.sh is run in the container on startup. It uses aws s3 sync to copy over the files to the bucket. sync makes sure that only new files are copied over and any files already existing will not be copied over again and again. 

This little script also uses aws-credentials.sh  which uses existing aws credentials to assume role into an AWS Role that can be used only to perform the s3 sync action. This way you won't need to share the credentials over slack. The Dockerfile specifies that we copy over the aws credentials from localhost. These credentials have access to only perform aws sts actions to assume role. 

In a production environment, you could just attach a Role to the manifest which would make it easy to execute. 

### IAM Role Policy
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:PutObjectAcl"
            ],
            "Resource": "arn:aws:s3:::s3bucketName/*"

        }
    ]
}

### Trust Relationship for the Role
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::1234567890:user/uploadAssumeRole"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}

### User credentials that are copied in Dockerfile - used only to assumeRole 

{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole"
            ],
            "Resource": "*"
        }
    ]
}

### S3 Bucket Policy
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::AccountB:user/AccountBUserName"
            },
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:PutObjectAcl"
            ],
            "Resource": [
                "arn:aws:s3:::AccountABucketName/*"
            ]
        }
    ]
}

There is also a cronjob.yaml that runs on a schedule - twice a day every 12 hours. 
*Assuming* that the first time this is run is at the end of the first shift. 

## Capacity Planning

Ooh this is a fun one. Pika, you mentioned that there is a *large* number of files that would be transferred and requested to understand the local disk needed and also the bandwidth for smooth transfer of data. 

I noticed that there were 5000 files written everytime the file-writer starts up. Found this in the container when I logged in. The directory `/var/file-writer/data` was 65MB for the 5000 files. (du -h) 
*Assuming* it runs once and hour,  and all the files are the same size. You will end up with 5000x12x65 = 3.8GB for half  a day. For the entire day, you'll need about 8GB. 

You would also need about 1GB/s Bandwidth if we are being generous. 

We can improve this by also adding in Auto Scaling features. 

- Need to update Pod template- to accomodate volume config to limit persistant storage that is shared between the two containers. 


## Metrics to be monitored:
- if data is flowing through file-writer: disk space. is the disk filling /var/file-writer/data
- are containers healthy?
- pod status
- Cluster health
- node health
- use prometheus to monitor pod and node performance metrics - send these metrics to grafana to visualize the data
- throughput of the data written by file-writer and the s3-uploader. This will help with scaling. 

## Ideal Architecture:
- You could setup file writer to share a volume that is the S3 bucket. This way you don't have to do a seperate action to write and another one to clear out the local files. You may always access what is needed in S3 and you can store them in several different archival buckets which would store data that would not need much access frequently. This would save some costs as well.
- Similarly you can use EFS to manage a shared data. This can be subject to Auto Scaling as well.
- Use AWS Role for accessing AWS services. 
- Use kubernetes secrets to perform assume role. Although I am not a fan of storing secrets. 
- when the cronjob runs, it cleans up data once every 12 hours. This is *assuming* that there is no data write at that time. 
ideally, we would have the file-writer deployment check to see if there was another service using the file-writer container. If it was, it woud pause its work or come back later to write the data, again assuming that the data is not live data that is flowing into the container and can be cached/ stored until it reaches its destination. 
- you would have the docker image ready in your docker hub or in a private registry that is ready to be pulled and good to go from the box. 