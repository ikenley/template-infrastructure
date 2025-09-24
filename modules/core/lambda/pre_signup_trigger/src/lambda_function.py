import json


def lambda_handler(event, context):
    # TODO implement
    print(f"lambda_handler:event:{json.dumps(event)}")
    raise Exception("No invitation exists for this email")
    return event
