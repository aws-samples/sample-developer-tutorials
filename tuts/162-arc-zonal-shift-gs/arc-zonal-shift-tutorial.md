# Arc Zonal Shift Tutorial

## Prerequisites

- Install and configure the [aws cli](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html).
- Ensure you have the necessary permissions to use the `arc-zonal-shift` service.

## Steps

**1. Import necessary libraries and set up the client**

```python
import boto3, json, time
suffix = str(int(time.time()))[-6:]
client = boto3.client('arc-zonal-shift', region_name='us-east-1')
```

**2. Print tutorial introduction**

```python
print("=== ARC Zonal Shift Tutorial ===")
print("ARC Zonal Shift lets you temporarily move traffic away from an")
print("Availability Zone to recover from AZ impairments.")
print()
```

**3. List managed resources**

Managed resources are load balancers or Auto Scaling groups registered for zonal shift and zonal autoshift.

```python
print("=== Listing managed resources ===")
resources = client.list_managed_resources()
print(f"Managed resources: {len(resources.get('items', []))}")
print()
```

**4. List zonal shifts**

Active zonal shifts show traffic currently being moved away from an AZ.

```python
print("=== Listing zonal shifts ===")
shifts = client.list_zonal_shifts()
print(f"Active zonal shifts: {len(shifts.get('items', []))}")
print()
```

**5. List autoshifts**

Autoshifts are automated responses to AZ impairments detected by AWS.

```python
print("=== Listing autoshifts ===")
autoshifts = client.list_autoshifts()
print(f"Autoshifts: {len(autoshifts.get('items', []))}")
print()
```

**6. Print tutorial completion message**

```python
print("=== Tutorial complete ===")
print("To use zonal shift, register an ELB or ASG with update-zonal-autoshift-configuration.")
print("PASS")
```

## Clean up

No resources were created in this tutorial that require cleanup.

## Next steps

- Explore how to register an Elastic Load Balancer (ELB) or Auto Scaling Group (ASG) with zonal autoshift using the `update-zonal-autoshift-configuration` command.
- Learn more about [AWS Arc Zonal Shift](https://docs.aws.amazon.com/r53recovery/latest/dg/arc-zonal-shift.html).