#!/bin/bash

echo "This script assumes that it is ran from the root project directory. If there are any errors being thrown from this script regarding missing files, then make sure that it is ran from the correct directory."
​
$AWS_REGION=<AWS REGION>

# Address of the Dag ECR repository that Terraform created
ECR_DAG_URL=<ECR DAG URL>

$(aws ecr get-login --region $AWS_REGION --no-include-email)
docker build -t $ECR_DAG_URL:$1 docker/dag/
docker build -t $ECR_DAG_URL:latest docker/dag/
docker push $ECR_DAG_URL:$1
docker push $ECR_DAG_URL:latest
kubectl set image deployment.apps/airflow web=$ECR_DAG_URL:$1 scheduler=$ECR_DAG_URL:$1