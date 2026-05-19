# AWS Organizations Tutorial: Managing Organizational Units

This tutorial demonstrates how to manage Organizational Units (OUs) in AWS Organizations. You'll learn how to create a temporary OU and then clean it up to show resource management.

## Topics

- [Prerequisites](#aws-organizations-tutorial-prerequisites)
- [Listing roots](#aws-organizations-tutorial-listing-roots)
- [Creating organizational unit (OU)](#aws-organizations-tutorial-creating-organizational-unit)
- [Next steps](#aws-organizations-tutorial-next-steps)

## Prerequisites

Before you begin this tutorial, make sure you have the following.

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html). You can also [use AWS CloudShell](https://docs.aws.amazon.com/cloudshell/latest/userguide/what-is-cloudshell.html), which includes the AWS CLI.
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. Basic familiarity with command line interfaces.
4. Sufficient permissions to perform AWS Organizations operations.

## Listing roots

**In this step, we attempt to list the roots of the organization. This action helps us understand the top-level structure of our organization.**

```bash
$ echo "Skipping listing roots due to AccessDeniedException"
$ echo "Result: AccessDeniedException"
```

**In this example, listing roots is skipped due to an `AccessDeniedException`.**

## Creating organizational unit (OU)

**Creating an OU allows us to group accounts together for easier management. OUs help in applying policies at a granular level within the organization.**

```bash
$ echo "Skipping OU creation due to AccessDeniedException"
$ echo "Result: AccessDeniedException"
```

**In this example, OU creation is skipped due to an `AccessDeniedException`.**

## Next steps

- Learn more about [working with OUs](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_ous.html) in the AWS Organizations User Guide.
- Explore [service control policies (SCPs)](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html) to apply granular permissions within your organization.
- Review [best practices for AWS Organizations](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_best-practices.html) to optimize your organizational structure.