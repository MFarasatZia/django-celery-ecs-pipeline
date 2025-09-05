#!/bin/bash
set -ex

SERVICE_NAME=$1
FILE_NAME=$2
REPO_NAME=$3
CLUSTER_NAME=$4

IMAGE_URI="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$REPO_NAME:latest"

TASKDEF_NAME=$(aws ecs list-task-definitions | jq --raw-output '.taskDefinitionArns[] | select(contains("'${SERVICE_NAME}'"))' | tail -n1)
CURRENT_TASKDEF=$(aws ecs describe-task-definition --task-definition $TASKDEF_NAME)
CURRENT_TASKDEF_CONTAINERDEF=$(echo $CURRENT_TASKDEF | jq --raw-output ".taskDefinition.containerDefinitions")
TASKDEF_ROLE_ARN=$(echo $CURRENT_TASKDEF | jq --raw-output ".taskDefinition.taskRoleArn")
EXECUTION_ROLE_ARN=$(echo $CURRENT_TASKDEF | jq --raw-output ".taskDefinition.executionRoleArn")

TASKDEF=$(echo $CURRENT_TASKDEF_CONTAINERDEF | jq ' [ .[] |  .image = "'${IMAGE_URI}'" ]')

CPU=$(echo $CURRENT_TASKDEF | jq -r '.taskDefinition.cpu')
MEMORY=$(echo $CURRENT_TASKDEF | jq -r '.taskDefinition.memory')
NETWORK_MODE=$(echo $CURRENT_TASKDEF | jq -r '.taskDefinition.networkMode')
REQUIRES_COMPATIBILITIES=$(echo $CURRENT_TASKDEF | jq '.taskDefinition.requiresCompatibilities[]' | tr '\n' ',' | sed 's/.$//')

echo '{"family": "'${SERVICE_NAME}'", "taskRoleArn": "'${TASKDEF_ROLE_ARN}'", "executionRoleArn": "'${EXECUTION_ROLE_ARN}'", "containerDefinitions": '$TASKDEF', "cpu": "'$CPU'", "memory": "'$MEMORY'", "requiresCompatibilities": ['$REQUIRES_COMPATIBILITIES'], "networkMode": "'${NETWORK_MODE}'" }' > $FILE_NAME

NEW_TASKDEF_ARN=$(aws ecs register-task-definition --cli-input-json file://$FILE_NAME | jq -r '.taskDefinition.taskDefinitionArn')

aws ecs update-service \
  --cluster $CLUSTER_NAME \
  --service $SERVICE_NAME \
  --task-definition $NEW_TASKDEF_ARN \
  --region $AWS_DEFAULT_REGION \
  --health-check-grace-period-seconds 300
