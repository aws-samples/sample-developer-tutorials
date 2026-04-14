# DocumentDB: Getting started

Create a DocumentDB cluster, connect to it, insert documents, and query them.

## Source

https://docs.aws.amazon.com/documentdb/latest/developerguide/get-started-guide.html

## Use case

- ID: documentdb/getting-started
- Phase: create
- Complexity: intermediate
- Core actions: docdb:CreateDBCluster, docdb:CreateDBInstance

## What it does

1. Generates a secure password and stores it in Secrets Manager
2. Identifies VPC, subnets, and default security group
3. Creates a DocumentDB subnet group
4. Authorizes inbound access on port 27017
5. Creates a DocumentDB cluster and instance
6. Waits for the instance to become available (~10 minutes)
7. Verifies the cluster endpoint is reachable
8. Cleans up all resources

## Running

```bash
bash documentdb-gs.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash documentdb-gs.sh
```

## Resources created

- Secrets Manager secret (database password)
- DocumentDB subnet group
- Security group rule (port 27017 ingress)
- DocumentDB cluster
- DocumentDB instance
- CloudWatch log group (created automatically)

## Estimated time

- Run: ~14 minutes (instance creation takes ~10 minutes)
- Cleanup: ~5 minutes (instance and cluster deletion)

## Cost

DocumentDB instances are billed per hour. A db.t3.medium instance costs approximately $0.076/hour. Clean up promptly after the tutorial.

## Related docs

- [Getting started with Amazon DocumentDB](https://docs.aws.amazon.com/documentdb/latest/developerguide/get-started-guide.html)
- [Managing Amazon DocumentDB clusters](https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-manage.html)
- [Connecting to an Amazon DocumentDB cluster](https://docs.aws.amazon.com/documentdb/latest/developerguide/connect.html)

---

## Appendix: Generation details

| Field | Value |
|-------|-------|
| Generation date | 2026-04-14 (README regenerated with appendix) |
| Source script | Regenerated from source topic, space-separated subnet IDs, ERR trap |
| Script test result | EXIT 0, 825s, 10 steps, clean teardown |
| Issues encountered | Region not configured (added pre-check); `openssl rand` password contained DocumentDB-illegal characters (switched to safe character set); subnet IDs needed space separation not comma; original used `set -e` (replaced with ERR trap for clean error reporting) |
| Iterations | v1 (original), v2 (region pre-check, password fix), v3 (regenerated from source topic 2026-04-12) |
