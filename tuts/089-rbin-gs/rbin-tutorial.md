# AWS Recycle Bin Tutorial

This tutorial demonstrates how to create, update, and delete an AWS Recycle Bin rule using the AWS CLI. You'll learn how to manage the lifecycle of your EBS snapshots by retaining them for a specified period.

## Topics

- [Prerequisites](#aws-recycle-bin-tutorial-prerequisites)
- [Creating a Recycle Bin rule](#aws-recycle-bin-tutorial-creating-a-recycle-bin-rule)
- [Verifying rule status](#aws-recycle-bin-tutorial-verifying-rule-status)
- [Updating rule retention period](#aws-recycle-bin-tutorial-updating-rule-retention-period)
- [Deleting the rule](#aws-recycle-bin-tutorial-deleting-the-rule)
- [Next steps](#aws-recycle-bin-tutorial-next-steps)

## Prerequisites

Before you begin this tutorial, make sure you have the following.

- The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
- Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
- Basic familiarity with command line interfaces.
- Sufficient permissions to create, update, and delete Recycle Bin rules.

## Creating a Recycle Bin rule

**Creating a Recycle Bin rule**

In this step, we will create a Recycle Bin rule with a retention period of 1 day for EBS snapshots. This rule helps manage the lifecycle of your EBS snapshots by retaining them for a specified period.

```bash
$ RULE_ID=$(aws rbin create-rule --retention-period RetentionPeriodValue=1,RetentionPeriodUnit=DAYS --resource-type EBS_SNAPSHOT --query 'Identifier' --output text)
$ echo "Rule created: $RULE_ID"
```

The rule has been created with the identifier `$RULE_ID`.

## Verifying rule status

**Verifying rule status**

After creating the rule, we need to verify its status to ensure it has been successfully applied. This step confirms that the rule is active and functioning as expected.

```bash
$ aws rbin get-rule --identifier "$RULE_ID" --query 'Status' --output text
```

The status of the rule should indicate that it is active.

## Updating rule retention period

**Updating rule retention period**

Now, we will update the retention period of the Recycle Bin rule to 7 days. Updating the retention period allows you to adjust the lifecycle management of your resources based on changing requirements.

```bash
$ aws rbin update-rule --identifier "$RULE_ID" --retention-period RetentionPeriodValue=7,RetentionPeriodUnit=DAYS
```

The retention period of the rule has been updated to 7 days.

## Deleting the rule

**Deleting the rule**

Finally, we will delete the Recycle Bin rule to clean up resources. Deleting the rule ensures that no unnecessary rules remain in your account, helping maintain a clean and efficient environment.

```bash
$ aws rbin delete-rule --identifier "$RULE_ID" || true
```

The rule has been deleted.

## Next steps

- Learn more about [AWS Recycle Bin](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/recycle-bin.html).
- Explore how to [manage EBS snapshots](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-creating-snapshot.html).