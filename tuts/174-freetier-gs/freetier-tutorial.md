# Tutorial for Getting Started with Freetier

## Prerequisites
- An AWS account
- Python installed
- Boto3 library installed

## Steps

1. **Install Boto3**
   Ensure you have Boto3 installed. You can install it using pip:
   ```sh
   pip install boto3
   ```

2. **Set Up AWS Credentials**
   Configure your AWS credentials. You can do this by running:
   ```sh
   aws configure
   ```
   Provide your `AWS Access Key ID`, `AWS Secret Access Key`, `Default region name` (e.g., `us-east-1`), and `Output format` (e.g., `json`).

3. **Create the Python Script**
   Create a Python script named `freetier_tutorial.py` and add the following content:
   ```python
   import boto3
   import time
   import random

   suffix = str(int(time.time()))[-6:] + str(random.randint(1, 100))
   client = boto3.client('freetier', region_name='us-east-1')

   try:
       account_activities = client.list_account_activities()
       print("ListAccountActivities:", account_activities)
       
       account_plan_state = client.get_account_plan_state()
       print("GetAccountPlanState:", account_plan_state)
       
       free_tier_usage = client.get_free_tier_usage()
       print("GetFreeTierUsage:", free_tier_usage)
       
       print("PASS")
   except Exception as e:
       print("Error:", e)
   ```

4. **Run the Script**
   Execute the script using Python:
   ```sh
   python freetier_tutorial.py
   ```

## Clean up
No resources are created in this tutorial that need manual cleanup.

## Next steps
- Explore more features of the Free Tier using the Boto3 documentation.
- Monitor your Free Tier usage to ensure you stay within the limits.