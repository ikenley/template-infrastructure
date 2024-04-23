#------------------------------------------------------------------------------
# Data Warehouse
#------------------------------------------------------------------------------

/*
Next up
    Redshift
        https://docs.aws.amazon.com/redshift/latest/mgmt/security-server-side-encryption.html
        KMS + Key rotation
            https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-db-encryption.html#working-with-key-rotation
    Require SSL 
        require_SSL parameter to true in the parameter group that is associated with the cluster.
        https://docs.aws.amazon.com/redshift/latest/mgmt/connecting-ssl-support.html
    Security Groups
        5439 Allow bastion host only
    
    S3
        KMS
        IAM policies
        VPC endpoints
            https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints-s3.html
        Enhanced VPC routing
            https://docs.aws.amazon.com/redshift/latest/mgmt/enhanced-vpc-enabling-cluster.html

    IAM
        Creating temporary IAM user credentials
            https://docs.aws.amazon.com/redshift/latest/mgmt/generating-iam-credentials-steps.html

    Logging and monitoring
        Log to S3
            https://docs.aws.amazon.com/redshift/latest/mgmt/db-auditing.html#db-auditing-manage-log-files
        
*/
