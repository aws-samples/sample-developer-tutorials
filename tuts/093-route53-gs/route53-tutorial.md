# AWS Route53 Tutorial: Creating and Deleting a Hosted Zone

This tutorial demonstrates how to create and delete an AWS Route53 Hosted Zone using the AWS CLI. You will learn how to generate a unique suffix, create a temporary directory for logging, and ensure all resources are cleaned up at the end.

## Topics

- [Prerequisites](#aws-route53-tutorial-prerequisites)
- [Generate a unique suffix](#aws-route53-tutorial-generate-a-unique-suffix)
- [Create a hosted zone](#aws-route53-tutorial-create-a-hosted-zone)
- [Delete the hosted zone](#aws-route53-tutorial-delete-the-hosted-zone)
- [Next steps](#aws-route53-tutorial-next-steps)

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html). You can also [use AWS CloudShell](https://docs.aws.amazon.com/cloudshell/latest/userguide/what-is-cloudshell.html), which includes the AWS CLI.
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. Basic familiarity with command line interfaces.

## Generate a unique suffix

We generate a unique suffix to ensure the hosted zone name is unique. This prevents conflicts with existing hosted zones.

**Generate a unique suffix:**

```bash
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
echo "Generated Suffix: ${SUFFIX}"
```

You should see an output similar to:

```
Generated Suffix: abcd1234
```

## Create a hosted zone

A Hosted Zone in Route53 is a collection of DNS records. Creating a hosted zone allows you to route traffic to your resources using DNS.

**Create a hosted zone:**

```bash
HOSTED_ZONE_ID=$(aws route53 create-hosted-zone --name "example-${SUFFIX}.com." --caller-reference $(date +%s) --query 'HostedZone.Id' --output text)
echo "Created Hosted Zone: ${HOSTED_ZONE_ID}"
```

You should see an output similar to:

```
Created Hosted Zone: /hostedzone/Z123456789ABCDEFGHIJ
```

## Delete the hosted zone

It's important to clean up resources to avoid unnecessary costs and maintain organization. We will now delete the hosted zone we created.

**Delete the hosted zone:**

```bash
aws route53 delete-hosted-zone --id ${HOSTED_ZONE_ID}
echo "Deleted Hosted Zone"
```

You should see an output similar to:

```
Deleted Hosted Zone
```

## Next steps

- Learn more about [working with hosted zones](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/hosted-zones-working-with.html).
- Explore how to [create and manage DNS records](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/rrsets-working-with.html).
- Discover best practices for [managing your Route53 resources](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/best-practices-managing-route53-resources.html).