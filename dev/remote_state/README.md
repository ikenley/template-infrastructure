# remote_state

Creates the backend remote state in an S3 bucket. Required from all future 

Requires bootstrapping the state locally before enabling the backend s3.

```sh
# comment out ./main.tf terraform.backend
terraform init
terraform apply
# uncomment ./main.tf terraform.backend and update the bucket name
terraform init
```
