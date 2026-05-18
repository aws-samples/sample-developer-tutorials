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