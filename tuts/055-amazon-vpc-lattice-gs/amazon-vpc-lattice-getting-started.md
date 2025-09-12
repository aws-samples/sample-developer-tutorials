# Creating and managing a VPC Lattice service network using the AWS CLI

This tutorial guides you through the process of creating and managing an Amazon VPC Lattice service network using the AWS Command Line Interface (AWS CLI). You'll learn how to create a service network, create a service, associate the service with the service network, and associate a VPC with the service network.

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI installed and configured with appropriate credentials. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).

2. Permissions to create and manage VPC Lattice resources. You'll need the following permissions:
   - `vpc-lattice:CreateServiceNetwork`
   - `vpc-lattice:GetServiceNetwork`
   - `vpc-lattice:DeleteServiceNetwork`
   - `vpc-lattice:ListServiceNetworks`
   - `vpc-lattice:CreateService`
   - `vpc-lattice:GetService`
   - `vpc-lattice:DeleteService`
   - `vpc-lattice:ListServices`
   - `vpc-lattice:CreateServiceNetworkServiceAssociation`
   - `vpc-lattice:GetServiceNetworkServiceAssociation`
   - `vpc-lattice:DeleteServiceNetworkServiceAssociation`
   - `vpc-lattice:ListServiceNetworkServiceAssociations`
   - `vpc-lattice:CreateServiceNetworkVpcAssociation`
   - `vpc-lattice:GetServiceNetworkVpcAssociation`
   - `vpc-lattice:DeleteServiceNetworkVpcAssociation`
   - `vpc-lattice:ListServiceNetworkVpcAssociations`
   - `ec2:DescribeVpcs`
   - `ec2:DescribeSecurityGroups`

3. At least one VPC in your account that you can associate with the service network.

4. At least one security group in the VPC that you'll associate with the service network.

5. **Cost Consideration**: Running VPC Lattice resources incurs costs. The estimated cost for running the resources in this tutorial for one hour is approximately $0.15. Make sure to follow the cleanup instructions at the end of the tutorial to avoid ongoing charges.

## Create a service network

A service network in VPC Lattice is a logical boundary for a collection of services. It enables you to organize and manage your services in a structured way.

To create a service network, run the following command:

```
aws vpc-lattice create-service-network --name my-service-network
```

The command returns information about the newly created service network, including its ID, ARN, and name:

```
{
    "arn": "arn:aws:vpc-lattice:us-east-2:123456789012:servicenetwork/sn-abcd1234EXAMPLE",
    "authType": "NONE",
    "id": "sn-abcd1234EXAMPLE",
    "name": "my-service-network"
}
```

Make note of the service network ID, as you'll need it for subsequent steps.

You can verify that the service network was created successfully by running:

```
aws vpc-lattice get-service-network --service-network-identifier sn-abcd1234EXAMPLE
```

Replace `sn-abcd1234EXAMPLE` with your service network ID.

## Create a service

A service in VPC Lattice is an independently deployable unit of software that delivers a specific task or function. Services can run on instances, containers, or as serverless functions.

To create a service, run the following command:

```
aws vpc-lattice create-service --name my-service
```

The command returns information about the newly created service, including its ID, ARN, name, and DNS entry:

```
{
    "arn": "arn:aws:vpc-lattice:us-east-2:123456789012:service/svc-abcd1234EXAMPLE",
    "authType": "NONE",
    "dnsEntry": {
        "domainName": "my-service-abcd1234EXAMPLE.7d67968.vpc-lattice-svcs.us-east-2.on.aws",
        "hostedZoneId": "Z09127221KTH2EXAMPLE"
    },
    "id": "svc-abcd1234EXAMPLE",
    "name": "my-service",
    "status": "ACTIVE"
}
```

Make note of the service ID, as you'll need it for the next step.

You can verify that the service was created successfully by running:

```
aws vpc-lattice get-service --service-identifier svc-abcd1234EXAMPLE
```

Replace `svc-abcd1234EXAMPLE` with your service ID.

## Associate the service with the service network

After creating both a service network and a service, you need to associate them to enable communication between them. This association allows clients in VPCs connected to the service network to make requests to the service.

To associate the service with the service network, run the following command:

```
aws vpc-lattice create-service-network-service-association \
    --service-identifier svc-abcd1234EXAMPLE \
    --service-network-identifier sn-abcd1234EXAMPLE
```

Replace `svc-abcd1234EXAMPLE` with your service ID and `sn-abcd1234EXAMPLE` with your service network ID.

The command returns information about the newly created association, including its ID, ARN, and DNS entry:

```
{
    "arn": "arn:aws:vpc-lattice:us-east-2:123456789012:servicenetworkserviceassociation/snsa-abcd1234EXAMPLE",
    "createdBy": "123456789012",
    "dnsEntry": {
        "domainName": "my-service-abcd1234EXAMPLE.7d67968.vpc-lattice-svcs.us-east-2.on.aws",
        "hostedZoneId": "Z09127221KTH2EXAMPLE"
    },
    "id": "snsa-abcd1234EXAMPLE",
    "status": "CREATE_IN_PROGRESS"
}
```

