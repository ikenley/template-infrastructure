# Creates an SSH tunnel to private VPC via bastion host and SSM session
# https://aws.amazon.com/premiumsupport/knowledge-center/systems-manager-ssh-vpc-resources/

#AWS_PROFILE=default
#AWS_REGION=us-east-1
# USERNAME=$USERNAME
# MY_ENV=development
EC2_INSTANCE_NAME=ik-dev-core
#KEY_PATH=./secrets/ik-dev-main-bastion-host-ssh-key
KEY_PATH=~/.ssh/ik-dev-main-bastion-host-ssh-key
KEY_PARAM_NAME=/ik/dev/core/nat/ec2-nat-instance/key
SOURCE_PORT=5440
TARGET_HOST_PARAM_NAME=/ik/dev/main-aurora-01/cluster_endpoint
TARGET_PORT=5432

# echo "AWS_PROFILE=$AWS_PROFILE"
# export AWS_PROFILE=$AWS_PROFILE
# echo "AWS_REGION=$AWS_REGION"
# export AWS_REGION=$AWS_REGION
# echo "KEY_PATH=$KEY_PATH"

# Function to fetch SSM parameter
get_parameter () {
  local func_result=$(aws ssm get-parameter --name $1 --with-decryption --query "Parameter.Value" | tr -d '"')
  echo "$func_result"
}

# echo "Fetching host info..."
INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$EC2_INSTANCE_NAME" \
              "Name=instance-state-name,Values=running" \
    --query "Reservations[0].Instances[0].InstanceId" \
    --output text)
echo "INSTANCE_ID=$INSTANCE_ID"

TARGET_HOST=$(get_parameter "$TARGET_HOST_PARAM_NAME")
echo "TARGET_HOST=$TARGET_HOST"

# echo "Fetching key"
# RAW_KEY=$(get_parameter "$KEY_PARAM_NAME")
# chmod 700 $KEY_PATH
# echo "$RAW_KEY" | sed 's/\\n/\n/g' > "$KEY_PATH"
# chmod 400 $KEY_PATH

# echo "Establishing SSH tunnel via..."
#echo "ssh -i $KEY_PATH ec2-user@$INSTANCE_ID -L $SOURCE_PORT:$TARGET_HOST:$TARGET_PORT"
#ssh -i $KEY_PATH ec2-user@$INSTANCE_ID -L $SOURCE_PORT:$TARGET_HOST:$TARGET_PORT
aws ssm start-session \
    --target $INSTANCE_ID \
    --document-name AWS-StartPortForwardingSessionToRemoteHost \
    --parameters '{"host":["'$TARGET_HOST'"],"portNumber":["'$TARGET_PORT'"], "localPortNumber":["'$SOURCE_PORT'"]}'