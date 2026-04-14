# Kinesis: Process real-time stock data

Create a Kinesis data stream with a Lambda producer that generates stock trades and a Lambda consumer that stores them in DynamoDB.

## Source

https://docs.aws.amazon.com/streams/latest/dev/tutorial-stock-data-kplkcl2.html

## Use case

- ID: kinesis/getting-started
- Phase: create
- Complexity: intermediate
- Core actions: kinesis:CreateStream, kinesis:PutRecord, lambda:CreateEventSourceMapping

## What it does

1. Creates a Kinesis data stream (1 shard)
2. Creates an IAM role with Kinesis, Lambda, and DynamoDB permissions
3. Creates a Python producer Lambda that generates random stock trades
4. Creates a Python consumer Lambda that writes trades to DynamoDB
5. Creates a DynamoDB table (on-demand billing)
6. Connects the stream to the consumer via event source mapping
7. Produces 10 stock trades and verifies they land in DynamoDB
8. Cleans up all resources

## Running

```bash
bash kinesis-data-streams.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash kinesis-data-streams.sh
```

## Resources created

- Kinesis data stream (1 shard)
- IAM role (with Lambda, Kinesis, and DynamoDB policies)
- 2 Lambda functions (Python 3.12): producer and consumer
- DynamoDB table (on-demand)
- Event source mapping
- 2 CloudWatch log groups (created automatically by Lambda)

## Estimated time

- Run: ~2.5 minutes (stream creation takes ~30s, event source mapping activation ~60s)
- Cleanup: ~10 seconds

## Cost

Kinesis: $0.015/shard-hour. DynamoDB: on-demand pricing. Both are negligible for a single tutorial run. Clean up promptly to avoid ongoing Kinesis charges.

## Related docs

- [Tutorial: Process real-time stock data using KPL and KCL](https://docs.aws.amazon.com/streams/latest/dev/tutorial-stock-data-kplkcl2.html)
- [Using Lambda with Kinesis](https://docs.aws.amazon.com/lambda/latest/dg/with-kinesis.html)
- [Amazon Kinesis Data Streams terminology](https://docs.aws.amazon.com/streams/latest/dev/key-concepts.html)

---

## Appendix: Generation details

| Field | Value |
|-------|-------|
| Generation date | 2026-04-14 |
| Source script | Full rewrite from internal 026-kinesis-ds-gs/2-cli-script-v3.sh |
| Script test result | EXIT 0, 185s, 8 steps, clean teardown |
| Issues encountered | Original had hardcoded resource names (fixed with random IDs); python3.9 runtime (upgraded to 3.12); stream name embedded in Lambda code via bash interpolation (fixed with env vars); DynamoDB verification timing — Kinesis event source mapping first poll can take 60s after Enabled state |
| Iterations | v1 (internal, hardcoded), v2 (partial fixes), v3 (internal, still hardcoded), v4 (clean rewrite for publish) |
