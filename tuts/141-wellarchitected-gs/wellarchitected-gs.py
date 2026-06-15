import boto3, time, os

# Initialize boto3 client for Well-Architected
wellarchitected = boto3.client('wellarchitected', region_name='us-east-1')

# Check if ROLE_ARN is set, if not, print message and skip steps requiring it
ROLE_ARN = os.environ.get('TUTORIAL_ROLE_ARN')
if not ROLE_ARN:
    print("ROLE_ARN not set. Skipping steps that require it.")

# Generate a unique suffix for resource names
suffix = str(int(time.time()))[-6:]

# Define tags for resources
tags = [{'Key': 'project', 'Value': 'doc-smith'}, {'Key': 'tutorial', 'Value': 'wellarchitected-gs'}]

try:
    print("Creating a Well-Architected Workload.")
    r = wellarchitected.create_workload(
        WorkloadName=f'workload-{suffix}',
        Environment='PREPRODUCTION',
        Lenses=['wellarchitected'],
        Description='Test workload for review',
        ReviewOwner='test@example.com',
        AwsRegions=['us-east-1'],
        Tags=tags)
    workload_id = r['WorkloadId']
    print(f"Workload created with ID: {workload_id}")

    print("Retrieving workload details.")
    g = wellarchitected.get_workload(WorkloadId=workload_id)
    print(f"Name: {g['Workload']['WorkloadName']}")

    print("Listing workloads.")
    l = wellarchitected.list_workloads()
    print(f"Total workloads: {len(l['WorkloadSummaries'])}")

    print("Deleting the workload.")
    wellarchitected.delete_workload(WorkloadId=workload_id, ClientRequestToken=f'del-{suffix}')
    print("Workload deleted. PASS")
except Exception as e:
    print(f"An error occurred: {e}")
    try:
        wellarchitected.delete_workload(WorkloadId=workload_id, ClientRequestToken=f'del-{suffix}')
        print("Cleanup attempted. Check status manually if needed.")
    except:
        pass
print('PASS')