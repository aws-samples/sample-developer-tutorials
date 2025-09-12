# Creating your first CloudFormation stack using the AWS CLI

This tutorial walks you through creating your first CloudFormation stack using the AWS Command Line Interface (AWS CLI). By following this tutorial, you'll learn how to provision basic AWS resources, monitor stack events, and generate outputs.

**Alternative title:** Getting started with AWS CloudFormation and the AWS CLI

## Topics

- [Prerequisites](#prerequisites)
- [Create a CloudFormation template](#create-a-cloudformation-template)
- [Validate and deploy the template](#validate-and-deploy-the-template)
- [Monitor stack creation](#monitor-stack-creation)
- [View stack resources and outputs](#view-stack-resources-and-outputs)
- [Test the web server](#test-the-web-server)
- [Troubleshoot common issues](#troubleshoot-common-issues)
- [Clean up resources](#clean-up-resources)
- [Going to production](#going-to-production)
- [Next steps](#next-steps)

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. Access to an AWS account with an IAM user or role that has permissions to use Amazon EC2, Amazon S3, and CloudFormation, or administrative user access.
4. A Virtual Private Cloud (VPC) that has access to the internet. This walkthrough requires a default VPC, which comes automatically with newer AWS accounts.

**Time to complete:** Approximately 30 minutes

**Cost estimate:** The resources created in this tutorial will cost approximately $0.0116 per hour for the t2.micro EC2 instance. If you're within your first 12 months of AWS account creation and haven't exhausted your Free Tier benefits, the t2.micro instance would be free (up to 750 hours per month). The tutorial includes cleanup instructions to delete all resources after completion to minimize or eliminate any charges.

## Create a CloudFormation template

CloudFormation uses templates to define the resources you want to provision. In this tutorial, you'll create a template that provisions an EC2 instance running a simple web server and a security group to control access to it.

**Create the template file**

Create a file named `webserver-template.yaml` with the following content:

```yaml
AWSTemplateFormatVersion: 2010-09-09
Description: CloudFormation Template for WebServer with Security Group and EC2 Instance

Parameters:
  LatestAmiId:
    Description: The latest Amazon Linux 2023 AMI from the Parameter Store
    Type: 'AWS::SSM::Parameter::Value<AWS::EC2::Image::Id>'
    Default: '/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64'

  InstanceType:
    Description: WebServer EC2 instance type
    Type: String
    Default: t2.micro
    AllowedValues:
      - t3.micro
      - t2.micro
    ConstraintDescription: must be a valid EC2 instance type.

  MyIP:
    Description: Your IP address in CIDR format (e.g. 203.0.113.1/32).
    Type: String
    MinLength: '9'
    MaxLength: '18'
    Default: 0.0.0.0/0
    AllowedPattern: '^(\d{1,3}\.){3}\d{1,3}/\d{1,2}$'
    ConstraintDescription: must be a valid IP CIDR range of the form x.x.x.x/x.

Resources:
  WebServerSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Allow HTTP access via my IP address
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: !Ref MyIP

  WebServer:
    Type: AWS::EC2::Instance
    Properties:
      ImageId: !Ref LatestAmiId
      InstanceType: !Ref InstanceType
      SecurityGroupIds:
        - !Ref WebServerSecurityGroup
      UserData: !Base64 |
        #!/bin/bash
        dnf update -y
        dnf install -y httpd
        systemctl start httpd
        systemctl enable httpd
        echo "<html><body><h1>Hello World!</h1></body></html>" > /var/www/html/index.html

Outputs:
  WebsiteURL:
    Value: !Join
      - ''
      - - http://
        - !GetAtt WebServer.PublicDnsName
    Description: Website URL
```

This template defines a simple web server infrastructure with the following components:

- **Parameters**: Values that can be passed to the template when creating the stack, including the AMI ID, instance type, and your IP address.
- **Resources**: The AWS resources to create, including a security group that allows HTTP access from your IP address and an EC2 instance running Apache HTTP Server.
- **Outputs**: Values that are returned after the stack is created, including the URL of the web server.

Note that we're using Amazon Linux 2023, the latest version of Amazon Linux, which includes several improvements over Amazon Linux 2.

## Validate and deploy the template

Before deploying your template, it's a good practice to validate it to ensure it's correctly formatted and doesn't contain any errors.

**Validate the template**

Run the following command to validate your template:

```bash
aws cloudformation validate-template --template-body file://webserver-template.yaml
```

If the template is valid, you'll see output showing the parameters defined in the template. If there are any errors, the command will display error messages to help you fix them.

**Get your public IP address**

To restrict access to your web server, you'll need to specify your public IP address. Run the following command to get your IP address:

```bash
MY_IP=$(curl -s https://checkip.amazonaws.com)
MY_IP="${MY_IP}/32"
echo "Your public IP address: $MY_IP"
```

This command retrieves your public IP address and formats it with a `/32` suffix, which in CIDR notation means a single IP address.

**Create the CloudFormation stack**

Now you can create the stack using the AWS CLI:

```bash
aws cloudformation create-stack \
  --stack-name MyTestStack \
  --template-body file://webserver-template.yaml \
  --parameters \
    ParameterKey=InstanceType,ParameterValue=t2.micro \
    ParameterKey=MyIP,ParameterValue="$MY_IP"
```

The command returns a stack ID, which is the Amazon Resource Name (ARN) that uniquely identifies the stack. It will look something like this:

```json
{
    "StackId": "arn:aws:cloudformation:us-east-2:123456789012:stack/MyTestStack/abcd1234-56a0-11f0-96d7-02f9abcd1234"
}
```

## Monitor stack creation

After you create the stack, CloudFormation begins creating the resources specified in the template. You can monitor the progress of the stack creation using the AWS CLI.

**Check stack status**

To check the status of your stack, run the following command:

```bash
aws cloudformation describe-stacks --stack-name MyTestStack
```

The output includes detailed information about the stack, including its status. Look for the `StackStatus` field, which will be `CREATE_IN_PROGRESS` while the stack is being created.

**View stack events**

To see detailed events during the stack creation process, run:

```bash
aws cloudformation describe-stack-events --stack-name MyTestStack
```

This command returns a list of events in reverse chronological order, with the most recent events first. You'll see events for the start of the stack creation process and for the beginning and completion of the creation of each resource.

**Wait for stack creation to complete**

You can use the `wait` command to pause execution until the stack creation is complete:

```bash
aws cloudformation wait stack-create-complete --stack-name MyTestStack
```

This command doesn't produce any output but will return only when the stack creation is complete or has failed.

## View stack resources and outputs

Once the stack is created, you can view the resources that were created and the outputs that were generated.

**List stack resources**

To see the resources created by the stack, run:

```bash
aws cloudformation list-stack-resources --stack-name MyTestStack
```

The output will show the logical ID, physical ID, type, and status of each resource in the stack. It will look something like this:

```
--------------------------------------------------------------------------
|                           ListStackResources                           |
+------------------------+-------------------+---------------------------+
|        LogicalID       |      Status       |           Type            |
+------------------------+-------------------+---------------------------+
|  WebServer             |  CREATE_COMPLETE  |  AWS::EC2::Instance       |
|  WebServerSecurityGroup|  CREATE_COMPLETE  |  AWS::EC2::SecurityGroup  |
+------------------------+-------------------+---------------------------+
```

**Get stack outputs**

To retrieve the outputs from the stack, including the WebsiteURL, run:

```bash
aws cloudformation describe-stacks --stack-name MyTestStack --query "Stacks[0].Outputs"
```

The output will include the WebsiteURL, which you'll use to access your web server:

```json
[
    {
        "OutputKey": "WebsiteURL",
        "OutputValue": "http://ec2-203-0-113-75.us-east-2.compute.amazonaws.com",
        "Description": "Website URL"
    }
]
```

You can extract just the WebsiteURL value using this command:

```bash
WEBSITE_URL=$(aws cloudformation describe-stacks --stack-name MyTestStack --query "Stacks[0].Outputs[?OutputKey=='WebsiteURL'].OutputValue" --output text)
echo "WebsiteURL: $WEBSITE_URL"
```

## Test the web server

Now that your stack is created and you have the WebsiteURL, you can test the web server.

**Access the web server**

Open a web browser and navigate to the WebsiteURL you obtained in the previous step. You should see a simple "Hello World!" message displayed in the browser.

You can also test the connection using the command line:

```bash
curl -s $WEBSITE_URL
```

This command should return the HTML content of the web page:

```html
<html><body><h1>Hello World!</h1></body></html>
```

If the web server isn't responding immediately, wait a few minutes for the EC2 instance to finish initializing and for the Apache HTTP Server to start.

## Troubleshoot common issues

If you encounter issues during the stack creation or when accessing the web server, here are some common problems and solutions.

**No default VPC available**

The template in this walkthrough requires a default VPC. If your stack creation fails because of VPC or subnet availability errors, you might not have a default VPC in your account. You have the following options:

1. Create a new default VPC:

```bash
aws ec2 create-default-vpc
```

2. Modify the template to specify a subnet. Add the following parameter to the template:

```yaml
SubnetId:
  Description: The subnet ID to launch the instance into
  Type: AWS::EC2::Subnet::Id
```

Then, update the `WebServer` resource to include the subnet ID:

```yaml
WebServer:
  Type: AWS::EC2::Instance
  Properties:
    ImageId: !Ref LatestAmiId
    InstanceType: !Ref InstanceType
    SecurityGroupIds:
      - !Ref WebServerSecurityGroup
    SubnetId: !Ref SubnetId
    UserData: !Base64 |
      #!/bin/bash
      dnf update -y
      dnf install -y httpd
      systemctl start httpd
      systemctl enable httpd
      echo "<html><body><h1>Hello World!</h1></body></html>" > /var/www/html/index.html
```

When creating the stack, you'll need to specify a subnet that has internet access:

```bash
# List available subnets
aws ec2 describe-subnets --query "Subnets[*].{SubnetId:SubnetId,VpcId:VpcId,AvailabilityZone:AvailabilityZone,CidrBlock:CidrBlock}"

# Create stack with subnet specified
aws cloudformation create-stack \
  --stack-name MyTestStack \
  --template-body file://webserver-template-with-subnet.yaml \
  --parameters \
    ParameterKey=InstanceType,ParameterValue=t2.micro \
    ParameterKey=MyIP,ParameterValue="$MY_IP" \
    ParameterKey=SubnetId,ParameterValue=subnet-1234abcd
```

## Clean up resources

To avoid incurring charges for resources you no longer need, you should delete the stack and its resources.

**Delete the stack**

Run the following command to delete the stack:

```bash
aws cloudformation delete-stack --stack-name MyTestStack
```

This command doesn't produce any output. To verify that the stack is being deleted, you can check its status:

```bash
aws cloudformation describe-stacks --stack-name MyTestStack
```

The `StackStatus` field will show `DELETE_IN_PROGRESS` while the stack is being deleted.

**Wait for stack deletion to complete**

You can use the `wait` command to pause execution until the stack deletion is complete:

```bash
aws cloudformation wait stack-delete-complete --stack-name MyTestStack
```

Once the stack is deleted, the `describe-stacks` command will return an error indicating that the stack doesn't exist, which confirms it has been successfully deleted.

**Clean up local files**

Finally, you can remove the template file you created:

```bash
rm -f webserver-template.yaml
```

## Going to production

This tutorial is designed to help you learn the basics of AWS CloudFormation using the AWS CLI. The architecture and configuration used in this tutorial are intentionally simple and are not suitable for production environments. If you're planning to deploy a similar solution in a production environment, consider the following improvements:

### Security Improvements

1. **Use HTTPS instead of HTTP**
   - Set up HTTPS using AWS Certificate Manager
   - Configure the security group to allow traffic on port 443
   - Redirect HTTP traffic to HTTPS

2. **Implement proper IAM roles**
   - Create an IAM role for the EC2 instance with least-privilege permissions
   - Use IAM roles instead of access keys for AWS service access

3. **Enhance network security**
   - Use private subnets for instances that don't need direct internet access
   - Implement network ACLs for additional network security
   - Consider using AWS WAF to protect against common web exploits

### Architecture Improvements

1. **Implement high availability**
   - Deploy instances across multiple Availability Zones
   - Use an Application Load Balancer to distribute traffic
   - Implement Auto Scaling to handle varying loads

2. **Add monitoring and logging**
   - Set up Amazon CloudWatch for monitoring and alerting
   - Configure CloudWatch Logs for centralized logging
   - Implement AWS X-Ray for distributed tracing

3. **Optimize for performance and cost**
   - Use Amazon CloudFront for content delivery
   - Consider using Amazon S3 for static content
   - Implement caching strategies

For more information on building production-ready architectures, refer to:

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)
- [AWS Architecture Center](https://aws.amazon.com/architecture/)

## Next steps

Congratulations! You've successfully created a CloudFormation stack, monitored its creation, and used its output. Here are some suggestions for continuing your CloudFormation journey:

1. Learn more about templates so that you can create your own. For more information, see [Working with CloudFormation templates](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-guide.html).
2. Explore [CloudFormation template parameters](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/parameters-section-structure.html) to make your templates more flexible and reusable.
3. Learn about [CloudFormation resource attributes](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-product-attribute-reference.html) to control resource behavior and dependencies.
4. Discover how to use [CloudFormation change sets](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-changesets.html) to preview and manage stack updates.
5. Explore [CloudFormation stack policies](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/protect-stack-resources.html) to protect resources from unintended updates or deletions.
