#!/bin/bash

# Amazon MQ Getting Started Script
# This script creates an Amazon MQ broker and demonstrates connecting to it with a Java application

# - Added checks for Java and Maven installations before creating the Java application
# - Generate secure password and store in AWS Secrets Manager instead of hardcoding
# - Security improvements implemented

set -euo pipefail

# Set up logging
LOG_FILE="amazon-mq-tutorial.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Starting Amazon MQ tutorial script at $(date)"
echo "All commands and outputs will be logged to $LOG_FILE"

# Validation function for AWS region
validate_aws_credentials() {
    if ! aws sts get-caller-identity &> /dev/null; then
        echo "ERROR: AWS credentials not configured or invalid"
        exit 1
    fi
    
    if [ -z "${AWS_REGION:-}" ]; then
        echo "ERROR: AWS_REGION environment variable not set"
        exit 1
    fi
}

# Function to handle errors
handle_error() {
    echo "ERROR: $1"
    echo "Resources created:"
    if [ -n "${BROKER_ID:-}" ]; then
        echo "- Amazon MQ Broker: $BROKER_ID"
    fi
    if [ -n "${SECRET_ARN:-}" ]; then
        echo "- AWS Secrets Manager Secret: $SECRET_ARN"
    fi
    
    echo ""
    echo "==========================================="
    echo "CLEANUP CONFIRMATION"
    echo "==========================================="
    echo "An error occurred. Cleaning up all created resources..."
    
    cleanup_resources
    
    exit 1
}

# Function to clean up resources
cleanup_resources() {
    echo "Cleaning up resources..."
    
    if [ -n "${BROKER_ID:-}" ]; then
        echo "Deleting Amazon MQ broker: $BROKER_ID"
        if ! aws mq delete-broker --broker-id "$BROKER_ID" 2>/dev/null; then
            echo "Warning: Failed to delete broker or broker already deleted"
        else
            echo "Broker deletion initiated. It may take several minutes to complete."
        fi
    fi
    
    if [ -n "${SECRET_ARN:-}" ]; then
        echo "Deleting AWS Secrets Manager secret: $SECRET_ARN"
        if ! aws secretsmanager delete-secret --secret-id "$SECRET_ARN" --force-delete-without-recovery 2>/dev/null; then
            echo "Warning: Failed to delete secret or secret already deleted"
        else
            echo "Secret deleted."
        fi
    fi
}

# Trap errors and perform cleanup
trap 'handle_error "Script interrupted"' EXIT INT TERM

# Validate AWS credentials and region
validate_aws_credentials

# Generate a random identifier for resource names
RANDOM_ID=$(LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | fold -w 8 | head -n 1)
BROKER_NAME="mq-broker-${RANDOM_ID}"
SECRET_NAME="mq-broker-creds-${RANDOM_ID}"
BROKER_ID=""
SECRET_ARN=""

# Step 1: Generate a secure password and store it in AWS Secrets Manager
echo "Generating secure password and storing in AWS Secrets Manager..."

