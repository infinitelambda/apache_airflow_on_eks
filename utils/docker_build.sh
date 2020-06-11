#!/bin/bash

echo "This script assumes that it is ran from the root project directory. If there are any errors being thrown from this script regarding missing files, then make sure that it is ran from the correct directory."

# AWS Profile and Region
PROFILE=<AWS PROFILE>
REGION=<AWS REGION>

# Address of the two ECR repositories that Terraform created
ECR_BASE_URL=<ECR BASE URL>
ECR_DAG_URL=<ECR DAG URL>

# ECR Login in older versions
$(aws ecr get-login --region $REGION --no-include-email --profile $PROFILE)
# ECR Login in newer versions
if [ $? -eq 0 ]; then
  ECR_URL=`for i in $(echo $ECR_BASE_URL | tr "/" "\n")
  do
    echo $i
  done | sed -n 1p`
  aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_URL
fi

docker build -t $ECR_BASE_URL docker/base/
if [ $? -eq 0 ]; then
  docker push $ECR_BASE_URL
fi

docker build -t $ECR_DAG_URL docker/base/
if [ $? -eq 0 ]; then
  docker push $ECR_DAG_URL
fi
