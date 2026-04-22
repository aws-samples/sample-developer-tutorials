#!/bin/bash

# EMR Getting Started Tutorial Script
# This script automates the steps in the Amazon EMR Getting Started tutorial


# Set up logging
LOG_FILE="emr-tutorial.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Starting Amazon EMR Getting Started Tutorial Script"
echo "Logging to $LOG_FILE"

# Function to handle errors
handle_error() {
    echo "ERROR: $1"
    echo "Resources created so far:"
    if [ -n "$BUCKET_NAME" ]; then echo "- S3 Bucket: $BUCKET_NAME"; fi
    if [ -n "$CLUSTER_ID" ]; then echo "- EMR Cluster: $CLUSTER_ID"; fi
    
    echo "Attempting to clean up resources..."
    cleanup
    exit 1
}

# Function to clean up resources
cleanup() {
    echo ""
    echo "==========================================="
    echo "CLEANUP CONFIRMATION"
    echo "==========================================="
    echo "Do you want to clean up all created resources? (y/n): "
    read -r CLEANUP_CHOICE
    
    if [[ "${CLEANUP_CHOICE,,}" == "y" ]]; then
        echo "Starting cleanup process..."
        
        # Terminate EMR cluster if it exists
        if [ -n "$CLUSTER_ID" ]; then
            echo "Terminating EMR cluster: $CLUSTER_ID"
            aws emr terminate-clusters --cluster-ids "$CLUSTER_ID"
            
            echo "Waiting for cluster to terminate..."
            aws emr wait cluster-terminated --cluster-id "$CLUSTER_ID"
            echo "Cluster terminated successfully."
        fi
        
        # Delete S3 bucket and contents if it exists
        if [ -n "$BUCKET_NAME" ]; then
            echo "Deleting S3 bucket contents: $BUCKET_NAME"
            aws s3 rm "s3://$BUCKET_NAME" --recursive
            
            echo "Deleting S3 bucket: $BUCKET_NAME"
            aws s3 rb "s3://$BUCKET_NAME"
        fi
        
        echo "Cleanup completed."
    else
        echo "Cleanup skipped. Resources will remain in your AWS account."
        echo "To avoid ongoing charges, remember to manually delete these resources."
    fi
}

# Generate a random identifier for S3 bucket
RANDOM_ID=$(openssl rand -hex 6)
# Check for shared prereq bucket
PREREQ_BUCKET=$(aws cloudformation describe-stacks --stack-name tutorial-prereqs-bucket \
    --query 'Stacks[0].Outputs[?OutputKey==`BucketName`].OutputValue' --output text 2>/dev/null)
if [ -n "$PREREQ_BUCKET" ] && [ "$PREREQ_BUCKET" != "None" ]; then
    BUCKET_NAME="$PREREQ_BUCKET"
    BUCKET_IS_SHARED=true
    echo "Using shared bucket: $BUCKET_NAME"
else
    BUCKET_IS_SHARED=false
    BUCKET_NAME="emr${RANDOM_ID}"
fi
echo "Using bucket name: $BUCKET_NAME"

# Create S3 bucket
echo "Creating S3 bucket: $BUCKET_NAME"
aws s3 mb "s3://$BUCKET_NAME" || handle_error "Failed to create S3 bucket"
echo "S3 bucket created successfully."

# Create PySpark script
echo "Creating PySpark script: health_violations.py"
cat > health_violations.py << 'EOL'
import argparse

from pyspark.sql import SparkSession

def calculate_red_violations(data_source, output_uri):
    """
    Processes sample food establishment inspection data and queries the data to find the top 10 establishments
    with the most Red violations from 2006 to 2020.

    :param data_source: The URI of your food establishment data CSV, such as 's3://emr-tutorial-bucket/food-establishment-data.csv'.
    :param output_uri: The URI where output is written, such as 's3://emr-tutorial-bucket/restaurant_violation_results'.
    """
    with SparkSession.builder.appName("Calculate Red Health Violations").getOrCreate() as spark:
        # Load the restaurant violation CSV data
        if data_source is not None:
            restaurants_df = spark.read.option("header", "true").csv(data_source)

        # Create an in-memory DataFrame to query
        restaurants_df.createOrReplaceTempView("restaurant_violations")

        # Create a DataFrame of the top 10 restaurants with the most Red violations
        top_red_violation_restaurants = spark.sql("""SELECT name, count(*) AS total_red_violations 
          FROM restaurant_violations 
          WHERE violation_type = 'RED' 
          GROUP BY name 
          ORDER BY total_red_violations DESC LIMIT 10""")

        # Write the results to the specified output URI
        top_red_violation_restaurants.write.option("header", "true").mode("overwrite").csv(output_uri)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--data_source', help="The URI for you CSV restaurant data, like an S3 bucket location.")
    parser.add_argument(
        '--output_uri', help="The URI where output is saved, like an S3 bucket location.")
    args = parser.parse_args()

    calculate_red_violations(args.data_source, args.output_uri)