The association status will initially be `CREATE_IN_PROGRESS`. You can check the status of the association using the following command:

```
aws vpc-lattice get-service-network-service-association \
    --service-network-service-association-identifier snsa-abcd1234EXAMPLE
```

Replace `snsa-abcd1234EXAMPLE` with your service association ID.

Wait until the status changes to `ACTIVE` before proceeding to the next step.

## List available VPCs

Before you can associate a VPC with the service network, you need to identify which VPC you want to use. The following command lists all VPCs in your account:

```
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0]]' --output text
```

The command returns a list of VPC IDs and their names (if they have a Name tag):

```
vpc-abcd1234EXAMPLE    my-vpc
vpc-efgh5678EXAMPLE
```

Make note of the VPC ID that you want to associate with the service network.

## List security groups for the selected VPC

When associating a VPC with a service network, you need to specify at least one security group. The security group controls which resources in the VPC are allowed to access the service network and its services.

To list the security groups for a specific VPC, run the following command:

```
aws ec2 describe-security-groups --filters Name=vpc-id,Values=vpc-abcd1234EXAMPLE \
    --query 'SecurityGroups[*].[GroupId,GroupName]' --output text
```

Replace `vpc-abcd1234EXAMPLE` with your VPC ID.

The command returns a list of security group IDs and their names:

```
sg-abcd1234EXAMPLE    my-security-group
sg-efgh5678EXAMPLE    default
```

Make note of the security group ID that you want to use for the VPC association.

## Associate a VPC with the service network

Associating a VPC with a service network enables all resources within that VPC to be clients and communicate with services in the service network.

To associate a VPC with the service network, run the following command:

```
aws vpc-lattice create-service-network-vpc-association \
    --vpc-identifier vpc-abcd1234EXAMPLE \
    --service-network-identifier sn-abcd1234EXAMPLE \
    --security-group-ids sg-abcd1234EXAMPLE
```

Replace `vpc-abcd1234EXAMPLE` with your VPC ID, `sn-abcd1234EXAMPLE` with your service network ID, and `sg-abcd1234EXAMPLE` with your security group ID.

The command returns information about the newly created association, including its ID, ARN, and status:

```
{
    "arn": "arn:aws:vpc-lattice:us-east-2:123456789012:servicenetworkvpcassociation/snva-abcd1234EXAMPLE",
    "createdBy": "123456789012",
    "id": "snva-abcd1234EXAMPLE",
    "securityGroupIds": [
        "sg-abcd1234EXAMPLE"
    ],
    "status": "CREATE_IN_PROGRESS"
}
```

The association status will initially be `CREATE_IN_PROGRESS`. You can check the status of the association using the following command:

```
aws vpc-lattice get-service-network-vpc-association \
    --service-network-vpc-association-identifier snva-abcd1234EXAMPLE
```

Replace `snva-abcd1234EXAMPLE` with your VPC association ID.

Wait until the status changes to `ACTIVE` before proceeding to the next step.

## View service network details

To view details about your service network, including the number of associated services and VPCs, run the following command:

```
aws vpc-lattice get-service-network --service-network-identifier sn-abcd1234EXAMPLE
```

Replace `sn-abcd1234EXAMPLE` with your service network ID.

The command returns detailed information about the service network:

```
{
    "arn": "arn:aws:vpc-lattice:us-east-2:123456789012:servicenetwork/sn-abcd1234EXAMPLE",
    "authType": "NONE",
    "createdAt": "2025-07-04T04:34:01.369Z",
    "id": "sn-abcd1234EXAMPLE",
    "lastUpdatedAt": "2025-07-04T04:34:01.369Z",
    "name": "my-service-network",
    "numberOfAssociatedServices": 1,
    "numberOfAssociatedVPCs": 1
}
```

## List service associations

To view all services associated with your service network, run the following command:

```
aws vpc-lattice list-service-network-service-associations \
    --service-network-identifier sn-abcd1234EXAMPLE
```

Replace `sn-abcd1234EXAMPLE` with your service network ID.

The command returns a list of service associations:

```
{
    "items": [
        {
            "arn": "arn:aws:vpc-lattice:us-east-2:123456789012:servicenetworkserviceassociation/snsa-abcd1234EXAMPLE",
            "createdAt": "2025-07-04T04:34:16.187Z",
            "createdBy": "123456789012",
            "dnsEntry": {
                "domainName": "my-service-abcd1234EXAMPLE.7d67968.vpc-lattice-svcs.us-east-2.on.aws",
                "hostedZoneId": "Z03318031A60CNV6FMDRB"
            },
            "id": "snsa-abcd1234EXAMPLE",
            "serviceArn": "arn:aws:vpc-lattice:us-east-2:123456789012:service/svc-abcd1234EXAMPLE",
            "serviceId": "svc-abcd1234EXAMPLE",
            "serviceName": "my-service",
            "serviceNetworkArn": "arn:aws:vpc-lattice:us-east-2:123456789012:servicenetwork/sn-abcd1234EXAMPLE",
            "serviceNetworkId": "sn-abcd1234EXAMPLE",
            "serviceNetworkName": "my-service-network",
            "status": "ACTIVE"
        }
    ]
}
```

