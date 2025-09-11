# Getting started with Amazon MQ for ActiveMQ using the AWS CLI and Secrets Manager

This tutorial guides you through creating an Amazon MQ for ActiveMQ broker and connecting a Java application to it using the AWS CLI. You'll also learn how to securely manage broker credentials using AWS Secrets Manager, which is a best practice for production environments.

## Prerequisites

Before you begin, make sure you have:

1. **AWS CLI installed and configured** - If you haven't already, install the AWS CLI and configure it with your credentials. For installation instructions, see [Installing the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).

2. **Java Development Kit (JDK)** - You need Java 11 or later installed to run the sample application.

3. **Maven** - You need Maven to build the sample Java application.

4. **Required permissions** - Ensure your AWS user has permissions to create and manage Amazon MQ resources, AWS Secrets Manager secrets, and modify security groups.

5. **Estimated time to complete**: 30-40 minutes (including broker creation time)

6. **Estimated cost**: Running an Amazon MQ broker with a mq.t3.micro instance type costs approximately $0.068 per hour. AWS Secrets Manager costs $0.40 per secret per month and $0.05 per 10,000 API calls. The total cost for completing this tutorial should be less than $0.10 if you delete the resources immediately after completion. For the most up-to-date pricing information, see [Amazon MQ Pricing](https://aws.amazon.com/amazon-mq/pricing/) and [AWS Secrets Manager Pricing](https://aws.amazon.com/secrets-manager/pricing/).

## Step 1: Store broker credentials in AWS Secrets Manager

First, let's create a secure password and store it in AWS Secrets Manager:

```bash
# Generate a random identifier for resource names
RANDOM_ID=$(LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | fold -w 8 | head -n 1)
BROKER_NAME="mq-broker-${RANDOM_ID}"
SECRET_NAME="mq-broker-creds-${RANDOM_ID}"

# Generate a secure password with special characters, numbers, uppercase and lowercase letters
MQ_PASSWORD=$(LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^&*()_+' < /dev/urandom | fold -w 20 | head -n 1)
MQ_USERNAME="mqadmin"

# Create a JSON document with the credentials
CREDENTIALS_JSON="{\"username\":\"$MQ_USERNAME\",\"password\":\"$MQ_PASSWORD\"}"

# Store the credentials in AWS Secrets Manager
SECRET_RESULT=$(aws secretsmanager create-secret \
  --name "$SECRET_NAME" \
  --description "Amazon MQ broker credentials for $BROKER_NAME" \
  --secret-string "$CREDENTIALS_JSON")

# Extract secret ARN
SECRET_ARN=$(echo "$SECRET_RESULT" | grep -o '"ARN": "[^"]*' | cut -d'"' -f4)
echo "Secret created successfully. ARN: $SECRET_ARN"
```

This creates a secret in AWS Secrets Manager containing the username and password for your Amazon MQ broker. Using Secrets Manager provides several benefits:

- Credentials are stored securely and encrypted
- You can rotate credentials automatically
- You can control access to credentials using IAM policies
- You can audit access to credentials

## Step 2: Create an Amazon MQ broker

Now, create a single-instance Amazon MQ broker with the ActiveMQ engine:

```bash
# Create the broker using the credentials from the previous step
BROKER_RESULT=$(aws mq create-broker \
  --broker-name "$BROKER_NAME" \
  --engine-type ACTIVEMQ \
  --engine-version 5.18 \
  --host-instance-type mq.t3.micro \
  --deployment-mode SINGLE_INSTANCE \
  --authentication-strategy SIMPLE \
  --users "Username=$MQ_USERNAME,Password=$MQ_PASSWORD,ConsoleAccess=true" \
  --publicly-accessible \
  --auto-minor-version-upgrade)

# Extract broker ID
BROKER_ID=$(echo "$BROKER_RESULT" | grep -o '"BrokerId": "[^"]*' | cut -d'"' -f4)
echo "Broker creation initiated. Broker ID: $BROKER_ID"
```

This command creates a broker with the following configuration:
- Name: A unique name with a random identifier
- Engine: ActiveMQ version 5.18
- Instance type: mq.t3.micro (suitable for development)
- Deployment mode: Single-instance (not highly available)
- Authentication: Simple authentication with the username and password stored in Secrets Manager
- Public accessibility: Enabled (for easy access in this tutorial)

## Step 3: Wait for the broker to be in RUNNING state

The broker creation process takes about 15-20 minutes. You can check the status with the following command:

```bash
# Check broker status
aws mq describe-broker --broker-id "$BROKER_ID" --query 'BrokerState' --output text
```

Wait until the status shows `RUNNING` before proceeding to the next step.

## Step 4: Get broker connection details

Once the broker is running, retrieve its connection details:

```bash
# Get broker details
BROKER_DETAILS=$(aws mq describe-broker --broker-id "$BROKER_ID")

# Extract web console URL
WEB_CONSOLE=$(aws mq describe-broker --broker-id "$BROKER_ID" --query 'BrokerInstances[0].ConsoleURL' --output text)

# Extract wire-level endpoint for OpenWire
WIRE_ENDPOINT=$(aws mq describe-broker --broker-id "$BROKER_ID" --query 'BrokerInstances[0].Endpoints[0]' --output text)

echo "Web Console URL: $WEB_CONSOLE"
echo "Wire-level Endpoint: $WIRE_ENDPOINT"
```

## Step 5: Configure security group for the broker

To connect to your broker, you need to configure its security group to allow inbound connections:

```bash
# Get the security group ID associated with your broker
SECURITY_GROUP_ID=$(aws mq describe-broker --broker-id "$BROKER_ID" --query 'SecurityGroups[0]' --output text)

# Get current IP address
CURRENT_IP=$(curl -s https://checkip.amazonaws.com)

# Allow inbound connections to the web console (port 8162)
aws ec2 authorize-security-group-ingress \
  --group-id "$SECURITY_GROUP_ID" \
  --protocol tcp \
  --port 8162 \
  --cidr "${CURRENT_IP}/32"

# Allow inbound connections to the OpenWire endpoint (port 61617)
aws ec2 authorize-security-group-ingress \
  --group-id "$SECURITY_GROUP_ID" \
  --protocol tcp \
  --port 61617 \
  --cidr "${CURRENT_IP}/32"
```

These commands add rules to the security group to allow connections from your current IP address to the web console (port 8162) and the OpenWire endpoint (port 61617).

## Step 6: Create a Java application to connect to the broker

Now, let's create a Java application that connects to your Amazon MQ broker, sends a message, and receives it. This application will retrieve the broker credentials from AWS Secrets Manager:

```bash
# Create project directory
mkdir -p amazon-mq-demo/src/main/java/com/example

# Create pom.xml file with required dependencies
cat > amazon-mq-demo/pom.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.example</groupId>
    <artifactId>amazon-mq-demo</artifactId>
    <version>1.0-SNAPSHOT</version>

    <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.apache.activemq</groupId>
            <artifactId>activemq-client</artifactId>
            <version>5.15.16</version>
        </dependency>
        <dependency>
            <groupId>org.apache.activemq</groupId>
            <artifactId>activemq-pool</artifactId>
            <version>5.15.16</version>
        </dependency>
        <dependency>
            <groupId>software.amazon.awssdk</groupId>
            <artifactId>secretsmanager</artifactId>
            <version>2.20.45</version>
        </dependency>
        <dependency>
            <groupId>com.google.code.gson</groupId>
            <artifactId>gson</artifactId>
            <version>2.10.1</version>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.8.1</version>
            </plugin>
            <plugin>
                <groupId>org.codehaus.mojo</groupId>
                <artifactId>exec-maven-plugin</artifactId>
                <version>3.0.0</version>
                <configuration>
                    <mainClass>com.example.AmazonMQExample</mainClass>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
EOF
```

This Maven configuration includes:
- ActiveMQ client and connection pooling dependencies
- AWS SDK for Secrets Manager to retrieve the broker credentials
- Gson for parsing the JSON response from Secrets Manager

Now, create the Java application file:

```bash
# Create the Java application file with the actual endpoint and secret retrieval
cat > amazon-mq-demo/src/main/java/com/example/AmazonMQExample.java << EOF
package com.example;

import org.apache.activemq.ActiveMQConnectionFactory;
import org.apache.activemq.jms.pool.PooledConnectionFactory;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.secretsmanager.SecretsManagerClient;
import software.amazon.awssdk.services.secretsmanager.model.GetSecretValueRequest;
import software.amazon.awssdk.services.secretsmanager.model.GetSecretValueResponse;
import com.google.gson.Gson;
import com.google.gson.JsonObject;

import javax.jms.*;

public class AmazonMQExample {

    // Broker connection details
    private final static String WIRE_LEVEL_ENDPOINT = "$WIRE_ENDPOINT";
    private final static String SECRET_NAME = "$SECRET_NAME";
    
    // Credentials will be retrieved from AWS Secrets Manager
    private static String username;
    private static String password;

    public static void main(String[] args) throws JMSException {
        // Retrieve credentials from AWS Secrets Manager
        retrieveCredentials();
        
        final ActiveMQConnectionFactory connectionFactory = createActiveMQConnectionFactory();
        final PooledConnectionFactory pooledConnectionFactory = createPooledConnectionFactory(connectionFactory);

        sendMessage(pooledConnectionFactory);
        receiveMessage(connectionFactory);

        pooledConnectionFactory.stop();
    }
    
    private static void retrieveCredentials() {
        try {
            // Create a Secrets Manager client
            SecretsManagerClient client = SecretsManagerClient.builder()
                    .region(Region.of(System.getenv("AWS_REGION")))
                    .build();
                    
            GetSecretValueRequest getSecretValueRequest = GetSecretValueRequest.builder()
                    .secretId(SECRET_NAME)
                    .build();
                    
            GetSecretValueResponse getSecretValueResponse = client.getSecretValue(getSecretValueRequest);
            String secretString = getSecretValueResponse.secretString();
            
            // Parse the JSON string
            JsonObject jsonObject = new Gson().fromJson(secretString, JsonObject.class);
            username = jsonObject.get("username").getAsString();
            password = jsonObject.get("password").getAsString();
            
            System.out.println("Successfully retrieved credentials from AWS Secrets Manager");
        } catch (Exception e) {
            System.err.println("Error retrieving credentials from AWS Secrets Manager: " + e.getMessage());
            System.exit(1);
        }
    }

    private static void sendMessage(PooledConnectionFactory pooledConnectionFactory) throws JMSException {
        // Establish a connection for the producer
        final Connection producerConnection = pooledConnectionFactory.createConnection();
        producerConnection.start();

        // Create a session
        final Session producerSession = producerConnection.createSession(false, Session.AUTO_ACKNOWLEDGE);

        // Create a queue named "MyQueue"
        final Destination producerDestination = producerSession.createQueue("MyQueue");

        // Create a producer from the session to the queue
        final MessageProducer producer = producerSession.createProducer(producerDestination);
        producer.setDeliveryMode(DeliveryMode.NON_PERSISTENT);

        // Create a message
        final String text = "Hello from Amazon MQ!";
        final TextMessage producerMessage = producerSession.createTextMessage(text);

        // Send the message
        producer.send(producerMessage);
        System.out.println("Message sent: " + text);

        // Clean up the producer
        producer.close();
        producerSession.close();
        producerConnection.close();
    }

    private static void receiveMessage(ActiveMQConnectionFactory connectionFactory) throws JMSException {
        // Establish a connection for the consumer
        // Note: Consumers should not use PooledConnectionFactory
        final Connection consumerConnection = connectionFactory.createConnection();
        consumerConnection.start();

        // Create a session
        final Session consumerSession = consumerConnection.createSession(false, Session.AUTO_ACKNOWLEDGE);

        // Create a queue named "MyQueue"
        final Destination consumerDestination = consumerSession.createQueue("MyQueue");

        // Create a message consumer from the session to the queue
        final MessageConsumer consumer = consumerSession.createConsumer(consumerDestination);

        // Begin to wait for messages
        final Message consumerMessage = consumer.receive(1000);

        // Receive the message when it arrives
        final TextMessage consumerTextMessage = (TextMessage) consumerMessage;
        System.out.println("Message received: " + consumerTextMessage.getText());

        // Clean up the consumer
        consumer.close();
        consumerSession.close();
        consumerConnection.close();
    }

    private static PooledConnectionFactory createPooledConnectionFactory(ActiveMQConnectionFactory connectionFactory) {
        // Create a pooled connection factory
        final PooledConnectionFactory pooledConnectionFactory = new PooledConnectionFactory();
        pooledConnectionFactory.setConnectionFactory(connectionFactory);
        pooledConnectionFactory.setMaxConnections(10);
        return pooledConnectionFactory;
    }

    private static ActiveMQConnectionFactory createActiveMQConnectionFactory() {
        // Create a connection factory
        final ActiveMQConnectionFactory connectionFactory = new ActiveMQConnectionFactory(WIRE_LEVEL_ENDPOINT);

        // Pass the sign-in credentials
        connectionFactory.setUserName(username);
        connectionFactory.setPassword(password);
        return connectionFactory;
    }
}
EOF
```

This Java application:
1. Connects to AWS Secrets Manager to retrieve the broker credentials
2. Establishes a connection to your Amazon MQ broker using those credentials
3. Sends a message to a queue named "MyQueue"
4. Receives that message from the queue

## Step 7: Build and run the application

Now, build and run the Java application:

```bash
cd amazon-mq-demo
mvn clean compile
mvn exec:java
```

If successful, you should see output similar to:
```
Successfully retrieved credentials from AWS Secrets Manager
Message sent: Hello from Amazon MQ!
Message received: Hello from Amazon MQ!
```

This confirms that your application successfully:
1. Retrieved the credentials from AWS Secrets Manager
2. Connected to the Amazon MQ broker
3. Sent a message to a queue
4. Received that message from the queue

## Step 8: Access the ActiveMQ web console (Optional)

You can also access the ActiveMQ web console to monitor your broker:

1. Open the web console URL in your browser (the URL you retrieved earlier)
2. Log in with the username and password stored in Secrets Manager
3. Navigate to the "Queues" tab to see the "MyQueue" that was created by your application
4. You can explore other tabs to monitor connections, topics, and other broker metrics

## Step 9: Clean up resources

When you're done with the tutorial, you can delete the resources to avoid incurring additional charges:

```bash
# Delete the broker
aws mq delete-broker --broker-id "$BROKER_ID"

# Delete the secret
aws secretsmanager delete-secret --secret-id "$SECRET_ARN" --force-delete-without-recovery
```

The broker deletion process takes a few minutes to complete.

## Benefits of using AWS Secrets Manager

Using AWS Secrets Manager to store your broker credentials provides several advantages:

1. **Enhanced security**: Credentials are encrypted at rest and in transit, and access is controlled through IAM policies.

2. **Centralized management**: You can manage all your credentials in one place, making it easier to track and update them.

3. **Automatic rotation**: You can configure Secrets Manager to automatically rotate credentials on a schedule.

4. **Audit and compliance**: Secrets Manager integrates with AWS CloudTrail, allowing you to audit who accessed your secrets and when.

5. **Reduced risk of credential exposure**: By retrieving credentials programmatically, you avoid hardcoding them in your application code or storing them in environment variables.

## Going to production

This tutorial is designed to help you learn how to use Amazon MQ with the AWS CLI and Secrets Manager, not to provide production-ready configurations. If you're planning to use Amazon MQ in a production environment, consider the following best practices:

### Security considerations

1. **Use private accessibility**: Instead of making your broker publicly accessible, configure it to be accessible only within your VPC.

2. **Implement proper IAM policies**: Restrict access to your Secrets Manager secrets using IAM policies.

3. **Use more secure authentication**: Consider using LDAP authentication instead of simple username/password authentication.

4. **Configure encryption**: Ensure that your data is encrypted both in transit and at rest.

5. **Implement credential rotation**: Configure Secrets Manager to automatically rotate your broker credentials.

### Architecture considerations

1. **Use active/standby deployment**: For high availability, use the active/standby deployment mode instead of single-instance.

2. **Right-size your broker**: Choose an appropriate instance type based on your workload requirements.

3. **Implement proper connection pooling**: Follow best practices for connection pooling to optimize performance.

4. **Configure message persistence**: Configure message persistence to prevent data loss in case of broker failure.

5. **Set up monitoring and alerting**: Use Amazon CloudWatch to monitor your broker and set up alerts for important metrics.

For more information on best practices, see:
- [Amazon MQ Best Practices](https://docs.aws.amazon.com/amazon-mq/latest/developer-guide/best-practices-activemq.html)
- [AWS Secrets Manager Best Practices](https://docs.aws.amazon.com/secretsmanager/latest/userguide/best-practices.html)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)

## Troubleshooting

### Connection issues

If you're having trouble connecting to your broker:

1. **Check security group rules**: Ensure that the security group allows inbound connections from your IP address to the required ports.

2. **Verify broker status**: Make sure the broker is in the `RUNNING` state.

3. **Check network connectivity**: Ensure that your network allows outbound connections to the broker's endpoints.

4. **Verify credentials**: Double-check that the credentials in Secrets Manager are correct.

### Java application issues

If the Java application fails to compile or run:

1. **Check Java version**: Ensure you have Java 11 or later installed.

2. **Verify Maven installation**: Make sure Maven is properly installed and configured.

3. **Check AWS credentials**: Ensure that your AWS credentials are properly configured to allow the application to access Secrets Manager.

4. **Examine error messages**: Look for specific error messages in the output to identify the issue.

### Secrets Manager issues

If you're having trouble with Secrets Manager:

1. **Check IAM permissions**: Ensure that your IAM user or role has the necessary permissions to access the secret.

2. **Verify region**: Make sure you're using the correct AWS region when accessing the secret.

3. **Check secret name**: Verify that you're using the correct secret name or ARN.

## Next steps

Now that you've created an Amazon MQ broker with secure credential management, you can explore more advanced features:

- [Configure automatic credential rotation](https://docs.aws.amazon.com/secretsmanager/latest/userguide/rotating-secrets.html) to enhance security
- [Configure broker network of brokers](https://docs.aws.amazon.com/amazon-mq/latest/developer-guide/network-of-brokers.html) to connect multiple brokers together
- [Configure broker storage](https://docs.aws.amazon.com/amazon-mq/latest/developer-guide/broker-storage.html) to understand storage options for your broker
- [Monitor your broker](https://docs.aws.amazon.com/amazon-mq/latest/developer-guide/security-logging-monitoring.html) using Amazon CloudWatch metrics and logs
- [Create an ActiveMQ broker with high availability](https://docs.aws.amazon.com/amazon-mq/latest/developer-guide/amazon-mq-broker-architecture.html#active-standby-broker-deployment) by using the active/standby deployment mode