EOL

# Upload PySpark script to S3
echo "Uploading PySpark script to S3"
aws s3 cp health_violations.py "s3://$BUCKET_NAME/" || handle_error "Failed to upload PySpark script"
echo "PySpark script uploaded successfully."

# Download and prepare sample data
echo "Downloading sample data"
curl -o food_establishment_data.zip https://docs.aws.amazon.com/emr/latest/ManagementGuide/samples/food_establishment_data.zip || handle_error "Failed to download sample data"
unzip -o food_establishment_data.zip || handle_error "Failed to unzip sample data"
echo "Sample data downloaded and extracted successfully."

# Upload sample data to S3
echo "Uploading sample data to S3"
aws s3 cp food_establishment_data.csv "s3://$BUCKET_NAME/" || handle_error "Failed to upload sample data"
echo "Sample data uploaded successfully."

# Create IAM default roles for EMR
echo "Creating IAM default roles for EMR"
aws emr create-default-roles || handle_error "Failed to create default roles"
echo "IAM default roles created successfully."

# Check if EC2 key pair exists
echo "Checking for EC2 key pair"
KEY_PAIRS=$(aws ec2 describe-key-pairs --query "KeyPairs[*].KeyName" --output text)

if [ -z "$KEY_PAIRS" ]; then
    echo "No EC2 key pairs found. Creating a new key pair..."
    KEY_NAME="emr-tutorial-key-$RANDOM_ID"
    aws ec2 create-key-pair --key-name "$KEY_NAME" --query "KeyMaterial" --output text > "${KEY_NAME}.pem"
    chmod 400 "${KEY_NAME}.pem"
    echo "Created new key pair: $KEY_NAME"
else
    # Use the first available key pair
    KEY_NAME=$(echo "$KEY_PAIRS" | awk '{print $1}')
    echo "Using existing key pair: $KEY_NAME"
fi

# Launch EMR cluster
echo "Launching EMR cluster with Spark"
CLUSTER_RESPONSE=$(aws emr create-cluster \
  --name "EMR Tutorial Cluster" \
  --release-label emr-6.10.0 \
  --applications Name=Spark \
  --ec2-attributes KeyName="$KEY_NAME" \
  --instance-type m5.xlarge \
  --instance-count 3 \
  --use-default-roles \
  --log-uri "s3://$BUCKET_NAME/logs/")

# Check for errors in the response
if echo "$CLUSTER_RESPONSE" | grep -i "error" > /dev/null; then
    handle_error "Failed to create EMR cluster: $CLUSTER_RESPONSE"
fi

# Extract cluster ID
CLUSTER_ID=$(echo "$CLUSTER_RESPONSE" | grep -o '"ClusterId": "[^"]*' | cut -d'"' -f4)
if [ -z "$CLUSTER_ID" ]; then
    handle_error "Failed to extract cluster ID from response"
fi

echo "EMR cluster created with ID: $CLUSTER_ID"

# Wait for cluster to be ready
echo "Waiting for cluster to be ready (this may take several minutes)..."
aws emr wait cluster-running --cluster-id "$CLUSTER_ID" || handle_error "Cluster failed to reach running state"

# Check if cluster is in WAITING state
CLUSTER_STATE=$(aws emr describe-cluster --cluster-id "$CLUSTER_ID" --query "Cluster.Status.State" --output text)
if [ "$CLUSTER_STATE" != "WAITING" ]; then
    echo "Waiting for cluster to reach WAITING state..."
    while [ "$CLUSTER_STATE" != "WAITING" ]; do
        sleep 30
        CLUSTER_STATE=$(aws emr describe-cluster --cluster-id "$CLUSTER_ID" --query "Cluster.Status.State" --output text)
        echo "Current cluster state: $CLUSTER_STATE"
        
        # Check for error states
        if [[ "$CLUSTER_STATE" == "TERMINATED_WITH_ERRORS" || "$CLUSTER_STATE" == "TERMINATED" ]]; then
            handle_error "Cluster entered error state: $CLUSTER_STATE"
        fi
    done
fi

echo "Cluster is now in WAITING state and ready to accept work."

