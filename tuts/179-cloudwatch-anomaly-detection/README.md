# Cloudwatch Anomaly Detection

An AWS CLI tutorial that demonstrates Cloudwatch operations.

## Running

```bash
bash cloudwatch-anomaly-detection.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash cloudwatch-anomaly-detection.sh
```

## What it does

1. Publishing baseline metrics
2. Creating anomaly detector
3. Creating anomaly detection alarm
4. Describing alarm

## Resources created

- Anomaly Detector
- Metric Alarm
- Metric Data

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI cloudwatch reference](https://docs.aws.amazon.com/cli/latest/reference/cloudwatch/index.html)

