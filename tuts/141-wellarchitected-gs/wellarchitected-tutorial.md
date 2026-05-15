# Well-Architected Framework Tutorial

## Prerequisites

- Install and configure the AWS CLI.
- Ensure you have the necessary permissions to create and manage Well-Architected workloads.

## Steps

1. **Create Workload**

   ```sh
   $ aws wellarchitected create-workload \
     --tags '{"project": "doc-smith", "tutorial": "wellarchitected-gs"}' \
     --workload-name "workload-${SUFFIX}" \
     --environment "PREPRODUCTION" \
     --lenses "wellarchitected" \
     --description "Test workload for review" \
     --review-owner "test@example.com" \
     --aws-regions "us-east-1" \
     --query 'WorkloadId' \
     --output text
   ```

   This command creates a new workload with a unique name, tags, and specified environment. The workload ID is stored for later use.

2. **Get Workload**

   ```sh
   $ aws wellarchitected get-workload --workload-id "${WORKLOAD_ID}" --query 'Workload.WorkloadName' --output text
   ```

   This command retrieves the details of the created workload, specifically the workload name.

3. **List Workloads**

   ```sh
   $ aws wellarchitected list-workloads --query 'length(WorkloadSummaries)' --output text
   ```

   This command lists all workloads and outputs the count of workload summaries.

## Clean up

All created resources are automatically cleaned up at the end of the script to avoid unnecessary charges or resource accumulation. The cleanup function deletes the created workload and removes temporary files.

## Next steps

- Explore additional Well-Architected lenses and frameworks.
- Integrate Well-Architected reviews into your CI/CD pipeline.
- Share your workload with team members for collaborative reviews.