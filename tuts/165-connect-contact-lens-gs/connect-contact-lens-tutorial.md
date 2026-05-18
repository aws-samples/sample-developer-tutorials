# Tutorial for Getting Started with Connect Contact Lens

## Prerequisites
- An AWS account
- Python installed
- Boto3 library installed
  ```bash
  pip install boto3
  ```

## Steps

1. **Set Up Your Environment**
   Ensure you have the necessary AWS credentials configured. You can set them up using the AWS CLI:
   ```bash
   aws configure
   ```

2. **Install Boto3**
   If you haven't already, install the Boto3 library:
   ```bash
   pip install boto3
   ```

3. **Script to Fetch Real-time Contact Analysis Segments**
   Create a Python script to fetch real-time contact analysis segments using Connect Contact Lens.

   ```python
   import boto3
   import time
   import random

   suffix = str(int(time.time()))[-6:] + str(random.randint(1, 100))
   client = boto3.client('connect', region_name='us-east-1')

   try:
       instance_id = 'your-instance-id'  # Replace with your Connect instance ID
       contact_id = 'your-contact-id'    # Replace with your Contact ID
      
       response = client.list_realtime_contact_analysis_segments(
           InstanceId=instance_id,
           ContactId=contact_id
       )
      
       print(response)
       print("PASS")
   except Exception as e:
       print(f"An error occurred: {e}")
   ```

4. **Run the Script**
   Execute the script to fetch the analysis segments.
   ```bash
   python your_script_name.py
   ```

## Clean Up
Delete any resources created to avoid unnecessary charges.

## Next Steps
Explore more features of Connect Contact Lens, such as:
- Analyzing call transcripts
- Detecting sentiments and issues
- Generating detailed reports