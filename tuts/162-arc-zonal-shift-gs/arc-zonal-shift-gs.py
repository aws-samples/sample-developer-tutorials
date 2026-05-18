import boto3, json, time, random

suffix = str(int(time.time()))[-6:] + str(random.randint(100, 999))
client = boto3.client('arc-zonal-shift', region_name='us-east-1')

print("=== ARC Zonal Shift Tutorial ===")
print("ARC Zonal Shift lets you temporarily move traffic away from an")
print("Availability Zone to recover from AZ impairments.")
print()

print("=== Listing managed resources ===")
print("Managed resources are load balancers or Auto Scaling groups")
print("registered for zonal shift and zonal autoshift.")
resources = client.list_managed_resources()
print(f"Managed resources: {len(resources.get('items', []))}")
print()

print("=== Listing zonal shifts ===")
print("Active zonal shifts show traffic currently being moved away from an AZ.")
shifts = client.list_zonal_shifts()
print(f"Active zonal shifts: {len(shifts.get('items', []))}")
print()

print("=== Listing autoshifts ===")
print("Autoshifts are automated responses to AZ impairments detected by AWS.")
autoshifts = client.list_autoshifts()
print(f"Autoshifts: {len(autoshifts.get('items', []))}")
print()

print("=== Tutorial complete ===")
print("To use zonal shift, register an ELB or ASG with update-zonal-autoshift-configuration.")
print("PASS")