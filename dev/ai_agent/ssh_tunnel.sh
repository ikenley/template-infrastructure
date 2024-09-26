# Creates an SSH tunnel to private VPC via bastion host and SSM session
# https://aws.amazon.com/premiumsupport/knowledge-center/systems-manager-ssh-vpc-resources/

EC2_INSTANCE_NAME=ik-dev-core-nat-ec2-nat-instance
KEY_PATH=~/.ssh/ik-dev-main-bastion-host-ssh-key
KEY_PARAM_NAME="/ik/dev/core/nat/ec2-nat-instance/key"
INSTANCE_PARAM_NAME='/ik/dev/core/nat_instance_id'
SOURCE_PORT="5444"
TARGET_HOST="ik-dev-ai-agent-rds-writer.ikenley.com"
TARGET_PORT="5432"

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
INSTANCE_ID=$(get_parameter "$INSTANCE_PARAM_NAME")
echo "INSTANCE_ID=$INSTANCE_ID"

echo "Fetching key"
RAW_KEY=$(get_parameter "$KEY_PARAM_NAME")
chmod 700 $KEY_PATH
echo "$RAW_KEY" | sed 's/\\n/\n/g' > "$KEY_PATH"
chmod 400 $KEY_PATH

# echo "Establishing SSH tunnel via..."
echo "ssh -i $KEY_PATH ec2-user@$INSTANCE_ID -L $SOURCE_PORT:$TARGET_HOST:$TARGET_PORT"
ssh -i $KEY_PATH ec2-user@$INSTANCE_ID -L $SOURCE_PORT:$TARGET_HOST:$TARGET_PORT