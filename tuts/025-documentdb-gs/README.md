# DocumentDB: Create a cluster and connect

Create an Amazon DocumentDB cluster with encryption, configure network access, and display connection information.

## Source

https://docs.aws.amazon.com/documentdb/latest/developerguide/get-started-guide.html

## Use case

- ID: docdb/getting-started
- Phase: create
- Complexity: intermediate
- Core actions: docdb:CreateDBCluster, docdb:CreateDBInstance

## What it does

1. Generates a secure password and stores it in Secrets Manager
2. Finds the default VPC and subnets across availability zones
3. Creates a DocumentDB subnet group
4. Creates an encrypted DocumentDB cluster
5. Creates a DocumentDB instance (db.t3.medium)
6. Retrieves the cluster endpoint and security group
7. Adds a security group rule for MongoDB access from your IP
8. Downloads the TLS CA certificate
9. Displays connection information (endpoint, mongosh command)
10. Cleans up all resources including the security group rule

## Running

```bash
bash documentdb-gs.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash documentdb-gs.sh
```

## Resources created

- Secrets Manager secret (admin credentials)
- DocumentDB subnet group
- DocumentDB cluster (encrypted)
- DocumentDB instance
- Security group ingress rule (port 27017, your IP only)

## Estimated time

- Run: ~8 minutes (cluster and instance creation)
- Cleanup: ~7 minutes (instance and cluster deletion)

## Cost

DocumentDB instances incur charges while running. The db.t3.medium instance costs approximately $0.08/hour. Cleanup deletes all resources to stop charges.
