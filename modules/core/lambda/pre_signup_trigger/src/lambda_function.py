import json


def lambda_handler(event, context):
    # TODO implement
    print(f"lambda_handler:event:{json.dumps(event)}")
    return event
