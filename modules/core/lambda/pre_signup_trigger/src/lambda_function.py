import json
import os
import boto3


def lambda_handler(event, context):
    print(f"lambda_handler:event:{json.dumps(event)}")

    config = get_conf()
    invitation_table_name = config.get("invitation_table_name")

    # Get invitation by email (if exists)
    email = get_email(event)
    dynamodb_client = boto3.client("dynamodb")
    invitation = get_invitation(dynamodb_client, invitation_table_name, email)

    if invitation is None:
        raise Exception("No invitation exists for this email")

    return event


def get_conf():
    """Get configuration vars"""
    config = {"invitation_table_name": os.environ.get("INVITATION_TABLE_NAME")}
    print(f"config={config}")
    return config


def get_email(event):
    email = event.get("request", {}).get("userAttributes", {}).get("email", None)
    if email is None:
        print(f"Missing email: {email}")
        raise Exception("Missing email")
    return email


def get_invitation(dynamodb_client, invitation_table_name: str, email_address: str):
    partition_key = f"i:{email_address}"
    item = dynamodb_client.get_item(
        Key={
            "hash_key": {
                "S": partition_key,
            },
            "range_key": {
                "S": "i",
            },
        },
        TableName=invitation_table_name,
    )

    print(f"item={json.dumps(item)}")
    return item.get("Item", None)
