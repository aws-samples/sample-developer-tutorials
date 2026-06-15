#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)

# Export environment variable for the script
export TUTORIAL_ROLE_ARN=your_role_arn_here

python - <<EOF
import boto3
import time
import os

ROLE_ARN = os.getenv('TUTORIAL_ROLE_ARN')
suffix = '${SUFFIX}'
tags = [{'Key': 'project', 'Value': 'doc-smith'}, {'Key': 'tutorial', 'Value': 'lakeformation-gs'}]

lakeformation = boto3.client('lakeformation')

# Step 1: Create LF-Tag
print("Step 1: Creating LF-Tag to categorize resources.")
tag_name = f'tutorial-tag-{suffix}'
response = lakeformation.create_lf_tag(CatalogId='123456789012', TagKey=tag_name, TagValues=['value1', 'value2'], Tags=tags)
print(f"LF-Tag created with key: {tag_name}")

# Step 2: Create Data Cells Filter
print("Step 2: Creating Data Cells Filter to control data access.")
filter_name = f'tutorial-filter-{suffix}'
response = lakeformation.create_data_cells_filter(
    TableData={
        'DatabaseName': 'example_db',
        'TableName': 'example_table',
        'Name': filter_name,
        'RowFilter': {
            'FilterExpression': "column1 = 'value1'"
        },
        'ColumnNames': ['column1', 'column2'],
        'ColumnWildcard': {'ExcludedColumnNames': ['column3']}
    }
)
print(f"Data Cells Filter created with name: {filter_name}")
EOF

echo "PASS"
