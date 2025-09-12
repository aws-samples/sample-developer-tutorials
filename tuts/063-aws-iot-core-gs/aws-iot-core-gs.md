# Getting started with AWS IoT Core using the AWS CLI

This tutorial guides you through the process of setting up AWS IoT Core and connecting a device to send and receive MQTT messages using the AWS Command Line Interface (AWS CLI). You'll create the necessary AWS IoT resources, configure your device, and test the connection using the MQTT client.

## Prerequisites

Before you begin this tutorial, you need:

- An AWS account with permissions to create AWS IoT resources
- The AWS CLI installed and configured with your credentials
- Python 3.7 or later installed on your computer
- Git installed on your computer
- Basic familiarity with the command line interface

**Time to complete:** Approximately 20-30 minutes

**Cost:** The resources you create in this tutorial will incur minimal costs (less than $0.01) as long as you complete the cleanup steps. AWS IoT Core charges for connectivity, messaging, and operations, but the usage in this tutorial falls well within the free tier limits for most accounts.

If you haven't installed the AWS CLI yet, see [Installing or updating the latest version of the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).

If you haven't configured the AWS CLI yet, see [Configuring the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html).

## Create AWS IoT resources

In this section, you'll create the AWS IoT resources that a device requires to connect to AWS IoT Core and exchange messages.

### Create an AWS IoT policy

First, you'll create an AWS IoT policy that defines the permissions for your device. The policy allows your device to connect to AWS IoT Core, publish messages to a specific topic, and subscribe to that topic.

Create a policy document file named `iot-policy.json` with the following content:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iot:Connect"
      ],
      "Resource": [
        "arn:aws:iot:REGION:ACCOUNT_ID:client/test-*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "iot:Publish",
        "iot:Receive"
      ],
      "Resource": [
        "arn:aws:iot:REGION:ACCOUNT_ID:topic/test/topic"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "iot:Subscribe"
      ],
      "Resource": [
        "arn:aws:iot:REGION:ACCOUNT_ID:topicfilter/test/topic"
      ]
    }
  ]
}
```

Replace `REGION` with your AWS Region (e.g., us-east-1) and `ACCOUNT_ID` with your AWS account ID. You can get your account ID by running:

```bash
aws sts get-caller-identity --query Account --output text
```

Now create the policy using the AWS CLI:

```bash
aws iot create-policy --policy-name MyIoTPolicy --policy-document file://iot-policy.json
```

The command returns information about the newly created policy, including its Amazon Resource Name (ARN).

### Create a thing object

Next, create a thing object in the AWS IoT registry. A thing represents your device in AWS IoT.

```bash
aws iot create-thing --thing-name MyIoTThing
```

The command returns the thing name, thing ARN, and thing ID:

```json
{
    "thingName": "MyIoTThing",
    "thingArn": "arn:aws:iot:us-east-1:123456789012:thing/MyIoTThing",
    "thingId": "abcd1234-a554-49b1-9451-ed468f11ce6c"
}
```

### Create a certificate and attach it to your thing

Now, create a certificate for your device. The certificate will be used to authenticate your device when it connects to AWS IoT Core.

First, create a directory to store your certificates and set appropriate permissions:

```bash
mkdir -p ~/certs
chmod 700 ~/certs
```

Then, create the certificate and save the files to the directory:

```bash
aws iot create-keys-and-certificate \
  --set-as-active \
  --certificate-pem-outfile ~/certs/device.pem.crt \
  --public-key-outfile ~/certs/public.pem.key \
  --private-key-outfile ~/certs/private.pem.key
```

This command generates a certificate and key pair, and saves them to the specified files. It also returns the certificate ARN and ID in the output:

```json
{
    "certificateArn": "arn:aws:iot:us-east-1:123456789012:cert/abcd1234bb44639a3ffc4335ea7d804d82ac2b8d6a91aa4d368993779bc1028b",
    "certificateId": "abcd1234bb44639a3ffc4335ea7d804d82ac2b8d6a91aa4d368993779bc1028b",
    "certificatePem": "-----BEGIN CERTIFICATE-----\n...\n-----END CERTIFICATE-----\n",
    "keyPair": {
        "PublicKey": "-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----\n",
        "PrivateKey": "-----BEGIN RSA PRIVATE KEY-----\n...\n-----END RSA PRIVATE KEY-----\n"
    }
}
```

Save the certificate ARN for use in the next steps:

```bash
CERTIFICATE_ARN="arn:aws:iot:us-east-1:123456789012:cert/abcd1234bb44639a3ffc4335ea7d804d82ac2b8d6a91aa4d368993779bc1028b"
```

Attach the policy to the certificate:

```bash
aws iot attach-policy \
  --policy-name MyIoTPolicy \
  --target $CERTIFICATE_ARN
