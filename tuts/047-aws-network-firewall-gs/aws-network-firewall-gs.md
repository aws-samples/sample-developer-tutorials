# Getting started with AWS Network Firewall using the AWS CLI

This tutorial guides you through setting up AWS Network Firewall using the AWS Command Line Interface (AWS CLI). Network Firewall provides network traffic filtering protection for your Amazon Virtual Private Cloud (VPC).

## Topics

- [Prerequisites](#prerequisites)
- [Create rule groups](#create-rule-groups)
- [Create a firewall policy](#create-a-firewall-policy)
- [Create a firewall](#create-a-firewall)
- [Update route tables](#update-route-tables)
- [Clean up resources](#clean-up-resources)
- [Going to production](#going-to-production)
- [Next steps](#next-steps)

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI installed and configured with appropriate permissions. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
2. A test VPC with the following configuration:
   * An internet gateway
   * A customer subnet with routing to the internet gateway
   * A second subnet to use as the firewall subnet (must have at least one available IP address)
   * Routing configured to send traffic between the internet gateway and customer subnet

3. Sufficient permissions to create and manage Network Firewall resources and modify VPC route tables.

### Cost considerations

The resources you create in this tutorial will incur the following approximate costs if left running:

- Network Firewall Endpoint: $0.395 per hour in US East (N. Virginia)
- Network Firewall Traffic Processing: $0.065 per GB processed in US East (N. Virginia)

For a firewall running continuously for a month (730 hours) with 100 GB of traffic, the cost would be approximately $295. Prices may vary by region. This tutorial includes cleanup instructions to help you avoid ongoing charges.

### Best practices for CLI operations

When working with Network Firewall resources using the CLI, consider these best practices:

- **Use unique resource names**: Generate unique identifiers for your resources to avoid naming conflicts. For example, append a random string to resource names like `StatelessRuleGroup-abcd1234`.
- **Implement proper error handling**: Check the exit status of commands and handle failures appropriately.
- **Wait for resource readiness**: Always wait for resources to reach the appropriate state before proceeding to dependent operations.
- **Use timeouts**: Implement timeouts for long-running operations to avoid indefinite waits.

For information about managing subnets and route tables in your VPC, see [VPCs and subnets](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html) and [Route tables](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Route_Tables.html) in the Amazon Virtual Private Cloud User Guide.

## Create rule groups

Rule groups are reusable collections of network filtering rules that you use to configure firewall behavior. In this step, you'll create a stateless rule group and a stateful rule group.

**Create a stateless rule group**

The following command creates a stateless rule group that blocks all packets coming from the source IP address CIDR range 192.0.2.0/24:

```bash
aws network-firewall create-rule-group \
  --rule-group-name "StatelessRuleGroup-abcd1234" \
  --type STATELESS \
  --capacity 10 \
  --rule-group '{"RulesSource": {"StatelessRulesAndCustomActions": {"StatelessRules": [{"RuleDefinition": {"MatchAttributes": {"Sources": [{"AddressDefinition": "192.0.2.0/24"}], "Destinations": [], "SourcePorts": [], "DestinationPorts": [], "Protocols": []}, "Actions": ["aws:drop"]}, "Priority": 10}]}}}' \
  --description "Stateless rule group example"
```

The command specifies a rule group name, type (STATELESS), capacity (10), and a rule definition. The rule definition includes a source IP address range to block and the action to take (drop the packets).

**Create a stateful rule group**

Next, create a stateful rule group with a Suricata-compatible rule that drops TLS traffic for a specific target domain:

```bash
aws network-firewall create-rule-group \
  --rule-group-name "StatefulRuleGroup-abcd1234" \
  --type STATEFUL \
  --capacity 10 \
  --rule-group '{"RulesSource": {"RulesString": "drop tls $HOME_NET any -> $EXTERNAL_NET any (ssl_state:client_hello; tls.sni; content:\"evil.com\"; startswith; nocase; endswith; msg:\"matching TLS denylisted FQDNs\"; priority:1; flow:to_server, established; sid:1; rev:1;)"}}' \
  --description "Stateful rule group example"
```

This command creates a stateful rule group that uses a Suricata-compatible rule to inspect TLS traffic and drop connections to "evil.com".

**Get the rule group ARNs**

After creating the rule groups, you need to retrieve their Amazon Resource Names (ARNs) to use them in a firewall policy:

```bash
STATELESS_RULE_GROUP_ARN=$(aws network-firewall describe-rule-group \
  --rule-group-name StatelessRuleGroup-abcd1234 \
  --type STATELESS \
  --query "RuleGroup.RuleGroupArn" \
  --output text)

STATEFUL_RULE_GROUP_ARN=$(aws network-firewall describe-rule-group \
  --rule-group-name StatefulRuleGroup-abcd1234 \
  --type STATEFUL \
  --query "RuleGroup.RuleGroupArn" \
  --output text)

echo "Stateless Rule Group ARN: $STATELESS_RULE_GROUP_ARN"
echo "Stateful Rule Group ARN: $STATEFUL_RULE_GROUP_ARN"
```

These commands retrieve the ARNs for both rule groups and store them in variables for use in the next step.

## Create a firewall policy

A firewall policy defines the traffic filtering behavior for a firewall by referencing rule groups and specifying default actions. In this step, you'll create a policy using the rule groups you created earlier.

```bash
aws network-firewall create-firewall-policy \
  --firewall-policy-name "FirewallPolicy-abcd1234" \
  --firewall-policy '{
    "StatelessDefaultActions": ["aws:forward_to_sfe"],
    "StatelessFragmentDefaultActions": ["aws:forward_to_sfe"],
    "StatelessRuleGroupReferences": [
      {
        "ResourceArn": "'"$STATELESS_RULE_GROUP_ARN"'",
        "Priority": 100
      }
    ],
    "StatefulRuleGroupReferences": [
      {
        "ResourceArn": "'"$STATEFUL_RULE_GROUP_ARN"'"
      }
    ]
  }' \
  --description "Firewall policy example"
```

This command creates a firewall policy that:
- References both the stateless and stateful rule groups you created
- Sets the default action for stateless traffic to forward packets to the stateful engine (`aws:forward_to_sfe`)
- Sets the same default action for packet fragments
- Assigns a priority of 100 to the stateless rule group (required parameter)

**Get the firewall policy ARN**

After creating the firewall policy, retrieve its ARN:

```bash
FIREWALL_POLICY_ARN=$(aws network-firewall describe-firewall-policy \
  --firewall-policy-name FirewallPolicy-abcd1234 \
  --query "FirewallPolicyResponse.FirewallPolicyArn" \
  --output text)

echo "Firewall Policy ARN: $FIREWALL_POLICY_ARN"
```

This command retrieves the ARN of your firewall policy and stores it in a variable for use in the next step.

## Create a firewall

A firewall associates the traffic filtering behavior of a firewall policy with a VPC where you want to filter traffic. In this step, you'll create a firewall using the firewall policy you created earlier.

**Select your VPC and subnet**

Before creating the firewall, you need to identify the VPC and subnet where you want to deploy it. You can list your available VPCs and subnets using these commands:

```bash
# List available VPCs
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0],CidrBlock,State]' --output table

# List available subnets in a specific VPC
VPC_ID="vpc-abcd1234"  # Replace with your VPC ID
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[*].[SubnetId,Tags[?Key==`Name`].Value|[0],CidrBlock,AvailabilityZone,State]' --output table
```

**Create the firewall**

```bash
# Replace these values with your actual VPC and subnet IDs
VPC_ID="vpc-abcd1234"
SUBNET_ID="subnet-abcd1234"

aws network-firewall create-firewall \
  --firewall-name "Firewall-abcd1234" \
  --firewall-policy-arn "$FIREWALL_POLICY_ARN" \
  --vpc-id "$VPC_ID" \
  --subnet-mappings "SubnetId=$SUBNET_ID"
```

This command creates a firewall in your VPC using the specified subnet for the firewall endpoint. The firewall uses the policy you created to determine its traffic filtering behavior.

**Wait for the firewall to be ready**

After creating the firewall, you need to wait for it to be ready before proceeding:

```bash
echo "Waiting for firewall to be ready..."

# Check the firewall status repeatedly until ready
while true; do
  STATUS=$(aws network-firewall describe-firewall \
    --firewall-name "Firewall-abcd1234" \
    --query "FirewallStatus.Status" \
    --output text)

  if [ "$STATUS" = "READY" ]; then
    echo "Firewall is ready!"
    break
  fi

  echo "Firewall not ready yet (status: $STATUS), waiting 20 seconds..."
  sleep 20
done
```

**Get the firewall endpoint ID**

Once the firewall is ready, retrieve the firewall endpoint ID. The endpoint ID is located within the availability zone-specific sync states:

```bash
# Get the firewall description to find available zones
FIREWALL_OUTPUT=$(aws network-firewall describe-firewall --firewall-name "Firewall-abcd1234")

# Extract the first availability zone that has an endpoint
AZ_NAME=$(echo "$FIREWALL_OUTPUT" | grep -o '"us-[^"]*"' | head -1 | tr -d '"')

# Get the endpoint ID for that availability zone
FIREWALL_ENDPOINT=$(aws network-firewall describe-firewall \
  --firewall-name "Firewall-abcd1234" \
  --query "FirewallStatus.SyncStates.\"$AZ_NAME\".Attachment.EndpointId" \
  --output text)

echo "Firewall endpoint ID: $FIREWALL_ENDPOINT"
```

These commands check the status of the firewall in a loop until it's ready, then retrieve the firewall endpoint ID from the correct location in the JSON response structure. The endpoint ID is nested within availability zone-specific sync states, so you need to identify the availability zone first.

## Update route tables

After creating your firewall, you need to update your route tables to direct traffic through the firewall endpoint. This involves creating a route table for the firewall endpoint and updating the route tables for your internet gateway and customer subnet.

**Identify your route tables and internet gateway**

Before updating routes, identify the route tables and internet gateway in your VPC:

```bash
# List route tables in your VPC
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --query 'RouteTables[*].[RouteTableId,Tags[?Key==`Name`].Value|[0],Associations[0].Main]' --output table

# List internet gateways attached to your VPC
aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query 'InternetGateways[*].[InternetGatewayId,Tags[?Key==`Name`].Value|[0],State]' --output table
```

**Create a route table for the firewall endpoint**

```bash
# Replace these values with your actual route table IDs and CIDR block
IGW_ROUTE_TABLE_ID="rtb-abcd1234"        # Route table associated with internet gateway
SUBNET_ROUTE_TABLE_ID="rtb-5678efgh"     # Route table associated with customer subnet
CUSTOMER_SUBNET_CIDR="10.0.1.0/24"      # CIDR block of your customer subnet
INTERNET_GATEWAY_ID="igw-abcd1234"       # Your internet gateway ID

# Create a route table for the firewall endpoint
FIREWALL_ROUTE_TABLE_ID=$(aws ec2 create-route-table \
  --vpc-id "$VPC_ID" \
  --query "RouteTable.RouteTableId" \
  --output text)

echo "Firewall route table ID: $FIREWALL_ROUTE_TABLE_ID"
```

This command creates a new route table for the firewall endpoint in your VPC.

**Add routes to the firewall route table**

```bash
# Add route to the customer subnet
aws ec2 create-route \
  --route-table-id "$FIREWALL_ROUTE_TABLE_ID" \
  --destination-cidr-block "$CUSTOMER_SUBNET_CIDR" \
  --vpc-endpoint-id "$FIREWALL_ENDPOINT"

# Add route to the internet
aws ec2 create-route \
  --route-table-id "$FIREWALL_ROUTE_TABLE_ID" \
  --destination-cidr-block "0.0.0.0/0" \
  --gateway-id "$INTERNET_GATEWAY_ID"
```

These commands add routes to the firewall route table to direct traffic between the internet gateway and your customer subnet.

**Update the internet gateway route table**

```bash
aws ec2 create-route \
  --route-table-id "$IGW_ROUTE_TABLE_ID" \
  --destination-cidr-block "$CUSTOMER_SUBNET_CIDR" \
  --vpc-endpoint-id "$FIREWALL_ENDPOINT"
```

This command updates the internet gateway route table to send traffic destined for your customer subnet through the firewall endpoint.

**Update the customer subnet route table**

```bash
aws ec2 create-route \
  --route-table-id "$SUBNET_ROUTE_TABLE_ID" \
  --destination-cidr-block "0.0.0.0/0" \
  --vpc-endpoint-id "$FIREWALL_ENDPOINT"
```

This command updates the customer subnet route table to send outbound traffic through the firewall endpoint.

After completing these steps, the firewall endpoint is filtering all traffic between your internet gateway and customer subnet.

## Clean up resources

When you're finished with this tutorial, you should clean up the resources you created to avoid incurring additional charges.

**Restore original route tables**

Before deleting Network Firewall resources, you need to restore your original routing configuration:

```bash
# Remove firewall route from internet gateway route table
aws ec2 delete-route \
  --route-table-id "$IGW_ROUTE_TABLE_ID" \
  --destination-cidr-block "$CUSTOMER_SUBNET_CIDR"

# Remove firewall route from customer subnet route table
aws ec2 delete-route \
  --route-table-id "$SUBNET_ROUTE_TABLE_ID" \
  --destination-cidr-block "0.0.0.0/0"

# Restore original internet route for customer subnet
aws ec2 create-route \
  --route-table-id "$SUBNET_ROUTE_TABLE_ID" \
  --destination-cidr-block "0.0.0.0/0" \
  --gateway-id "$INTERNET_GATEWAY_ID"

# Delete the firewall route table
aws ec2 delete-route-table --route-table-id "$FIREWALL_ROUTE_TABLE_ID"
```

These commands remove the firewall-specific routes and restore your original route table configurations, then delete the firewall route table.

**Delete Network Firewall resources**

```bash
# Delete the firewall
aws network-firewall delete-firewall --firewall-name "Firewall-abcd1234"

# Wait for the firewall to be deleted before proceeding
echo "Waiting for firewall to be deleted..."
while aws network-firewall describe-firewall --firewall-name "Firewall-abcd1234" 2>/dev/null; do
  echo "Firewall still exists, waiting 10 seconds..."
  sleep 10
done
echo "Firewall deleted successfully."

# Delete the firewall policy
aws network-firewall delete-firewall-policy --firewall-policy-name "FirewallPolicy-abcd1234"

# Delete the rule groups
aws network-firewall delete-rule-group --rule-group-name "StatelessRuleGroup-abcd1234" --type STATELESS
aws network-firewall delete-rule-group --rule-group-name "StatefulRuleGroup-abcd1234" --type STATEFUL
```

These commands delete all the Network Firewall resources you created in this tutorial. The script waits for the firewall to be completely deleted before proceeding with the deletion of dependent resources.

## Going to production

This tutorial demonstrates the basic functionality of AWS Network Firewall using the AWS CLI. For production environments, consider the following additional best practices:

### High availability

For production workloads, deploy Network Firewall endpoints in multiple Availability Zones to ensure high availability. The tutorial creates a firewall in a single Availability Zone, which doesn't provide redundancy.

### Security considerations

- Enable logging for your Network Firewall to capture traffic information for security monitoring and incident response
- Implement more comprehensive rule sets based on your specific security requirements
- Consider using advanced features like TLS inspection and active threat defense managed rule groups

### Architecture best practices

- For organizations with multiple VPCs, consider implementing a centralized inspection VPC with Network Firewall
- Use infrastructure as code (AWS CloudFormation, AWS CDK, or Terraform) to define and deploy Network Firewall resources
- Implement automated rule updates and testing

For more information on building production-ready architectures with AWS Network Firewall, see:

- [AWS Network Firewall example architectures with routing](https://docs.aws.amazon.com/network-firewall/latest/developerguide/architectures.html)
- [AWS Security Reference Architecture](https://docs.aws.amazon.com/prescriptive-guidance/latest/security-reference-architecture/welcome.html)
- [AWS Well-Architected Framework - Security Pillar](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html)

## Next steps

Now that you've learned how to set up AWS Network Firewall using the AWS CLI, you can explore more advanced features:

1. **Logging and monitoring** - [Configure logging for your firewall](https://docs.aws.amazon.com/network-firewall/latest/developerguide/logging.html) to capture traffic information.
2. **Custom rule groups** - [Create more complex rule groups](https://docs.aws.amazon.com/network-firewall/latest/developerguide/rule-groups.html) to implement your security policies.
3. **Multiple firewall endpoints** - [Deploy firewalls across multiple Availability Zones](https://docs.aws.amazon.com/network-firewall/latest/developerguide/architectures.html) for high availability.
4. **TLS inspection** - [Configure TLS inspection](https://docs.aws.amazon.com/network-firewall/latest/developerguide/tls-inspection.html) to inspect encrypted traffic.
5. **Integration with other AWS services** - [Use Network Firewall with AWS Transit Gateway](https://docs.aws.amazon.com/network-firewall/latest/developerguide/arch-tgw-centralfirewall.html) for centralized network security.

For more information about available AWS CLI commands for Network Firewall, see the [AWS CLI Command Reference for Network Firewall](https://docs.aws.amazon.com/cli/latest/reference/network-firewall/index.html).