# Submit Spark application as a step
echo "Submitting Spark application as a step"
STEP_RESPONSE=$(aws emr add-steps \
  --cluster-id "$CLUSTER_ID" \
  --steps Type=Spark,Name="Health Violations Analysis",ActionOnFailure=CONTINUE,Args=["s3://$BUCKET_NAME/health_violations.py","--data_source","s3://$BUCKET_NAME/food_establishment_data.csv","--output_uri","s3://$BUCKET_NAME/results/"])

# Check for errors in the response
if echo "$STEP_RESPONSE" | grep -i "error" > /dev/null; then
    handle_error "Failed to submit step: $STEP_RESPONSE"
fi

# FIXED: Check if jq is available before using it
# Extract step ID using the appropriate method based on available tools
if command -v jq &> /dev/null; then
    # Use jq if available
    echo "Using jq to parse JSON response"
    STEP_ID=$(echo "$STEP_RESPONSE" | jq -r '.StepIds[0]')
else
    # Fallback to grep/awk if jq is not available
    echo "jq not found, using grep for parsing"
    STEP_ID=$(echo "$STEP_RESPONSE" | grep -o '"StepIds":\s*\[\s*"[^"]*"' | grep -o 's-[A-Z0-9]*')
    if [ -z "$STEP_ID" ]; then
        # Another fallback method
        STEP_ID=$(echo "$STEP_RESPONSE" | grep -o '"StepIds":\s*\[\s*"[^"]*' | grep -o 's-[A-Z0-9]*')
        if [ -z "$STEP_ID" ]; then
            # One more attempt with a different pattern
            STEP_ID=$(echo "$STEP_RESPONSE" | grep -o 's-[A-Z0-9]*')
            if [ -z "$STEP_ID" ]; then
                echo "Full step response: $STEP_RESPONSE"
                handle_error "Failed to extract step ID from response"
            fi
        fi
    fi
fi

if [ -z "$STEP_ID" ] || [ "$STEP_ID" == "null" ]; then
    echo "Full step response: $STEP_RESPONSE"
    handle_error "Failed to extract valid step ID from response"
fi

echo "Step submitted with ID: $STEP_ID"

# Wait for step to complete
echo "Waiting for step to complete (this may take several minutes)..."
aws emr wait step-complete --cluster-id "$CLUSTER_ID" --step-id "$STEP_ID" || handle_error "Step failed to complete"

# Check step status
STEP_STATE=$(aws emr describe-step --cluster-id "$CLUSTER_ID" --step-id "$STEP_ID" --query "Step.Status.State" --output text)
if [ "$STEP_STATE" != "COMPLETED" ]; then
    handle_error "Step did not complete successfully. Final state: $STEP_STATE"
fi

echo "Step completed successfully."

# View results
echo "Listing output files in S3"
aws s3 ls "s3://$BUCKET_NAME/results/" || handle_error "Failed to list output files"

# Download results
echo "Downloading results file"
RESULT_FILE=$(aws s3 ls "s3://$BUCKET_NAME/results/" | grep -o "part-[0-9]*.csv" | head -1)
if [ -z "$RESULT_FILE" ]; then
    echo "No result file found with pattern 'part-[0-9]*.csv'. Trying to find any CSV file..."
    RESULT_FILE=$(aws s3 ls "s3://$BUCKET_NAME/results/" | grep -o "part-.*\.csv" | head -1)
    if [ -z "$RESULT_FILE" ]; then
        echo "Listing all files in results directory:"
        aws s3 ls "s3://$BUCKET_NAME/results/"
        handle_error "No result file found in the output directory"
    fi
fi

aws s3 cp "s3://$BUCKET_NAME/results/$RESULT_FILE" ./results.csv || handle_error "Failed to download results file"

echo "Results downloaded to results.csv"
echo "Top 10 establishments with the most red violations:"
cat results.csv

# Display SSH connection information
echo ""
echo "To connect to the cluster via SSH, use the following command:"
echo "aws emr ssh --cluster-id $CLUSTER_ID --key-pair-file ${KEY_NAME}.pem"

# Display summary of created resources
echo ""
echo "==========================================="
echo "RESOURCES CREATED"
echo "==========================================="
echo "- S3 Bucket: $BUCKET_NAME"
echo "- EMR Cluster: $CLUSTER_ID"
echo "- Results file: results.csv"
if [ -f "${KEY_NAME}.pem" ]; then
    echo "- EC2 Key Pair: $KEY_NAME (saved to ${KEY_NAME}.pem)"
fi

# Offer to clean up resources
cleanup

echo "Script completed successfully."
