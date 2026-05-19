# Getting started with Amazon Connect Cases

## Prerequisites

Before you begin, ensure you have the following:

- AWS CLI installed and configured
- Appropriate IAM permissions to create and manage Amazon Connect Cases resources
- A CloudFormation stack with necessary IAM roles if required

## Step 1: Create a Domain

**Create a Domain**

The following script creates a new Amazon Connect Cases Domain.

```bash
$ aws connectcases create-domain \
  --name "TutorialDomainabc123" \
  --template "SimpleTemplate" \
  --tags '{"Environment":"Tutorial","Project":"GettingStarted"}'
```

**Expected Result**

You should see output similar to the following, indicating the Domain has been created:

```json
{
    "domainArn": "arn:aws:connectcases:us-west-2:123456789012:domain/abc123",
    "domainId": "abc123"
}
```

## Step 2: Create a Field

**Create a Field**

The following script creates a new Field within the Domain.

```bash
$ aws connectcases create-field \
  --domain-id "abc123" \
  --name "TutorialFieldabc123" \
  --type "SingleSelect" \
  --allowed-values '["Option1","Option2"]'
```

**Expected Result**

You should see output similar to the following, indicating the Field has been created:

```json
{
    "fieldArn": "arn:aws:connectcases:us-west-2:123456789012:domain/abc123/field/abc123",
    "fieldId": "abc123"
}
```

## Step 3: Create a Layout

**Create a Layout**

The following script creates a new Layout within the Domain.

```bash
$ aws connectcases create-layout \
  --domain-id "abc123" \
  --name "TutorialLayoutabc123" \
  --content '[{"fieldId":"abc123","order":1}]'
```

**Expected Result**

You should see output similar to the following, indicating the Layout has been created:

```json
{
    "layoutArn": "arn:aws:connectcases:us-west-2:123456789012:domain/abc123/layout/abc123",
    "layoutId": "abc123"
}
```

## Step 4: Create a Case

**Create a Case**

The following script creates a new Case within the Domain.

```bash
$ aws connectcases create-case \
  --domain-id "abc123" \
  --title "TutorialCaseabc123" \
  --fields '[{"id":"abc123","value":{"stringValue":"Option1"}}]'
```

**Expected Result**

You should see output similar to the following, indicating the Case has been created:

```json
{
    "caseArn": "arn:aws:connectcases:us-west-2:123456789012:domain/abc123/case/abc123",
    "caseId": "abc123"
}
```

## Clean up

The following script deletes all created resources to avoid unnecessary charges.

**Delete Resources**

```bash
$ for resource in "${CREATED_RESOURCES[@]}"; do
    case "$resource" in
      "domain:"*)
        domain_id="${resource#*:}"
        echo "Deleting domain $domain_id"
        aws connectcases delete-domain --domain-id "$domain_id" || true
        ;;
      "field:"*)
        field_id="${resource#*:}"
        echo "Deleting field $field_id"
        aws connectcases delete-field --domain-id "$domain_id" --field-id "$field_id" || true
        ;;
      "layout:"*)
        layout_id="${resource#*:}"
        echo "Deleting layout $layout_id"
        aws connectcases delete-layout --domain-id "$domain_id" --layout-id "$layout_id" || true
        ;;
      "case:"*)
        case_id="${resource#*:}"
        echo "Deleting case $case_id"
        aws connectcases delete-case --domain-id "$domain_id" --case-id "$case_id" || true
        ;;
      *)
        echo "Unknown resource type: $resource"
        ;;
    esac
  done
```

**Expected Result**

All created resources (Domain, Field, Layout, and Case) will be deleted.

## Next steps

- Explore [Amazon Connect Cases documentation](https://docs.aws.amazon.com/connect/latest/adminguide/cases.html) for more details.
- Learn how to [integrate Amazon Connect Cases with other AWS services](https://aws.amazon.com/connect/features/cases/).
- Check out [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/) for best practices.
