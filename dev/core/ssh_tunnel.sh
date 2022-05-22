# Creates an SSH tunnel to private VPC via bastion host and SSM session
# https://aws.amazon.com/premiumsupport/knowledge-center/systems-manager-ssh-vpc-resources/

#AWS_PROFILE=default
#AWS_REGION=us-east-1
# USERNAME=$USERNAME
# MY_ENV=development
EC2_INSTANCE_NAME=ik-dev-main-bastion-host
KEY_PATH=$HOME/.ssh/ik-dev-main-bastion-host-ssh-key

# echo "AWS_PROFILE=$AWS_PROFILE"
# export AWS_PROFILE=$AWS_PROFILE
# echo "AWS_REGION=$AWS_REGION"
# export AWS_REGION=$AWS_REGION
# echo "KEY_PATH=$KEY_PATH"

# # Function to fetch SSM parameter
# get_parameter () {
#   local func_result=$(aws ssm get-parameter --name $1 --with-decryption --query "Parameter.Value" | tr -d '"')
#   echo "$func_result"
# }

# echo "Fetching host info..."
# INSTANCE_ID=$(get_parameter "//bastion-host\instance-id")
# echo "INSTANCE_ID=$INSTANCE_ID"
# LOCAL_PORT=$(get_parameter "//todo\port-forwarding-number")
# echo "LOCAL_PORT=$LOCAL_PORT"
# DB_INSTANCE_ADDRESS=$(get_parameter "//\db-instance-address")
# echo "DB_INSTANCE_ADDRESS=$DB_INSTANCE_ADDRESS"

INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=$EC2_INSTANCE_NAME" \
  --output text --query 'Reservations[*].Instances[*].InstanceId')
echo INSTANCE_ID=$INSTANCE_ID

# echo "Establishing SSH tunnel via..."
# -L $LOCAL_PORT:$DB_INSTANCE_ADDRESS:5432"
echo "ssh -i $KEY_PATH ec2-user@$INSTANCE_ID"
ssh -i $KEY_PATH ec2-user@$INSTANCE_ID