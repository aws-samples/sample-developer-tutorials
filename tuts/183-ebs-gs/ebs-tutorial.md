# Tutorial: Getting started with Amazon EBS

This tutorial guides you through creating and managing an Amazon Elastic Block Store (EBS) volume and snapshot using the AWS SDK for Python (Boto3).

## Prerequisites

- An AWS account.
- Python installed on your local machine.
- Boto3 library installed. You can install it using `$ pip install boto3`.

## Steps

1. **Initialize a session using Amazon EC2**

    ```python
    import boto3

    ec2 = boto3.client('ec2')
    ```

2. **Create a unique suffix for resources**

    ```python
    import uuid

    suffix = str(uuid.uuid4())
    ```

3. **Create and configure a volume in a valid availability zone**

    ```python
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
    ```

4. **Wait until the volume is available**

    ```python
    ec2.get_waiter('volume_available').wait(VolumeIds=[volume_id])
    ```

5. **Create and configure a snapshot**

    ```python
    snapshot_id = ec2.create_snapshot(
        VolumeId=volume_id,
        Description='Test snapshot for EBS getting started'
    )['SnapshotId']
    ```

6. **Wait until the snapshot is completed**

    ```python
    ec2.get_waiter('snapshot_completed').wait(SnapshotIds=[snapshot_id])
    ```

7. **Print statuses**

    ```python
    print(f"Volume created: {volume_id}")
    print(f"Snapshot created: {snapshot_id}")
    print("PASS")
    ```

## Clean up

- Delete the snapshot.

    ```python
    ec2.delete_snapshot(SnapshotId=snapshot_id)
    ```

- Delete the volume.

    ```python
    ec2.delete_volume(VolumeId=volume_id)
    ```

## Next steps

- Explore more about [Amazon EBS](https://aws.amazon.com/ebs/).
- Learn how to [optimize your EBS volumes](https://aws.amazon.com/ebs/details/).