# Getting started with Elastic Load Balancing using the AWS CLI

This tutorial guides you through creating and configuring an Application Load Balancer using the AWS Command Line Interface (AWS CLI). You'll learn how to create a load balancer, configure target groups, register targets, and set up listeners to distribute traffic to your applications.

## Topics

- [Prerequisites](#prerequisites)
- [Create an Application Load Balancer](#create-an-application-load-balancer)
- [Create a target group](#create-a-target-group)
- [Register targets](#register-targets)
- [Create a listener](#create-a-listener)
- [Verify your configuration](#verify-your-configuration)
- [Add an HTTPS listener (optional)](#add-an-https-listener-optional)
- [Add path-based routing (optional)](#add-path-based-routing-optional)
- [Going to production](#going-to-production)
- [Clean up resources](#clean-up-resources)
- [Next steps](#next-steps)

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI installed and configured with appropriate credentials. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
2. EC2 instances running in a VPC with a web server (such as Apache or IIS) installed.
3. Security groups configured to allow HTTP access on port 80 for your instances.
4. At least two subnets in different Availability Zones within your VPC.
5. [Sufficient permissions](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-authentication-access-control.html) to create and manage Elastic Load Balancing resources.

**Cost information**: The resources created in this tutorial will incur charges as long as they exist. The estimated cost for running an Application Load Balancer is approximately $0.0305 per hour, plus any charges for your EC2 instances (approximately $0.0116 per hour per t2.micro instance). The total estimated cost for completing this tutorial (assuming 1 hour with 2 t2.micro instances) is about $0.05. Make sure to follow the cleanup instructions to avoid ongoing charges. For more information about pricing, see [Elastic Load Balancing pricing](https://aws.amazon.com/elasticloadbalancing/pricing/) and [Amazon EC2 pricing](https://aws.amazon.com/ec2/pricing/).

First, verify that your AWS CLI version supports Elastic Load Balancing v2 commands:

```
$ aws elbv2 help
```

If you get an error message, update your AWS CLI to the latest version.

## Create an Application Load Balancer

An Application Load Balancer operates at the application layer (layer 7) and routes traffic based on the content of the request. In this section, you'll create an Application Load Balancer that distributes traffic across multiple EC2 instances.

**Retrieve your VPC and subnet information**

Before creating a load balancer, you need to identify your VPC and subnets. The following commands help you retrieve this information:

```
$ VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text)
$ echo "Using VPC: $VPC_ID"

$ SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[0:2].SubnetId" --output text)
$ read -r SUBNET1 SUBNET2 <<< "$SUBNETS"
$ echo "Using subnets: $SUBNET1 and $SUBNET2"
```

These commands find your default VPC and retrieve two subnets within it. For a production environment, you should select specific subnets in different Availability Zones.

**Create a security group for the load balancer**

Next, create a security group that allows HTTP traffic to your load balancer:

```
$ SECURITY_GROUP_ID=$(aws ec2 create-security-group \
    --group-name "elb-demo-sg" \
    --description "Security group for ELB demo" \
    --vpc-id "$VPC_ID" \
    --query "GroupId" --output text)
$ echo "Created security group: $SECURITY_GROUP_ID"

$ aws ec2 authorize-security-group-ingress \
    --group-id "$SECURITY_GROUP_ID" \
    --protocol tcp \
    --port 80 \
    --cidr "203.0.113.0/24"  # Replace with your specific IP range
```

This security group allows inbound HTTP traffic from a specific IP range. For the tutorial, you can use your own IP address or range. In a production environment, you should restrict this to only the IP ranges that need access to your application.

**Create the load balancer**

Now, create the Application Load Balancer using the subnets and security group:

```
$ LOAD_BALANCER_ARN=$(aws elbv2 create-load-balancer \
    --name "my-load-balancer" \
    --subnets "$SUBNET1" "$SUBNET2" \
    --security-groups "$SECURITY_GROUP_ID" \
    --query "LoadBalancers[0].LoadBalancerArn" --output text)
$ echo "Created load balancer: $LOAD_BALANCER_ARN"
```

This command creates an internet-facing Application Load Balancer in the specified subnets with the security group you created. The load balancer ARN is stored in the `LOAD_BALANCER_ARN` variable for later use.

Wait for the load balancer to become active before proceeding:

```
$ aws elbv2 wait load-balancer-available --load-balancer-arns "$LOAD_BALANCER_ARN"
```

## Create a target group

A target group routes requests to registered targets (such as EC2 instances) using the protocol and port you specify. In this section, you'll create a target group for your Application Load Balancer.

```
$ TARGET_GROUP_ARN=$(aws elbv2 create-target-group \
    --name "my-targets" \
    --protocol HTTP \
    --port 80 \
    --vpc-id "$VPC_ID" \
    --target-type instance \
    --query "TargetGroups[0].TargetGroupArn" --output text)
$ echo "Created target group: $TARGET_GROUP_ARN"
```

This command creates a target group that uses the HTTP protocol on port 80. The target type is set to `instance`, which means you'll register EC2 instances by their instance IDs.

You can customize the health check settings for your target group to better suit your application:

```
$ aws elbv2 modify-target-group \
    --target-group-arn "$TARGET_GROUP_ARN" \
    --health-check-path "/health" \
    --health-check-interval-seconds 15 \
    --healthy-threshold-count 3 \
    --unhealthy-threshold-count 3
```

This command configures the health check to check the `/health` path every 15 seconds and requires 3 consecutive successful or failed checks to change the health status.

## Register targets

After creating a target group, you need to register targets with it. In this section, you'll register EC2 instances with your target group.

First, find available EC2 instances in your VPC:

```
$ INSTANCES=$(aws ec2 describe-instances \
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=instance-state-name,Values=running" \
    --query "Reservations[*].Instances[*].InstanceId" --output text)
```

Then, register the instances with your target group:

```
$ aws elbv2 register-targets \
    --target-group-arn "$TARGET_GROUP_ARN" \
    --targets Id=$INSTANCES
```

Replace the instance IDs with your actual instance IDs. You can register multiple instances at once by specifying multiple `Id` parameters.

## Create a listener

A listener checks for connection requests using the protocol and port you configure. In this section, you'll create an HTTP listener for your load balancer.

```
$ LISTENER_ARN=$(aws elbv2 create-listener \
    --load-balancer-arn "$LOAD_BALANCER_ARN" \
    --protocol HTTP \
    --port 80 \
    --default-actions Type=forward,TargetGroupArn="$TARGET_GROUP_ARN" \
    --query "Listeners[0].ListenerArn" --output text)
$ echo "Created listener: $LISTENER_ARN"
```

This command creates an HTTP listener on port 80 that forwards requests to your target group. The listener ARN is stored in the `LISTENER_ARN` variable for later use.

## Verify your configuration

After setting up your load balancer, target group, and listener, you should verify that everything is working correctly.

**Check target health**

Verify the health of your registered targets:

```
$ aws elbv2 describe-target-health --target-group-arn "$TARGET_GROUP_ARN"
```

This command shows the health status of each registered target. If your targets are healthy, you should see a status of `healthy`. If they're unhealthy, check that your instances are running and that the security groups allow traffic on port 80.

**Troubleshooting unhealthy targets**

If your targets are unhealthy, check the following:

1. Ensure your instances are running and the web server is active
2. Verify that the security group for your instances allows inbound traffic from the load balancer
3. Check that the health check path exists and returns a 200 OK response
4. Review the health check settings to ensure they're appropriate for your application

**Get the load balancer DNS name**

Retrieve the DNS name of your load balancer:

```
$ LB_DNS=$(aws elbv2 describe-load-balancers \
    --load-balancer-arns "$LOAD_BALANCER_ARN" \
    --query "LoadBalancers[0].DNSName" --output text)
$ echo "Load Balancer DNS Name: $LB_DNS"
```

You can use this DNS name to access your application through the load balancer. Open a web browser and enter the DNS name to test your load balancer.

## Add an HTTPS listener (optional)

For secure communication, you can add an HTTPS listener to your load balancer. This requires an SSL/TLS certificate.

**Create or import an SSL certificate**

Before creating an HTTPS listener, you need an SSL certificate. You can create or import a certificate using AWS Certificate Manager (ACM):

```
$ CERTIFICATE_ARN=$(aws acm request-certificate \
    --domain-name example.com \
    --validation-method DNS \
    --query "CertificateArn" --output text)
$ echo "Certificate ARN: $CERTIFICATE_ARN"
```

Replace `example.com` with your domain name. You'll need to complete the domain validation process before using the certificate.

**Create an HTTPS listener**

After obtaining a certificate, create an HTTPS listener:

```
$ aws elbv2 create-listener \
    --load-balancer-arn "$LOAD_BALANCER_ARN" \
    --protocol HTTPS \
    --port 443 \
    --certificates CertificateArn="$CERTIFICATE_ARN" \
    --default-actions Type=forward,TargetGroupArn="$TARGET_GROUP_ARN"
```

This command creates an HTTPS listener on port 443 that uses your SSL certificate and forwards requests to your target group.

## Add path-based routing (optional)

Path-based routing allows you to route requests to different target groups based on the URL path. In this section, you'll create a rule that forwards requests with a specific path pattern to a different target group.

**Create another target group**

First, create a new target group for handling specific paths:

```
$ IMAGE_TARGET_GROUP_ARN=$(aws elbv2 create-target-group \
    --name "my-images" \
    --protocol HTTP \
    --port 80 \
    --vpc-id "$VPC_ID" \
    --query "TargetGroups[0].TargetGroupArn" --output text)
$ echo "Created image target group: $IMAGE_TARGET_GROUP_ARN"
```

**Register targets with the new target group**

Register your instance with the new target group:

```
$ aws elbv2 register-targets \
    --target-group-arn "$IMAGE_TARGET_GROUP_ARN" \
    --targets Id=$INSTANCES
```

**Create a rule for path-based routing**

Create a rule that forwards requests with a specific path pattern to the new target group:

```
$ aws elbv2 create-rule \
    --listener-arn "$LISTENER_ARN" \
    --priority 10 \
    --conditions Field=path-pattern,Values='/img/*' \
    --actions Type=forward,TargetGroupArn="$IMAGE_TARGET_GROUP_ARN"
```

This rule forwards requests with paths that start with `/img/` to your image target group. All other requests are handled by the default action defined in the listener.

## Clean up resources

When you're done with this tutorial, you should clean up the resources you created to avoid incurring charges.

**Delete the listener**

```
$ aws elbv2 delete-listener --listener-arn "$LISTENER_ARN"
```

**Delete the load balancer**

```
$ aws elbv2 delete-load-balancer --load-balancer-arn "$LOAD_BALANCER_ARN"
```

Wait for the load balancer to be deleted:

```
$ aws elbv2 wait load-balancers-deleted --load-balancer-arns "$LOAD_BALANCER_ARN"
```

**Delete the target groups**

```
$ aws elbv2 delete-target-group --target-group-arn "$TARGET_GROUP_ARN"

# If you created an image target group
$ aws elbv2 delete-target-group --target-group-arn "$IMAGE_TARGET_GROUP_ARN"
```

## Going to production

This tutorial is designed to help you learn how to use the Elastic Load Balancing API, not to create a production-ready deployment. Before using these concepts in a production environment, consider the following best practices:

### Security considerations

1. **Use HTTPS instead of HTTP**: Always use HTTPS in production to encrypt data in transit.
2. **Restrict security group rules**: Limit inbound traffic to specific IP ranges or security groups.
3. **Implement AWS WAF**: Consider using AWS WAF with your Application Load Balancer for additional protection against common web exploits.
4. **Enable access logging**: Configure access logs to track requests to your load balancer.

### Reliability and scalability considerations

1. **Use Auto Scaling groups**: Integrate with Auto Scaling to automatically adjust capacity based on demand.
2. **Configure appropriate health checks**: Customize health checks to accurately reflect the health of your application.
3. **Enable cross-zone load balancing**: Ensure traffic is distributed evenly across all Availability Zones.
4. **Set appropriate deregistration delays**: Configure connection draining to allow in-flight requests to complete when instances are deregistered.

### Monitoring considerations

1. **Set up CloudWatch alarms**: Create alarms for key metrics like unhealthy host count and request count.
2. **Enable detailed monitoring**: Consider enabling detailed monitoring for more granular metrics.
3. **Implement request tracing**: Use AWS X-Ray to trace requests through your application.

For more information on building production-ready architectures, refer to:
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)
- [Elastic Load Balancing Best Practices](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers-best-practices.html)


## Next steps

Now that you've learned how to create and configure an Application Load Balancer using the AWS CLI, you might want to explore these related topics:

- [Configure health checks for your target group](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/target-group-health-checks.html)
- [Use sticky sessions with your load balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/sticky-sessions.html)
- [Configure access logs for your load balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html)
- [Monitor your load balancer with CloudWatch](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-cloudwatch-metrics.html)
- [Create a Network Load Balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancer-getting-started.html)
- [Create a Gateway Load Balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/gateway/getting-started.html)