```

Attach the certificate to the thing:

```bash
aws iot attach-thing-principal \
  --thing-name MyIoTThing \
  --principal $CERTIFICATE_ARN
```

### Download the Amazon Root CA certificate

Your device needs the Amazon Root CA certificate to verify the AWS IoT server certificate when it connects. Download the certificate:

```bash
curl -o ~/certs/Amazon-root-CA-1.pem https://www.amazontrust.com/repository/AmazonRootCA1.pem
```

Verify that the file was downloaded successfully:

```bash
ls -la ~/certs/Amazon-root-CA-1.pem
```

## Configure your device

In this tutorial, we'll use your computer as an IoT device. You'll need to install the AWS IoT Device SDK for Python.

### Install the AWS IoT Device SDK for Python

First, install the AWS IoT Device SDK for Python using pip:

```bash
python3 -m pip install awsiotsdk
```

Then, clone the AWS IoT Device SDK for Python repository to get the sample applications:

```bash
cd ~
git clone https://github.com/aws/aws-iot-device-sdk-python-v2.git
```

## Run the sample application

Now you're ready to run a sample application that connects to AWS IoT Core and exchanges MQTT messages.

### Get your AWS IoT endpoint

First, get your AWS IoT endpoint:

```bash
aws iot describe-endpoint --endpoint-type iot:Data-ATS
```

The command returns your endpoint:

```json
{
    "endpointAddress": "abcd1234xmpl-ats.iot.us-east-1.amazonaws.com"
}
```

Save the endpoint address for use in the next step:

```bash
IOT_ENDPOINT="abcd1234xmpl-ats.iot.us-east-1.amazonaws.com"
```

### Run the sample application

Now run the sample application that publishes and subscribes to MQTT messages:

```bash
cd ~/aws-iot-device-sdk-python-v2/samples
python3 pubsub.py \
  --endpoint $IOT_ENDPOINT \
  --ca_file ~/certs/Amazon-root-CA-1.pem \
  --cert ~/certs/device.pem.crt \
  --key ~/certs/private.pem.key
```

The sample application:
1. Connects to AWS IoT Core
2. Subscribes to the topic "test/topic"
3. Publishes 10 messages to that topic
4. Displays the messages it receives

You should see output similar to:

```
Connected!
Subscribing to topic 'test/topic'...
Subscribed with QoS.AT_LEAST_ONCE
Sending 10 message(s)
Publishing message to topic 'test/topic': Hello World! [1]
Received message from topic 'test/topic': b'"Hello World! [1]"'
Publishing message to topic 'test/topic': Hello World! [2]
Received message from topic 'test/topic': b'"Hello World! [2]"'
...
10 message(s) received.
Disconnecting...
Disconnected!
```

If you encounter any issues, you can add the `--verbosity Debug` parameter to see more detailed output:

```bash
python3 pubsub.py \
  --endpoint $IOT_ENDPOINT \
  --ca_file ~/certs/Amazon-root-CA-1.pem \
  --cert ~/certs/device.pem.crt \
  --key ~/certs/private.pem.key \
  --verbosity Debug
```

## View MQTT messages in the AWS IoT console

You can also view the messages in the AWS IoT console:

1. Open the AWS IoT console at https://console.aws.amazon.com/iot/
2. In the left navigation pane, choose **Test** and then **MQTT test client**
3. In the **Subscribe to a topic** tab, enter "test/topic" in the Topic filter field
4. Click **Subscribe**

Now run the sample application again, and you'll see the messages appear in the MQTT test client in the console.

## Try shared subscriptions (optional)

AWS IoT Core supports Shared Subscriptions for both MQTT 3 and MQTT 5. This allows multiple clients to share a subscription to a topic with only one client receiving each message.

### Create a policy for shared subscriptions

Create a policy document file named `shared-sub-policy.json` with the following content:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iot:Connect"
      ],
      "Resource": [
        "arn:aws:iot:REGION:ACCOUNT_ID:client/test-*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "iot:Publish",
        "iot:Receive"
      ],
      "Resource": [
        "arn:aws:iot:REGION:ACCOUNT_ID:topic/test/topic"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "iot:Subscribe"
      ],
      "Resource": [
        "arn:aws:iot:REGION:ACCOUNT_ID:topicfilter/test/topic",
        "arn:aws:iot:REGION:ACCOUNT_ID:topicfilter/$share/*/test/topic"
      ]
    }
  ]
}
```

