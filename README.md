# template-infrastructure

Template Terraform scripts for typical AWS web hosting infrastructure.

Each main directory corresponds to a different environment/AWS account, except for the shared `modules` directory. Most actual "work" occurs in the `modules` directory, with the environment directories primarily maintaining state and environment tags.

## Getting Started

1. Install the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html)
2. [Configure an AWS profile](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html) which maps to an IAM CLI user with sufficient privileges (e.g. "terraform" on the associated account): `terraform configure --profile terraform-dev`
3. Install [Terraform CLI](https://www.terraform.io/)

---

## Account Details

### Antigone Development (924586450630)

CIDR=10.0.0.0/18
remote_state_bucket=924586450630-terraform-state

### Antigone Production (TODO)

CIDR=10.0.64.0/18


---

## auth-service TODO

- cognito
    - add google_client_id and google_client_secret to codebuild_tf
- pg credentials
- refactor to load ssm params into env vars
- ci/cd 
- lambda function

```
aws cognito-idp describe-user-pool --user-pool-id us-east-1_47ncTVgu5
aws cognito-idp describe-user-pool-client --user-pool-id us-east-1_47ncTVgu5 --client-id 4l0inln46dnf4plvgjmu9b1523 > client.json
```