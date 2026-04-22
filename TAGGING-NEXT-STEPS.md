# SC-6 Resource Tagging — Next Steps

## Status
41 of 70 tutorials have been tagged and tested via the DocBash pipeline.
The tagged scripts are on the `feature/resource-tagging` branch.

## Remaining tutorials (not yet tagged)

These failed in the pipeline due to environment issues (not generation quality):

### VPC limit (run sequentially, not in parallel)
- 002-vpc-gs, 008-vpc-private-servers-gs, 009-vpc-ipam-gs
- 012-transitgateway-gettingstarted, 015-vpc-peering, 047-aws-network-firewall-gs
- 075-aws-database-migration-service-gs

### Timeout (need >10 min, increase TEST_TIMEOUT)
- 025-documentdb-gs, 043-amazon-mq-gs, 001-lightsail-gs

### Interactive prompts (need non-interactive flags added first)
- 019-lambda-gettingstarted (menu selection)
- 040-qbusiness-ica, 045-aws-iam-identity-center-gs (prereq prompts)
- 055-amazon-vpc-lattice-gs, 059-amazon-datazone-gs

### Missing prereqs
- 078-amazon-elastic-container-registry-gs (Docker)
- 035-workspaces-personal (AD directory)

### Script-specific (need manual tagging)
- 005-cloudfront-gettingstarted, 016-opensearch-service-gs
- 033-ses-gs, 034-eks-gs, 037-emr-gs, 038-redshift-serverless
- 053-aws-config-gs, 057-amazon-managed-streaming-for-apache-kafka-gs
- 063-aws-iot-core-gs, 064-amazon-neptune-gs
- 074-amazon-textract-gs, 081-aws-elemental-mediaconnect-gs, 082-amazon-polly-gs

## How to apply remaining tags manually
1. Check out this branch
2. For each tutorial, add `--tags Key=tutorial,Value=<id>` to create commands
3. Use the tagging reference in `doc-bash/agent-instructions.md` rule 3
4. Test with: `echo 'y' | timeout 600 bash tuts/<tutorial>/<script>.sh`
5. Update REVISION-HISTORY.md

## Pipeline improvements for next run
- Run VPC-heavy tutorials sequentially (not 70 in parallel)
- Add non-interactive flags to scripts before tagging
- Increase timeout to 1200s for DocumentDB/MQ/Lightsail
