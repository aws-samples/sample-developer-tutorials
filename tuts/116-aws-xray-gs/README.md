# X-Ray: Send traces and query them

Send trace segments to AWS X-Ray, query trace summaries, retrieve full traces, create a trace group, and view the service graph.

## Source

https://docs.aws.amazon.com/xray/latest/devguide/xray-api-sendingdata.html

## Use case

- **ID**: xray/getting-started
- **Level**: intermediate
- **Core actions**: `xray:PutTraceSegments`, `xray:GetTraceSummaries`, `xray:BatchGetTraces`, `xray:CreateGroup`

## Steps

1. Send a trace segment and subsegment
2. Get trace summaries
3. Get full trace details
4. Create a trace group with a filter expression
5. Get the service graph

## Resources created

| Resource | Type |
|----------|------|
| `tut-group-<random>` | X-Ray group |

## Duration

~10 seconds

## Cost

No charge. X-Ray provides a free tier of 100,000 traces recorded and 1,000,000 traces scanned per month.

## Related docs

- [Sending trace data to X-Ray](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-sendingdata.html)
- [Retrieving trace data](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-gettingdata.html)
- [Using groups in X-Ray](https://docs.aws.amazon.com/xray/latest/devguide/xray-console-groups.html)
- [AWS X-Ray pricing](https://aws.amazon.com/xray/pricing/)

---

## Appendix

| Field | Value |
|-------|-------|
| Date | 2026-04-14 |
| Script lines | 87 |
| Exit code | 0 |
| Runtime | 10s |
| Steps | 5 |
| Issues | Fixed parent_id extraction quoting |
| Version | v1 |
