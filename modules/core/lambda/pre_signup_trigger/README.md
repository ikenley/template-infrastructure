# pre_signup_trigger

A custom [pre sign-up Lambda trigger](https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-lambda-pre-sign-up.html) which verifies that a user has been invited.

If they are not on an explicit invite list, it rejects the sign-up.
