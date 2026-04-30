# Cloudwatch Composite Alarms

An AWS CLI tutorial that demonstrates Cloudwatch operations.

## Running

```bash
bash cloudwatch-composite-alarms.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash cloudwatch-composite-alarms.sh
```

## What it does

1. Publishing metrics
2. Creating metric alarms
3. Creating composite alarm
4. Describing composite alarm

## Resources created

- Composite Alarm
- Metric Alarm
- Metric Data

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI cloudwatch reference](https://docs.aws.amazon.com/cli/latest/reference/cloudwatch/index.html)

