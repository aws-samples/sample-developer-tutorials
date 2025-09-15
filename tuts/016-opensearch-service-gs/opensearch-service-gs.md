# Getting started with Amazon OpenSearch Service using the AWS CLI

This tutorial guides you through the process of creating and using an Amazon OpenSearch Service domain using the AWS Command Line Interface (AWS CLI). You'll learn how to create a domain, upload data, search for documents, and clean up resources when you're done.

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. The `curl` command-line tool for interacting with the OpenSearch API. Most Linux distributions and macOS have this installed by default. For Windows, you can use [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install) or [Cygwin](https://www.cygwin.com/).
4. [Sufficient permissions](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/ac.html) to create and manage OpenSearch Service resources in your AWS account.
5. Basic understanding of JSON and command-line operations.

This tutorial takes approximately 30-45 minutes to complete. You will incur charges for the OpenSearch Service domain until you delete it at the end of the tutorial. The estimated cost is approximately $0.038 per hour ($0.91 per day) for the t3.small instance and 10 GB of storage used in this tutorial.

## Create an OpenSearch Service domain

An OpenSearch Service domain is synonymous with an OpenSearch cluster. In this section, you'll create a domain with a basic configuration suitable for testing.

First, let's get your AWS account ID, which you'll need for the access policy:

```
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
```

This command retrieves your AWS account ID and stores it in a variable for later use.

Then, set your AWS region (required for access policy):
```
AWS_REGION=$(aws configure get region)
echo "Using AWS region: $AWS_REGION"
```

Now, create a domain named "movies" with the following configuration:

```
DOMAIN_NAME="movies"
MASTER_USER="master-user"
MASTER_PASSWORD='Master-Password123!'

ACCESS_POLICY="{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::${ACCOUNT_ID}:root\"},\"Action\":[\"es:ESHttpGet\",\"es:ESHttpPut\",\"es:ESHttpPost\",\"es:ESHttpDelete\"],\"Resource\":\"arn:aws:es:${AWS_REGION}:${ACCOUNT_ID}:domain/${DOMAIN_NAME}/*\"}]}"

aws opensearch create-domain \
  --domain-name "$DOMAIN_NAME" \
  --engine-version "OpenSearch_2.11" \
  --cluster-config "InstanceType=t3.small.search,InstanceCount=1,ZoneAwarenessEnabled=false" \
  --ebs-options "EBSEnabled=true,VolumeType=gp3,VolumeSize=10" \
  --node-to-node-encryption-options "Enabled=true" \
  --encryption-at-rest-options "Enabled=true" \
  --domain-endpoint-options "EnforceHTTPS=true" \
  --advanced-security-options "Enabled=true,InternalUserDatabaseEnabled=true,MasterUserOptions={MasterUserName=$MASTER_USER,MasterUserPassword=$MASTER_PASSWORD}" \
  --access-policies "$ACCESS_POLICY"
```

This command creates a domain with the following configuration:
- Domain name: movies
- Latest OpenSearch version (2.11)
- Single t3.small instance
- 10 GB of EBS storage
- Security features enabled (HTTPS, encryption at rest, node-to-node encryption)
- Fine-grained access control with a master user
- Access policy that allows only specific HTTP actions

The domain creation process typically takes 15-30 minutes. You can check the status with:

```
aws opensearch describe-domain --domain-name "$DOMAIN_NAME"
```

Look for the `"Processing": false` field in the output, which indicates that the domain is active. You'll also need the domain endpoint for the next steps, which you can extract with:

```
DOMAIN_ENDPOINT=$(aws opensearch describe-domain --domain-name "$DOMAIN_NAME" --query 'DomainStatus.Endpoint' --output text)
echo "Domain endpoint: $DOMAIN_ENDPOINT"
```

Make note of this endpoint as you'll need it for the next steps.

## Upload data to your domain

Once your domain is active, you can upload data to it. In this section, you'll upload documents using the master user authentication method.
You'll upload a single document and upload multiple documents in bulk.

### Verify variables are set correctly
```
echo "Domain endpoint: $DOMAIN_ENDPOINT"
echo "Master user: $MASTER_USER"
echo "Password set: $(if [ -n "$MASTER_PASSWORD" ]; then echo "Yes"; else echo "No";
fi)"
```

### Upload a single document

First, create a JSON file containing a single movie document:

```
cat > single_movie.json << EOF
{
  "director": "Burton, Tim",
  "genre": ["Comedy","Sci-Fi"],
  "year": 1996,
  "actor": ["Jack Nicholson","Pierce Brosnan","Sarah Jessica Parker"],
  "title": "Mars Attacks!"
}
EOF
```

This creates a file named `single_movie.json` with information about a movie.

Now, use curl to upload this document to your OpenSearch domain:

```
curl -XPUT -u "${MASTER_USER}:${MASTER_PASSWORD}" "https://${DOMAIN_ENDPOINT}/movies/_doc/1" \
  -d @single_movie.json \
  -H 'Content-Type: application/json'
```

This command adds the document to the "movies" index with an ID of "1". The `-u` option provides the master username and password for authentication.

**Success Response**: You should see a response like:
```json
{
    "_index": "movies",
    "_id": "1",
    "_version": 1,
    "result": "created"
}
```

### Upload multiple documents

For bulk uploads, you'll create a file with multiple documents in the OpenSearch bulk format:

```
cat > bulk_movies.json << EOF
{ "index" : { "_index": "movies", "_id" : "2" } }
{"director": "Frankenheimer, John", "genre": ["Drama", "Mystery", "Thriller", "Crime"], "year": 1962, "actor": ["Lansbury, Angela", "Sinatra, Frank", "Leigh, Janet", "Harvey, Laurence", "Silva, Henry", "Frees, Paul", "Gregory, James", "Bissell, Whit", "McGiver, John", "Parrish, Leslie", "Edwards, James", "Flowers, Bess", "Dhiegh, Khigh", "Payne, Julie", "Kleeb, Helen", "Gray, Joe", "Nalder, Reggie", "Stevens, Bert", "Masters, Michael", "Lowell, Tom"], "title": "The Manchurian Candidate"}
{ "index" : { "_index": "movies", "_id" : "3" } }
{"director": "Baird, Stuart", "genre": ["Action", "Crime", "Thriller"], "year": 1998, "actor": ["Downey Jr., Robert", "Jones, Tommy Lee", "Snipes, Wesley", "Pantoliano, Joe", "Jacob, Irène", "Nelligan, Kate", "Roebuck, Daniel", "Malahide, Patrick", "Richardson, LaTanya", "Wood, Tom", "Kosik, Thomas", "Stellate, Nick", "Minkoff, Robert", "Brown, Spitfire", "Foster, Reese", "Spielbauer, Bruce", "Mukherji, Kevin", "Cray, Ed", "Fordham, David", "Jett, Charlie"], "title": "U.S. Marshals"}
{ "index" : { "_index": "movies", "_id" : "4" } }
{"director": "Ray, Nicholas", "genre": ["Drama", "Romance"], "year": 1955, "actor": ["Hopper, Dennis", "Wood, Natalie", "Dean, James", "Mineo, Sal", "Backus, Jim", "Platt, Edward", "Ray, Nicholas", "Hopper, William", "Allen, Corey", "Birch, Paul", "Hudson, Rochelle", "Doran, Ann", "Hicks, Chuck", "Leigh, Nelson", "Williams, Robert", "Wessel, Dick", "Bryar, Paul", "Sessions, Almira", "McMahon, David", "Peters Jr., House"], "title": "Rebel Without a Cause"}
EOF
```

This creates a file named `bulk_movies.json` with three movie documents in the bulk format.

Now, upload these documents using the bulk API:

```
curl -XPOST -u "${MASTER_USER}:${MASTER_PASSWORD}" "https://${DOMAIN_ENDPOINT}/movies/_bulk" \
  --data-binary @bulk_movies.json \
  -H 'Content-Type: application/x-ndjson'
```

The bulk API allows you to perform multiple index operations in a single request, which is more efficient than individual requests.

## Search documents

Now that you've uploaded data, you can search for documents in your domain. In this section, you'll use both the command line and OpenSearch Dashboards to search for documents.

### Search from the command line

Use the following curl command to search for movies with "mars" in any field:

```
curl -XGET -u "${MASTER_USER}:${MASTER_PASSWORD}" "https://${DOMAIN_ENDPOINT}/movies/_search?q=mars&pretty=true"
```

The `q=mars` parameter searches for documents containing the word "mars", and `pretty=true` formats the JSON response for readability.

If you uploaded the bulk data, try searching for "rebel" instead:

```
curl -XGET -u "${MASTER_USER}:${MASTER_PASSWORD}" "https://${DOMAIN_ENDPOINT}/movies/_search?q=rebel&pretty=true"
```

You should see a response that includes the matching document(s) with details about the search operation.

### Access OpenSearch Dashboards

OpenSearch Dashboards provides a graphical interface for searching and visualizing your data. To access it:

1. Open the following URL in your web browser. Replace `DOMAIN-ENDPOINT` with your actual domain endpoint.
   ```
   https://DOMAIN-ENDPOINT/_dashboards/
   ```
2. Log in with the master username and password you created earlier.

3. Create an index pattern:
   - Navigate to Dashboards Management > Index patterns
   - Choose "Create index pattern"
   - Enter "movies" as the pattern
   - Choose "Next step" and then "Create index pattern"

4. Search your data:
   - Go to the "Discover" tab in the left navigation panel
   - Enter search terms like "mars" or "rebel" in the search bar

OpenSearch Dashboards allows you to explore your data visually and create dashboards and visualizations.

## Clean up resources

When you're done experimenting, delete the domain to avoid incurring charges:

```
aws opensearch delete-domain --domain-name "$DOMAIN_NAME"
```

This command initiates the deletion of your OpenSearch Service domain. The deletion process may take several minutes to complete.

You can verify that the domain has been deleted by running:

```
aws opensearch describe-domain --domain-name "$DOMAIN_NAME"
```

If the domain has been successfully deleted, you'll see a "Domain not found" error.


## Going to production

This tutorial is designed for learning purposes and is not intended for production use. If you're planning to deploy OpenSearch Service in a production environment, consider the following best practices:

### Security best practices

1. **Use specific IAM roles instead of the root user**: The tutorial uses the AWS account root user in the access policy for simplicity. In production, create specific IAM roles with least privilege permissions.

2. **Deploy within a VPC**: For production workloads, deploy your domain within a VPC and use VPC endpoints to restrict access.

3. **Use AWS Secrets Manager for credentials**: Instead of hardcoding credentials, use AWS Secrets Manager to securely store and retrieve credentials.

4. **Implement IP-based restrictions**: Restrict access to your domain to specific IP ranges or VPC CIDR blocks.

### Architecture best practices

1. **Multi-node deployment**: Use multiple data nodes across availability zones for high availability.

2. **Dedicated master nodes**: For larger clusters, use dedicated master nodes to improve cluster stability.

3. **Appropriate instance sizing**: Choose instance types based on your workload requirements rather than using t3.small instances.

4. **Implement monitoring**: Set up CloudWatch alarms and dashboards to monitor your domain's health and performance.

5. **Automated backups**: Configure automated snapshots to protect your data.

For more information on production best practices, see:
- [Amazon OpenSearch Service Best Practices](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/bp.html)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Security in Amazon OpenSearch Service](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/security.html)

## Next steps

Now that you've learned the basics of Amazon OpenSearch Service, you can explore more advanced features:

- [Create and manage indices](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/managing-indices.html) to optimize your data storage and retrieval
- [Set up fine-grained access control](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/fgac.html) to secure your domain
- [Configure domain settings](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/createupdatedomains.html) for production workloads
- [Integrate with other AWS services](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/integrations.html) like Amazon S3, Amazon Kinesis, and AWS Lambda
- [Create visualizations and dashboards](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/dashboards.html) to gain insights from your data

For more information, see the [Amazon OpenSearch Service Developer Guide](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/).
