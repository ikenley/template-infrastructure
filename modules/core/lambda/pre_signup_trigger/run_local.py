from src.lambda_function import lambda_handler

event = {
    "version": "1",
    "region": "us-east-1",
    "userPoolId": "us-east-1_NjltV12qt",
    "userName": "f6e0232f-6227-4184-be98-750eca887174",
    "callerContext": {
        "awsSdkVersion": "aws-sdk-unknown-unknown",
        "clientId": "3lsgg21f557bs4keaiu7l1aet1",
    },
    "triggerSource": "PreSignUp_SignUp",
    "request": {
        "userAttributes": {"email": "ikenley6+auth@gmail.com"},
        "validationData": None,
    },
    "response": {
        "autoConfirmUser": False,
        "autoVerifyEmail": False,
        "autoVerifyPhone": False,
    },
}

context = {}

lambda_handler(event, context)
