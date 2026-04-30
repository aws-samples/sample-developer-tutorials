# IoT Device Defender: Getting started

Set up AWS IoT Device Defender audit, run an on-demand audit, and review the findings.

## Source

https://docs.aws.amazon.com/iot/latest/developerguide/device-defender-tutorial.html

## Use case

- ID: iot-device-defender/getting-started
- Phase: create
- Complexity: intermediate
- Core actions: iot:CreateScheduledAudit, iot:StartOnDemandAuditTask, iot:DescribeAuditTask

## What it does

1. Creates an IAM role for IoT Device Defender
2. Configures audit settings with the role
3. Starts an on-demand audit
4. Waits for the audit to complete
5. Retrieves and displays audit findings
6. Cleans up audit configuration, role, and policies

## Running

```bash
bash aws-iot-device-defender-gs.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash aws-iot-device-defender-gs.sh
```

## Resources created

- IAM role (with IoT Device Defender audit permissions)
- IoT audit configuration
- On-demand audit task

## Estimated time

- Run: ~2 minutes (audit takes ~60 seconds)
- Cleanup: ~10 seconds

## Cost

No additional charges for IoT Device Defender audit. Standard IoT pricing applies.

## Related docs

- [Getting started with AWS IoT Device Defender](https://docs.aws.amazon.com/iot/latest/developerguide/device-defender-tutorial.html)
- [Audit checks](https://docs.aws.amazon.com/iot/latest/developerguide/device-defender-audit-checks.html)
- [AWS IoT Device Defender detect](https://docs.aws.amazon.com/iot/latest/developerguide/device-defender-detect.html)
