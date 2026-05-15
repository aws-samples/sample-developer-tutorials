import boto3, time, random

suffix = str(int(time.time()))[-6:]
client = boto3.client('wellarchitected', region_name='us-east-1')

tags = [{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'wellarchitected-gs'}]

try:
    r = client.create_workload(
        WorkloadName=f'workload-{suffix}',
        Environment='PREPRODUCTION',
        Lenses=['wellarchitected'],
        Description='Test workload for review',
        ReviewOwner='test@example.com',
        AwsRegions=['us-east-1'],
        Tags=tags)
    workload_id = r['WorkloadId']
    print(f"Created workload: {workload_id}")
    g = client.get_workload(WorkloadId=workload_id)
    print(f"Name: {g['Workload']['WorkloadName']}")
    l = client.list_workloads()
    print(f"Workloads: {len(l['WorkloadSummaries'])}")
    client.delete_workload(WorkloadId=workload_id, ClientRequestToken=f'del-{suffix}')
    print("Deleted. PASS")
except Exception as e:
    print(f"An error occurred: {e}")
    try:
        client.delete_workload(WorkloadId=workload_id, ClientRequestToken=f'del-{suffix}')
        print("Cleanup attempted. Check status manually if needed.")
    except:
        pass