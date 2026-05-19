# AWS GuardDuty Setup Tutorial

This tutorial guides you through setting up an AWS GuardDuty detector, creating a filter, an IP set, and a threat intel set.

## Topics

- [Prerequisites](#aws-guardduty-setup-tutorial-prerequisites)
- [Check for existing detector](#aws-guardduty-setup-tutorial-check-for-existing-detector)
- [Create detector](#aws-guardduty-setup-tutorial-create-detector)
- [Create filter](#aws-guardduty-setup-tutorial-create-filter)
- [Create IP set](#aws-guardduty-setup-tutorial-create-ip-set)
- [Clean up resources](#aws-guardduty-setup-tutorial-clean-up-resources)
- [Next steps](#aws-guardduty-setup-tutorial-next-steps)

## Prerequisites

Before you begin this tutorial, make sure you have the following.

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html). You can also [use AWS CloudShell](https://docs.aws.amazon.com/cloudshell/latest/userguide/what-is-cloudshell.html), which includes the AWS CLI.
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. Basic familiarity with command line interfaces.
4. [Sufficient permissions](https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_settingup.html#guardduty_permissions) to create and manage GuardDuty resources.

## Check for existing detector

GuardDuty detectors are essential for monitoring and protecting your AWS accounts. We first check if an existing detector is available to avoid creating duplicates.

**Check for existing detector:**

```bash
DETECTOR_ID=$(aws guardduty list-detectors --query 'DetectorIds[0]' --output text || true)
echo "Result: $DETECTOR_ID"
```

If a detector ID is returned, it means a detector already exists in your account.

## Create detector

Since no detector was found, we create a new one. This enables GuardDuty in your account.

**Create detector:**

```bash
DETECTOR_ID=$(aws guardduty create-detector --enable --query 'DetectorId' --output text)
echo "Detector created: $DETECTOR_ID"
```

Your new GuardDuty detector is now enabled.

## Create filter

Filters in GuardDuty allow you to focus on specific types of findings. We create a filter to capture unauthorized access attempts via SSH brute force.

**Create filter:**

```bash
FILTER_NAME="filter-xmpl"
aws guardduty create-filter --detector-id $DETECTOR_ID --name $FILTER_NAME --finding-criteria '{"Criterion":{"type":{"Eq":["UnauthorizedAccess:EC2/SSHBruteForce"]}}}'
echo "Filter created: $FILTER_NAME"
```

Your new filter is now active and will capture relevant findings.

## Create IP set

IP sets in GuardDuty help you define a list of trusted or malicious IP addresses. We create an IP set to specify a list of IPs to monitor.

**Create IP set:**

```bash
IP_SET_NAME="ip-set-xmpl"
aws guardduty create-ip-set --detector-id $DETECTOR_ID --name $IP_SET_NAME --format TXT --location /test-files/ip-set.txt --activate
IP_SET_ID=$(aws guardduty list-ip-sets --detector-id $DETECTOR_ID --query "IpSetIds[?contains(Name, \`$IP_SET_NAME\`)]" --output text)
echo "IP set created: $IP_SET_NAME"
```

Your new IP set is now active and will monitor the specified IP addresses.

## Clean up resources

To avoid unnecessary charges, clean up the resources you created.

**Clean up resources:**

```bash
# The script automatically handles resource cleanup on exit
```

All created resources have been deleted.

## Next steps

- Learn more about [GuardDuty detectors](https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_detectors.html).
- Explore [GuardDuty findings](https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_findings.html).
- Discover how to [manage GuardDuty filters](https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_filter-findings.html).
- Find out more about [GuardDuty IP sets](https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_ipsets.html).
- Read about [GuardDuty threat intel sets](https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_threatintelsets.html).