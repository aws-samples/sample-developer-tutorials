# Tutorial: Managing AWS Schemas with CLI

This tutorial guides you through managing AWS Schemas using the AWS Command Line Interface (CLI). You create, describe, list, and delete schemas and registries.

## Prerequisites

- Install and configure the AWS CLI.
- Ensure you have the necessary permissions to create and delete AWS Schemas resources.

## Steps

### Step 1: Creating Registry

Create a registry with a unique name and description.

**Command:**

```bash
$ aws schemas create-registry --registry-name "test-registry-xmpl" --description "Test Registry" --tags Key=project,Value=doc-smith Key=tutorial,Value=schemas-gs
```

**Output:**

```json
{
    "RegistryArn": "arn:aws:schemas:us-east-1:123456789012:registry/test-registry-xmpl",
    "RegistryName": "test-registry-xmpl"
}
```

### Step 2: Describing Registry

Retrieve details of the created registry.

**Command:**

```bash
$ aws schemas describe-registry --registry-name "test-registry-xmpl"
```

**Output:**

```json
{
    "RegistryArn": "arn:aws:schemas:us-east-1:123456789012:registry/test-registry-xmpl",
    "RegistryName": "test-registry-xmpl",
    "Description": "Test Registry"
}
```

### Step 3: Creating Schema

Create a schema within the registry.

**Command:**

```bash
$ aws schemas create-schema --registry-name "test-registry-xmpl" --schema-name "test-schema-xmpl" --content "{\"type\":\"object\",\"properties\":{\"id\":{\"type\":\"integer\"}}}" --description "Test Schema" --type "JSONSchemaDraft4"
```

**Output:**

```json
{
    "SchemaArn": "arn:aws:schemas:us-east-1:123456789012:schema/test-registry-xmpl/test-schema-xmpl",
    "SchemaName": "test-schema-xmpl",
    "SchemaVersion": "xmpl",
    "Type": "JSONSchemaDraft4",
    "Description": "Test Schema"
}
```

### Step 4: Describing Schema

Retrieve details of the created schema.

**Command:**

```bash
$ aws schemas describe-schema --registry-name "test-registry-xmpl" --schema-name "test-schema-xmpl"
```

**Output:**

```json
{
    "Content": "{\"type\":\"object\",\"properties\":{\"id\":{\"type\":\"integer\"}}}",
    "SchemaArn": "arn:aws:schemas:us-east-1:123456789012:schema/test-registry-xmpl/test-schema-xmpl",
    "SchemaName": "test-schema-xmpl",
    "SchemaVersion": "xmpl",
    "Type": "JSONSchemaDraft4",
    "Description": "Test Schema"
}
```

### Step 5: Listing Schemas

List all schemas within the registry.

**Command:**

```bash
$ aws schemas list-schemas --registry-name "test-registry-xmpl"
```

**Output:**

```json
{
    "Schemas": [
        {
            "SchemaArn": "arn:aws:schemas:us-east-1:123456789012:schema/test-registry-xmpl/test-schema-xmpl",
            "SchemaName": "test-schema-xmpl"
        }
    ]
}
```

### Step 6: Deleting Schema

Delete the created schema.

**Command:**

```bash
$ aws schemas delete-schema --registry-name "test-registry-xmpl" --schema-name "test-schema-xmpl"
```

### Step 7: Deleting Registry

Delete the created registry.

**Command:**

```bash
$ aws schemas delete-registry --registry-name "test-registry-xmpl"
```

## Clean up

All created resources are automatically cleaned up at the end of the tutorial.

## Next steps

Explore more AWS Schemas features and integrate them into your applications.
