# feature/resource-tagging-v2

## What's in this branch
All 70 tutorial scripts with resource tagging (69 tagged, 1 SES has no taggable resources).

Tags: Key=project,Value=doc-smith and Key=tutorial,Value={tutorial-id}

## Sources
- 29 from pipeline (tested end-to-end in Fargate)
- 41 fixed locally (syntax-checked + 10 tested locally)

## Local test results (10 light tutorials)
- 7/10 pass: athena, iot-core, kvs, ecr, lambda, step-functions, mediaconnect
- 2 pre-existing bugs (not tagging): cloudwatch-streams (zip), textract (sample doc)
- 1 environment: config (shared bucket conflict)
- 0 tagging-caused failures

## Before publishing
- [x] Rebase off feature/non-interactive
- [x] Local test light tutorials (7/10 pass, 0 tagging bugs)
- [ ] Test medium tutorials locally (VPC-creating, sequential)
- [ ] Fix 032-cloudwatch-streams zip bug (pre-existing)
- [ ] Fix 074-textract sample document (pre-existing)

## After publishing
- [ ] Run full suite in pipeline to verify
- [ ] Test heavy tutorials that need special prereqs
