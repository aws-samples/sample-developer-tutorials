import boto3
import uuid

# Initialize a session using Amazon EC2
ec2 = boto3.client('ec2')

# Unique suffix for resources
suffix = str(uuid.uuid4())

# Create and configure a volume in a valid availability zone
valid_zones = [zone['ZoneName'] for zone in ec2.describe_availability_zones()['AvailabilityZones'] if zone['State'] == 'available' and zone['RegionName'] == 'us-west-2']
if valid_zones:
    availability_zone = valid_zones[0]
    volume_id = ec2.create_volume(
        AvailabilityZone=availability_zone,
        Size=1,
        Encrypted=True,
        TagSpecifications=[
            {
                'ResourceType': 'volume',
                'Tags': [
                    {'Key': 'project', 'Value': 'doc-smith'},
                    {'Key': 'tutorial', 'Value': 'ebs-gs'}
                ]
            },
        ]
    )['VolumeId']

    # Wait until the volume is available
    ec2.get_waiter('volume_available').wait(VolumeIds=[volume_id])

    # Create and configure a snapshot
    snapshot_id = ec2.create_snapshot(
        VolumeId=volume_id,
        Description='Test snapshot for EBS getting started'
    )['SnapshotId']

    # Wait until the snapshot is completed
    ec2.get_waiter('snapshot_completed').wait(SnapshotIds=[snapshot_id])

    # Print statuses
    print(f"Volume created: {volume_id}")
    print(f"Snapshot created: {snapshot_id}")
    print("PASS")

    # Cleanup
    ec2.delete_snapshot(SnapshotId=snapshot_id)
    ec2.delete_volume(VolumeId=volume_id)
else:
    print("No valid availability zones found in us-west-2")