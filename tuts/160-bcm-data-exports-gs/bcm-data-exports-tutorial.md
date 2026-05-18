# Tutorial for Getting Started with Bcm-data-exports

## Prerequisites

- An aws account.
- Python installed on your local machine.
- Boto3 python library installed.
- An s3 bucket where the export will be stored.

## Steps

**1. List existing exports**

```bash
$ exports = client.list_exports()
```

**2. Create a new export**

```bash
$ export_name = f"example-export-{suffix}"
$ export_description = "this is an example export for getting started with bcm-data-exports"
$ export_arn = f"arn:aws:bcm-data-exports:us-east-1:123456789012:export/{export_name}"
```

**3. Verify the new export is created**

```bash
$ exports = client.list_exports()
```

**4. Get the newly created export**

```bash
$ get_export_response = client.get_export(exportarn=export_arn)
```

**5. Tag the resource if supported**

```bash
$ tag_resource_response = client.tag_resource(
    resourcearn=export_arn,
    tags=[
        {'key': 'project', 'value': 'doc-smith'},
        {'key': 'tutorial', 'value': 'bcm-data-exports-gs'}
    ]
)
```

**6. List tags for the resource**

```bash
$ list_tags_response = client.list_tags_for_resource(resourcearn=export_arn)
```

**7. Update the export**

```bash
$ update_export_response = client.update_export(
    exportarn=export_arn,
    export={
        'name': f"updated-example-export-{suffix}",
        'description': "updated example export for getting started with bcm-data-exports"
    }
)
```

**8. Get the updated export**

```bash
$ get_export_response = client.get_export(exportarn=export_arn)
```

**9. Delete the export**

```bash
$ delete_export_response = client.delete_export(exportarn=export_arn)
```

**10. Verify the export is deleted**

```bash
$ exports = client.list_exports()
```

## Clean up

Delete any resources that are no longer needed to avoid unnecessary costs.

## Next steps

Explore more features and functionalities of bcm-data-exports.