## List VPC associations

To view all VPCs associated with your service network, run the following command:

```
aws vpc-lattice list-service-network-vpc-associations \
    --service-network-identifier sn-abcd1234EXAMPLE
```

Replace `sn-abcd1234EXAMPLE` with your service network ID.

The command returns a list of VPC associations:

```
{
    "items": [
        {
            "arn": "arn:aws:vpc-lattice:us-east-2:123456789012:servicenetworkvpcassociation/snva-abcd1234EXAMPLE",
            "createdAt": "2025-07-04T05:24:55.312Z",
            "createdBy": "123456789012",
            "id": "snva-abcd1234EXAMPLE",
            "lastUpdatedAt": "2025-07-04T05:25:55.854Z",
            "serviceNetworkArn": "arn:aws:vpc-lattice:us-east-2:123456789012:servicenetwork/sn-abcd1234EXAMPLE",
            "serviceNetworkId": "sn-abcd1234EXAMPLE",
            "serviceNetworkName": "my-service-network",
            "status": "ACTIVE",
            "vpcId": "vpc-abcd1234EXAMPLE"
        }
    ]
}
```

## Troubleshooting

Here are some common issues you might encounter when working with VPC Lattice and how to resolve them:

1. **Resource creation fails**: If resource creation fails, check the error message and ensure you have the necessary permissions. Also, verify that you're using valid parameters.

2. **Association status stuck in CREATE_IN_PROGRESS**: If an association status remains in `CREATE_IN_PROGRESS` for an extended period, there might be an issue with the underlying resources. Try deleting the association and recreating it.

3. **Cannot delete a service network**: Ensure that all associations (service and VPC) are deleted before attempting to delete a service network.

4. **Security group issues**: If you're having connectivity issues, check that your security group allows the necessary traffic. For VPC Lattice, you typically need to allow HTTP (port 80) and HTTPS (port 443) traffic.

5. **Permission denied errors**: Verify that your IAM user or role has the necessary permissions to create and manage VPC Lattice resources.

## Going to production

This tutorial demonstrates the basic functionality of VPC Lattice for educational purposes. When deploying VPC Lattice in a production environment, consider the following best practices:

1. **Authentication and Authorization**: Configure authentication for your service network and services using `authType: "AWS_IAM"` and implement auth policies to control access.

2. **High Availability**: Deploy services across multiple availability zones to ensure high availability.

3. **Monitoring and Logging**: Enable access logs and set up CloudWatch metrics and alarms to monitor your service network.

4. **Security**: Implement least privilege IAM policies and use security groups to restrict access to your service network.

5. **Infrastructure as Code**: Use CloudFormation, CDK, or Terraform to manage your VPC Lattice resources.

For more information on these topics, refer to the following resources:
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)
- [AWS CloudFormation Documentation](https://docs.aws.amazon.com/cloudformation/)

## Clean up resources

When you're finished with the resources created in this tutorial, you should delete them to avoid incurring charges.

1. Delete the VPC association:

```
aws vpc-lattice delete-service-network-vpc-association \
    --service-network-vpc-association-identifier snva-abcd1234EXAMPLE
```

2. Delete the service association:

```
aws vpc-lattice delete-service-network-service-association \
    --service-network-service-association-identifier snsa-abcd1234EXAMPLE
```

3. Delete the service:

```
aws vpc-lattice delete-service --service-identifier svc-abcd1234EXAMPLE
```

4. Delete the service network:

```
aws vpc-lattice delete-service-network --service-network-identifier sn-abcd1234EXAMPLE
```

Make sure to replace all example IDs with your actual resource IDs.

After running each delete command, you can verify that the resource has been deleted by attempting to retrieve it. For example:

```
aws vpc-lattice get-service-network --service-network-identifier sn-abcd1234EXAMPLE
```

If the resource has been successfully deleted, you'll receive a `ResourceNotFoundException` error.

## Next steps

Now that you've learned how to create and manage a VPC Lattice service network, you can explore more advanced features:

- [Create and configure target groups](https://docs.aws.amazon.com/vpc-lattice/latest/ug/target-groups.html) to route traffic to your application targets
- [Define routing with listeners and rules](https://docs.aws.amazon.com/vpc-lattice/latest/ug/listeners.html) to control how traffic is directed to your targets
- [Configure authentication and authorization](https://docs.aws.amazon.com/vpc-lattice/latest/ug/auth-policies.html) to secure access to your services
- [Set up monitoring and logging](https://docs.aws.amazon.com/vpc-lattice/latest/ug/monitoring.html) to gain insights into your service network traffic
- [Share your service network with other AWS accounts](https://docs.aws.amazon.com/vpc-lattice/latest/ug/sharing.html) using AWS Resource Access Manager