# Generate a secure password with special characters, numbers, uppercase and lowercase letters
# Avoid characters that may cause issues: backslash, quotes
MQ_PASSWORD=$(LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^&*()_+-=' < /dev/urandom | fold -w 20 | head -n 1)
MQ_USERNAME="mqadmin"

# Validate password was generated
if [ -z "$MQ_PASSWORD" ] || [ ${#MQ_PASSWORD} -lt 12 ]; then
    handle_error "Failed to generate secure password"
fi

# Create a JSON document with the credentials using printf for safer quoting
CREDENTIALS_JSON=$(printf '{"username":"%s","password":"%s"}' "$MQ_USERNAME" "$MQ_PASSWORD" | jq -c .)

if [ -z "$CREDENTIALS_JSON" ]; then
    handle_error "Failed to create credentials JSON"
fi

# Store the credentials in AWS Secrets Manager
SECRET_RESULT=$(aws secretsmanager create-secret \
  --name "$SECRET_NAME" \
  --description "Amazon MQ broker credentials for $BROKER_NAME" \
  --secret-string "$CREDENTIALS_JSON" 2>&1)

# Check for errors
if echo "$SECRET_RESULT" | grep -i "error" > /dev/null; then
    handle_error "Failed to create secret: $SECRET_RESULT"
fi

# Extract secret ARN using jq for safer parsing
SECRET_ARN=$(echo "$SECRET_RESULT" | jq -r '.ARN // empty')
if [ -z "$SECRET_ARN" ]; then
    handle_error "Failed to extract secret ARN from response"
fi

echo "Secret created successfully. ARN: $SECRET_ARN"

# Step 2: Create an Amazon MQ broker
echo "Creating Amazon MQ broker: $BROKER_NAME"
echo "WARNING: Broker is being created with public accessibility for tutorial purposes only"
echo "In production, use private subnets and proper network controls"

BROKER_RESULT=$(aws mq create-broker \
  --broker-name "$BROKER_NAME" \
  --engine-type ACTIVEMQ \
  --engine-version 5.18 \
  --host-instance-type mq.t3.micro \
  --deployment-mode SINGLE_INSTANCE \
  --authentication-strategy SIMPLE \
  --users "Username=$MQ_USERNAME,Password=$MQ_PASSWORD,ConsoleAccess=true" \
  --publicly-accessible \
  --auto-minor-version-upgrade \
  --storage-type EBS \
  2>&1)

# Check for errors
if echo "$BROKER_RESULT" | grep -i "error" > /dev/null; then
    handle_error "Failed to create broker: $BROKER_RESULT"
fi

# Extract broker ID using jq for safer parsing
BROKER_ID=$(echo "$BROKER_RESULT" | jq -r '.BrokerId // empty')
if [ -z "$BROKER_ID" ]; then
    handle_error "Failed to extract broker ID from response"
fi

echo "Broker creation initiated. Broker ID: $BROKER_ID"

# Step 3: Wait for the broker to be in RUNNING state
echo "Waiting for broker to be in RUNNING state. This may take 15-20 minutes..."
MAX_ATTEMPTS=120
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    BROKER_STATE=$(aws mq describe-broker --broker-id "$BROKER_ID" --query 'BrokerState' --output text 2>&1)
    
    if echo "$BROKER_STATE" | grep -i "error" > /dev/null; then
        handle_error "Error checking broker state: $BROKER_STATE"
    fi
    
    echo "Current broker state: $BROKER_STATE (Attempt $((ATTEMPT + 1))/$MAX_ATTEMPTS)"
    
    if [ "$BROKER_STATE" == "RUNNING" ]; then
        echo "Broker is now in RUNNING state"
        break
    elif [ "$BROKER_STATE" == "CREATION_FAILED" ]; then
        handle_error "Broker creation failed"
    fi
    
    ATTEMPT=$((ATTEMPT + 1))
    if [ $ATTEMPT -lt $MAX_ATTEMPTS ]; then
        echo "Waiting 60 seconds before checking again..."
        sleep 60
    fi
done

if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
    handle_error "Broker did not reach RUNNING state within expected time"
fi

# Step 4: Get broker connection details
echo "Retrieving broker connection details..."
BROKER_DETAILS=$(aws mq describe-broker --broker-id "$BROKER_ID" 2>&1)

if echo "$BROKER_DETAILS" | grep -i "error" > /dev/null; then
    handle_error "Failed to get broker details: $BROKER_DETAILS"
fi

# Extract web console URL using jq
WEB_CONSOLE=$(echo "$BROKER_DETAILS" | jq -r '.BrokerInstances[0].ConsoleURL // empty')
if [ -z "$WEB_CONSOLE" ] || [ "$WEB_CONSOLE" == "None" ]; then
    handle_error "Failed to get web console URL"
fi

# Extract wire-level endpoint for OpenWire using jq
WIRE_ENDPOINT=$(echo "$BROKER_DETAILS" | jq -r '.BrokerInstances[0].Endpoints[0] // empty')
if [ -z "$WIRE_ENDPOINT" ] || [ "$WIRE_ENDPOINT" == "None" ]; then
    handle_error "Failed to get wire-level endpoint"
fi

echo "Web Console URL: $WEB_CONSOLE"
echo "Wire-level Endpoint: $WIRE_ENDPOINT"

# Step 5: Configure security group for the broker
echo "Configuring security group for the broker..."
SECURITY_GROUP_ID=$(echo "$BROKER_DETAILS" | jq -r '.SecurityGroups[0] // empty')

if [ -z "$SECURITY_GROUP_ID" ] || [ "$SECURITY_GROUP_ID" == "None" ]; then
    handle_error "Failed to get security group ID"
fi

echo "Security Group ID: $SECURITY_GROUP_ID"

# Get current IP address with timeout and validation
CURRENT_IP=$(timeout 5 curl -s https://checkip.amazonaws.com | tr -d '[:space:]')
if [ -z "$CURRENT_IP" ]; then
    echo "WARNING: Failed to get current IP address. Skipping security group configuration."
    echo "You will need to manually configure security group rules for ports 8162 and 61617"
else
    # Validate IP format
    if ! [[ $CURRENT_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo "WARNING: Invalid IP address format: $CURRENT_IP. Skipping security group configuration."
    else
        echo "Your current IP address: $CURRENT_IP"

        # Allow inbound connections to the web console (port 8162)
        echo "Adding inbound rule for web console access (port 8162)..."
        if ! aws ec2 authorize-security-group-ingress \
          --group-id "$SECURITY_GROUP_ID" \
          --protocol tcp \
          --port 8162 \
          --cidr "${CURRENT_IP}/32" 2>/dev/null; then
            echo "Warning: Failed to add security group rule for port 8162. It might already exist or you may not have permissions."
        fi

        # Allow inbound connections to the OpenWire endpoint (port 61617)
        echo "Adding inbound rule for OpenWire access (port 61617)..."
        if ! aws ec2 authorize-security-group-ingress \
          --group-id "$SECURITY_GROUP_ID" \
          --protocol tcp \
          --port 61617 \
          --cidr "${CURRENT_IP}/32" 2>/dev/null; then
            echo "Warning: Failed to add security group rule for port 61617. It might already exist or you may not have permissions."
        fi
    fi
fi

# Step 6: Create Java application to connect to the broker
echo "Creating Java application to connect to the broker..."

# Check for Java and Maven installations before creating the Java application
echo "Checking for required dependencies..."
JAVA_INSTALLED=false
MAVEN_INSTALLED=false

if command -v java &> /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | head -n 1)
    echo "Java is installed: $JAVA_VERSION"
    JAVA_INSTALLED=true
else
    echo "Java is not installed. You will need to install Java to run the sample application."
fi

if command -v mvn &> /dev/null; then
    MAVEN_VERSION=$(mvn --version 2>&1 | head -n 1)
    echo "Maven is installed: $MAVEN_VERSION"
    MAVEN_INSTALLED=true
else
    echo "Maven is not installed. You will need to install Maven to build and run the sample application."
fi

# Create project directory with safe permissions
PROJECT_DIR="amazon-mq-demo"
mkdir -p "$PROJECT_DIR/src/main/java/com/example"
chmod 755 "$PROJECT_DIR"

# Create pom.xml file
cat > "$PROJECT_DIR/pom.xml" << 'EOF'
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
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.apache.activemq</groupId>
            <artifactId>activemq-client</artifactId>
            <version>5.18.3</version>
        </dependency>
        <dependency>
            <groupId>org.apache.activemq</groupId>
            <artifactId>activemq-pool</artifactId>
            <version>5.18.3</version>
        </dependency>
        <dependency>
            <groupId>software.amazon.awssdk</groupId>
            <artifactId>secretsmanager</artifactId>
            <version>2.21.0</version>
        </dependency>
        <dependency>
            <groupId>com.google.code.gson</groupId>
            <artifactId>gson</artifactId>
            <version>2.10.1</version>
        </dependency>
        <dependency>
            <groupId>org.slf4j</groupId>
            <artifactId>slf4j-simple</artifactId>
            <version>2.0.7</version>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.11.0</version>
            </plugin>
            <plugin>
                <groupId>org.codehaus.mojo</groupId>
                <artifactId>exec-maven-plugin</artifactId>
                <version>3.1.0</version>
                <configuration>
                    <mainClass>com.example.AmazonMQExample</mainClass>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
EOF

# Create Java application file with the actual endpoint and secret retrieval
cat > "$PROJECT_DIR/src/main/java/com/example/AmazonMQExample.java" << EOF
package com.example;

import org.apache.activemq.ActiveMQConnectionFactory;
import org.apache.activemq.jms.pool.PooledConnectionFactory;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.secretsmanager.SecretsManagerClient;
import software.amazon.awssdk.services.secretsmanager.model.GetSecretValueRequest;
import software.amazon.awssdk.services.secretsmanager.model.GetSecretValueResponse;
import software.amazon.awssdk.services.secretsmanager.model.ResourceNotFoundException;
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
        try {
            // Retrieve credentials from AWS Secrets Manager
            retrieveCredentials();
            
            final ActiveMQConnectionFactory connectionFactory = createActiveMQConnectionFactory();
            final PooledConnectionFactory pooledConnectionFactory = createPooledConnectionFactory(connectionFactory);

            sendMessage(pooledConnectionFactory);
            receiveMessage(connectionFactory);

            pooledConnectionFactory.stop();
            
            System.out.println("Application completed successfully");
        } catch (Exception e) {
            System.err.println("Fatal error: " + e.getMessage());
            e.printStackTrace();
            System.exit(1);
        }
    }
    
    private static void retrieveCredentials() {
        SecretsManagerClient client = null;
        try {
            // Create a Secrets Manager client
            String region = System.getenv("AWS_REGION");
            if (region == null || region.isEmpty()) {
                throw new IllegalArgumentException("AWS_REGION environment variable not set");
            }
            
            client = SecretsManagerClient.builder()
                    .region(Region.of(region))
                    .build();
                    
            GetSecretValueRequest getSecretValueRequest = GetSecretValueRequest.builder()
                    .secretId(SECRET_NAME)
                    .build();
                    
            GetSecretValueResponse getSecretValueResponse = client.getSecretValue(getSecretValueRequest);
            String secretString = getSecretValueResponse.secretString();
            
            if (secretString == null || secretString.isEmpty()) {
                throw new IllegalArgumentException("Secret value is empty");
            }
            
            // Parse the JSON string
            JsonObject jsonObject = new Gson().fromJson(secretString, JsonObject.class);
            
            if (!jsonObject.has("username") || !jsonObject.has("password")) {
                throw new IllegalArgumentException("Secret does not contain required fields");
            }
            
            username = jsonObject.get("username").getAsString();
            password = jsonObject.get("password").getAsString();
            
            if (username == null || username.isEmpty() || password == null || password.isEmpty()) {
                throw new IllegalArgumentException("Username or password is empty");
            }
            
            System.out.println("Successfully retrieved credentials from AWS Secrets Manager");
        } catch (ResourceNotFoundException e) {
            System.err.println("Error: Secret not found in AWS Secrets Manager: " + e.getMessage());
            System.exit(1);
        } catch (Exception e) {
            System.err.println("Error retrieving credentials from AWS Secrets Manager: " + e.getMessage());
            System.exit(1);
        } finally {
            if (client != null) {
                client.close();
            }
        }
    }

    private static void sendMessage(PooledConnectionFactory pooledConnectionFactory) throws JMSException {
        // Establish a connection for the producer
        final Connection producerConnection = pooledConnectionFactory.createConnection();
        producerConnection.setExceptionListener(exception -> {
            System.err.println("JMS Exception: " + exception.getMessage());
            exception.printStackTrace();
        });
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
        consumerConnection.setExceptionListener(exception -> {
            System.err.println("JMS Exception: " + exception.getMessage());
            exception.printStackTrace();
        });
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
        if (consumerMessage != null) {
            final TextMessage consumerTextMessage = (TextMessage) consumerMessage;
            System.out.println("Message received: " + consumerTextMessage.getText());
        } else {
            System.out.println("No message received within timeout period");
        }

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

echo "Java application created successfully"
echo "Project location: $(pwd)/$PROJECT_DIR"

# Step 7: Instructions for building and running the application
echo ""
echo "To build and run the Java application, execute the following commands:"
echo "cd $PROJECT_DIR"
echo "export AWS_REGION=$AWS_REGION"
echo "mvn clean compile"
echo "mvn exec:java"
echo ""

# Provide installation instructions if dependencies are missing
if [ "$JAVA_INSTALLED" = false ] || [ "$MAVEN_INSTALLED" = false ]; then
    echo "==========================================="
    echo "DEPENDENCY INSTALLATION INSTRUCTIONS"
    echo "==========================================="
    
    if [ "$JAVA_INSTALLED" = false ]; then
        echo "To install Java:"
        echo "  - Ubuntu/Debian: sudo apt-get install default-jdk"
        echo "  - Amazon Linux/RHEL/CentOS: sudo yum install java-11-amazon-corretto"
        echo "  - macOS: brew install openjdk@11"
        echo ""
    fi
    
    if [ "$MAVEN_INSTALLED" = false ]; then
        echo "To install Maven:"
        echo "  - Ubuntu/Debian: sudo apt-get install maven"
        echo "  - Amazon Linux/RHEL/CentOS: sudo yum install maven"
        echo "  - macOS: brew install maven"
        echo ""
    fi
    
    echo "After installing the required dependencies, you can proceed with building and running the application."
    echo ""
fi

# Display summary of created resources
echo ""
echo "==========================================="
echo "RESOURCE SUMMARY"
echo "==========================================="
echo "Amazon MQ Broker Name: $BROKER_NAME"
echo "Amazon MQ Broker ID: $BROKER_ID"
echo "Web Console URL: $WEB_CONSOLE"
echo "Wire-level Endpoint: $WIRE_ENDPOINT"
echo "Username: $MQ_USERNAME"
echo "Password: Stored in AWS Secrets Manager (not displayed)"
echo "Secret Name: $SECRET_NAME"
echo "Secret ARN: $SECRET_ARN"
echo "Security Group ID: $SECURITY_GROUP_ID"
echo ""

# Display cleanup instructions
echo "==========================================="
echo "CLEANUP INSTRUCTIONS"
echo "==========================================="
echo "To manually clean up resources created by this script, execute:"
echo "aws mq delete-broker --broker-id $BROKER_ID"
echo "aws secretsmanager delete-secret --secret-id $SECRET_ARN --force-delete-without-recovery"
echo ""

echo "Script completed at $(date)"

# Disable automatic cleanup trap
trap - EXIT INT TERM