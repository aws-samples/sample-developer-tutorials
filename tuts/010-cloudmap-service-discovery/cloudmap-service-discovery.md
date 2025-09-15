# Learn how to use AWS Cloud Map service discovery with the AWS CLI

This tutorial demonstrates how to use AWS Cloud Map service discovery using the AWS Command Line Interface (CLI). You'll create a microservice architecture with two backend services - one discoverable using DNS queries and another discoverable using the AWS Cloud Map API only.

## Prerequisites

Before you begin, make sure you have:

- [Installed and configured](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) the AWS CLI with appropriate permissions
- Completed the steps in [Set up to use AWS Cloud Map](https://docs.aws.amazon.com/cloud-map/latest/dg/setting-up-cloud-map.html)
- Installed the `dig` DNS lookup utility command for DNS verification

## Create an AWS Cloud Map namespace

First, you'll create a public AWS Cloud Map namespace. AWS Cloud Map will create a Amazon Route 53 hosted zone with the same name, enabling service discovery through both DNS records and API calls.

```bash
aws servicediscovery create-public-dns-namespace \
    --name cloudmap-tutorial.com \
    --creator-request-id cloudmap-tutorial-request-1 \
    --region us-east-2
```

The command returns an operation ID that you can use to check the status of the namespace creation:

```json
{
    "OperationId": "gv4g5meo7ndmeh4fqskygvk23d2fijwa-k9xmplyzd"
}
```

Check the operation status to confirm the namespace was created successfully:

```bash
aws servicediscovery get-operation \
    --operation-id gv4g5meo7ndmeh4fqskygvk23d2fijwa-k9xmplyzd \
    --region us-east-2
```

Once the operation is successful, get the namespace ID:

```bash
aws servicediscovery list-namespaces \
    --region us-east-2 \
    --query "Namespaces[?Name=='cloudmap-tutorial.com'].Id" \
    --output text
```

This command returns the namespace ID, which you'll need for subsequent steps:

```
ns-abcd1234xmplefgh
```

## Create the AWS Cloud Map services

Now, create two services within your namespace. The first service will be discoverable using both DNS and API calls, while the second will be discoverable using API calls only.

Create the first service with DNS discovery enabled:

```bash
aws servicediscovery create-service \
    --name public-service \
    --namespace-id ns-abcd1234xmplefgh \
    --dns-config "RoutingPolicy=MULTIVALUE,DnsRecords=[{Type=A,TTL=300}]" \
    --region us-east-2
```

The command returns details about the created service:

```json
{
    "Service": {
        "Id": "srv-abcd1234xmplefgh",
        "Arn": "arn:aws:servicediscovery:us-east-2:123456789012:service/srv-abcd1234xmplefgh",
        "Name": "public-service",
        "NamespaceId": "ns-abcd1234xmplefgh",
        "DnsConfig": {
            "NamespaceId": "ns-abcd1234xmplefgh",
            "RoutingPolicy": "MULTIVALUE",
            "DnsRecords": [
                {
                    "Type": "A",
                    "TTL": 300
                }
            ]
        },
        "CreateDate": 1673613600.000,
        "CreatorRequestId": "public-service-request"
    }
}
```

Create the second service with API-only discovery:

```bash
aws servicediscovery create-service \
    --name backend-service \
    --namespace-id ns-abcd1234xmplefgh \
    --type HTTP \
    --region us-east-2
```

The command returns details about the created service:

```json
{
    "Service": {
        "Id": "srv-ijkl5678xmplmnop",
        "Arn": "arn:aws:servicediscovery:us-east-2:123456789012:service/srv-ijkl5678xmplmnop",
        "Name": "backend-service",
        "NamespaceId": "ns-abcd1234xmplefgh",
        "Type": "HTTP",
        "CreateDate": 1673613600.000,
        "CreatorRequestId": "backend-service-request"
    }
}
```

## Register the AWS Cloud Map service instances

Next, register service instances for each of your services. These instances represent the actual resources that will be discovered.

Register the first instance with an IPv4 address for DNS discovery:

```bash
aws servicediscovery register-instance \
    --service-id srv-abcd1234xmplefgh \
    --instance-id first \
    --attributes AWS_INSTANCE_IPV4=192.168.2.1 \
    --region us-east-2
```

The command returns an operation ID:

```json
{
    "OperationId": "4yejorelbukcjzpnr6tlmrghsjwpngf4-k9xmplyzd"
}
```

Check the operation status to confirm the instance was registered successfully:

```bash
aws servicediscovery get-operation \
    --operation-id 4yejorelbukcjzpnr6tlmrghsjwpngf4-k9xmplyzd \
    --region us-east-2
```

Register the second instance with custom attributes for API discovery:

```bash
aws servicediscovery register-instance \
    --service-id srv-ijkl5678xmplmnop \
    --instance-id second \
    --attributes service-name=backend \
    --region us-east-2
```

The command returns an operation ID:

```json
{
    "OperationId": "7zxcvbnmasdfghjklqwertyuiop1234-k9xmplyzd"
}
```

Check the operation status to confirm the instance was registered successfully:

```bash
aws servicediscovery get-operation \
    --operation-id 7zxcvbnmasdfghjklqwertyuiop1234-k9xmplyzd \
    --region us-east-2
```

## Discover the AWS Cloud Map service instances

Now that you've created and registered your service instances, you can verify everything is working by discovering them using both DNS queries and the AWS Cloud Map API.

First, get the Amazon Route 53 hosted zone ID:

```bash
aws route53 list-hosted-zones-by-name \
    --dns-name cloudmap-tutorial.com \
    --query "HostedZones[0].Id" \
    --output text
```

This returns the hosted zone ID:

```
/hostedzone/Z1234ABCDXMPLEFGH
```

Get the name servers for your hosted zone:

```bash
aws route53 get-hosted-zone \
    --id Z1234ABCDXMPLEFGH \
    --query "DelegationSet.NameServers[0]" \
    --output text
```

This returns one of the name servers:

```
ns-1234.awsdns-12.org
```

Use the `dig` command to query the DNS records for your public service:

```bash
dig @ns-1234.awsdns-12.org public-service.cloudmap-tutorial.com
```

The output should display the IPv4 address you associated with your service:

```
;; ANSWER SECTION:
public-service.cloudmap-tutorial.com. 300 IN A	192.168.2.1
```

Use the AWS CLI to discover the backend service instance:

```bash
aws servicediscovery discover-instances \
    --namespace-name cloudmap-tutorial.com \
    --service-name backend-service \
    --region us-east-2
```

The output displays the attributes you associated with the service:

```json
{
    "Instances": [
        {
            "InstanceId": "second",
            "NamespaceName": "cloudmap-tutorial.com",
            "ServiceName": "backend-service",
            "HealthStatus": "UNKNOWN",
            "Attributes": {
                "service-name": "backend"
            }
        }
    ],
    "InstancesRevision": 71462688285136850
}
```

## Clean up the resources

Once you've completed the tutorial, clean up the resources to avoid incurring charges. AWS Cloud Map requires that you clean them up in reverse order: service instances first, then services, and finally the namespace.

Deregister the first service instance:

```bash
aws servicediscovery deregister-instance \
    --service-id srv-abcd1234xmplefgh \
    --instance-id first \
    --region us-east-2
```

Deregister the second service instance:

```bash
aws servicediscovery deregister-instance \
    --service-id srv-ijkl5678xmplmnop \
    --instance-id second \
    --region us-east-2
```

Delete the public service:

```bash
aws servicediscovery delete-service \
    --id srv-abcd1234xmplefgh \
    --region us-east-2
```

Delete the backend service:

```bash
aws servicediscovery delete-service \
    --id srv-ijkl5678xmplmnop \
    --region us-east-2
```

Delete the namespace:

```bash
aws servicediscovery delete-namespace \
    --id ns-abcd1234xmplefgh \
    --region us-east-2
```

Verify that the Amazon Route 53 hosted zone is deleted:

```bash
aws route53 list-hosted-zones-by-name \
    --dns-name cloudmap-tutorial.com
```

## Next steps

Now that you've learned how to use AWS Cloud Map for service discovery, you can:

- Integrate AWS Cloud Map with your microservices architecture
- Explore health checking options for your service instances
- Use AWS Cloud Map with Amazon ECS or Amazon EKS for container service discovery
- Create private DNS namespaces for internal service discovery within your VPCs

## Security Considerations

This tutorial demonstrates basic AWS CLI usage for educational purposes. For production environments:
- Follow the [AWS Well-Architected Security Pillar](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/)
- Implement least privilege access principles
- Enable appropriate logging and monitoring
- Review and apply security best practices specific to each service used

**Important:** This tutorial does not provide security guidance. Consult AWS security documentation and your security team for production deployments.