Replace `REGION` and `ACCOUNT_ID` as you did earlier. Note that we're using `client/test-*` instead of `client/*` to follow the principle of least privilege.

Create the policy:

```bash
aws iot create-policy \
  --policy-name SharedSubPolicy \
  --policy-document file://shared-sub-policy.json
```

Attach the policy to your certificate:

```bash
aws iot attach-policy \
  --policy-name SharedSubPolicy \
  --target $CERTIFICATE_ARN
```

### Run the shared subscription example

Run the shared subscription example:

```bash
cd ~/aws-iot-device-sdk-python-v2/samples
python3 mqtt5_shared_subscription.py \
  --endpoint $IOT_ENDPOINT \
  --ca_file ~/certs/Amazon-root-CA-1.pem \
  --cert ~/certs/device.pem.crt \
  --key ~/certs/private.pem.key \
  --group_identifier consumer
```

This will create a publisher and two subscribers sharing the same subscription. You'll see messages being distributed between the two subscribers.

## Clean up resources

When you're done with this tutorial, you should clean up the resources you created to avoid incurring any charges.

First, detach the policies from the certificate:

```bash
aws iot detach-policy --policy-name MyIoTPolicy --target $CERTIFICATE_ARN
aws iot detach-policy --policy-name SharedSubPolicy --target $CERTIFICATE_ARN
```

Detach the certificate from the thing:

```bash
aws iot detach-thing-principal --thing-name MyIoTThing --principal $CERTIFICATE_ARN
```

Update the certificate status to INACTIVE:

```bash
CERTIFICATE_ID=$(echo $CERTIFICATE_ARN | cut -d/ -f2)
aws iot update-certificate --certificate-id $CERTIFICATE_ID --new-status INACTIVE
```

Delete the certificate:

```bash
aws iot delete-certificate --certificate-id $CERTIFICATE_ID
```

Delete the thing:

```bash
aws iot delete-thing --thing-name MyIoTThing
```

Delete the policies:

```bash
aws iot delete-policy --policy-name MyIoTPolicy
aws iot delete-policy --policy-name SharedSubPolicy
```

## Going to production

This tutorial is designed to help you learn how AWS IoT Core works, not to build a production-ready application. When moving to a production environment, consider the following best practices:

### Security best practices

1. **Use more restrictive policies**: Limit permissions to specific clients and topics. Avoid using wildcards in resource ARNs.

2. **Implement certificate rotation**: Regularly rotate certificates to minimize the impact of compromised credentials.

3. **Use AWS IoT Device Defender**: Monitor and audit your IoT devices for security issues.

4. **Protect private keys**: Store private keys securely and use proper file permissions.

5. **Implement device authorization**: Use custom authorizers or AWS IoT Core's built-in authorization features.

For more information, see [AWS IoT Security Best Practices](https://docs.aws.amazon.com/iot/latest/developerguide/security-best-practices.html).

### Scalability best practices

1. **Use fleet provisioning**: For managing multiple devices, use fleet provisioning templates instead of manually creating certificates.

2. **Implement IoT Rules**: Process and route messages at scale using IoT Rules.

3. **Use Device Shadows**: Manage device state efficiently with Device Shadows.

4. **Optimize message payloads**: Keep message sizes small and use efficient encoding.

5. **Implement message batching**: Batch messages when appropriate to reduce connection overhead.

For more information, see [AWS IoT Core Quotas](https://docs.aws.amazon.com/iot/latest/developerguide/limits-iot.html) and [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/).

## Next steps

Now that you've successfully connected a device to AWS IoT Core and exchanged MQTT messages, you can explore more advanced features:

- [Working with rules for AWS IoT](https://docs.aws.amazon.com/iot/latest/developerguide/iot-rules.html) - Learn how to route messages to other AWS services
- [Working with device shadows](https://docs.aws.amazon.com/iot/latest/developerguide/iot-device-shadows.html) - Learn how to store and retrieve device state
- [Device provisioning](https://docs.aws.amazon.com/iot/latest/developerguide/iot-provision.html) - Learn how to provision devices at scale
- [Device Defender](https://docs.aws.amazon.com/iot/latest/developerguide/device-defender.html) - Learn how to audit and monitor your IoT devices for security issues
- [Message Quality of Service in AWS IoT](https://docs.aws.amazon.com/iot/latest/developerguide/mqtt.html#mqtt-qos) - Learn about MQTT QoS levels and how they affect message delivery reliability
