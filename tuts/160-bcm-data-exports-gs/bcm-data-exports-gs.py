import boto3
import json
import time
import random

suffix = str(int(time.time()))[-6:] + str(random.randint(1, 100))
client = boto3.client('bcm-data-exports', region_name='us-east-1')

# List existing exports
exports = client.list_exports()
print(f"Exports: {len(exports.get('Exports', []))}")

# Create a new export
export_name = f"example-export-{suffix}"
export_description = "This is an example export for getting started with bcm-data-exports"
export_arn = f"arn:aws:bcm-data-exports:us-east-1:123456789012:export/{export_name}"

try:
    create_export_response = client.create_export(
        Export={
            'Name': export_name,
            'Description': export_description,
            'DestinationConfiguration': {
                'DestinationType': 'S3',
                'S3Destination': {
                    'Bucket': 'your-s3-bucket-name',
                    'Prefix': 'your-s3-prefix/'
                }
            },
            'RefreshCadence': {
                'Frequency': 'MONTHLY'
            },
            'DataQuery': {
                'Query': 'your-query-here'
            }
        }
    )
    print(f"Created Export: {create_export_response}")

    # List exports again to verify the new export is created
    exports = client.list_exports()
    print(f"Exports after creation: {len(exports.get('Exports', []))}")

    # Get the newly created export
    get_export_response = client.get_export(ExportArn=export_arn)
    print(f"Get Export: {get_export_response}")

    # Tag the resource if supported
    try:
        tag_resource_response = client.tag_resource(
            ResourceArn=export_arn,
            Tags=[
                {'Key': 'project', 'Value': 'doc-smith'},
                {'Key': 'tutorial', 'Value': 'bcm-data-exports-gs'}
            ]
        )
        print(f"Tag Resource: {tag_resource_response}")
    except Exception as e:
        print(f"Tagging not supported: {e}")

    # List tags for the resource
    list_tags_response = client.list_tags_for_resource(ResourceArn=export_arn)
    print(f"List Tags: {list_tags_response}")

    # Update the export
    update_export_response = client.update_export(
        ExportArn=export_arn,
        Export={
            'Name': f"updated-example-export-{suffix}",
            'Description': "Updated example export for getting started with bcm-data-exports"
        }
    )
    print(f"Update Export: {update_export_response}")

    # Get the updated export
    get_export_response = client.get_export(ExportArn=export_arn)
    print(f"Get Updated Export: {get_export_response}")

    # Delete the export
    delete_export_response = client.delete_export(ExportArn=export_arn)
    print(f"Delete Export: {delete_export_response}")

    # List exports to verify the export is deleted
    exports = client.list_exports()
    print(f"Exports after deletion: {len(exports.get('Exports', []))}")

    print("PASS")
except Exception as e:
    print(f"An error occurred: {e}")