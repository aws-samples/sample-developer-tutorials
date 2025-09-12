# Working with AWS Direct Connect connections using the AWS CLI

This tutorial guides you through the process of creating and managing AWS Direct Connect connections using the AWS Command Line Interface (AWS CLI). You'll learn how to create a dedicated connection, update its properties, create virtual interfaces, and clean up resources when they're no longer needed.

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI installed and configured with appropriate credentials. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
2. Basic understanding of networking concepts, including BGP routing and VLAN configuration.
3. Sufficient permissions to create and manage AWS Direct Connect resources. Consider using the least-privilege policy provided in the `direct-connect-tutorial-policy.json` file.
4. **Important**: Creating AWS Direct Connect resources will incur costs. A 1 Gbps dedicated connection typically costs around $300 per month, plus data transfer charges. For the most current pricing information, see [AWS Direct Connect pricing](https://aws.amazon.com/directconnect/pricing/).
5. Time to complete the tutorial: approximately 30-45 minutes for the CLI commands, though connection provisioning may take 30+ minutes to several hours on the AWS side.
6. **Patience**: Direct Connect connections require physical provisioning and can take significant time to become available.

## Understanding AWS Direct Connect connections

AWS Direct Connect enables you to establish a dedicated network connection between your network and one of the AWS Direct Connect locations. There are two types of connections:

- **Dedicated Connection**: A physical Ethernet connection associated with a single customer. Available bandwidths are 1 Gbps, 10 Gbps, 100 Gbps, and 400 Gbps.
- **Hosted Connection**: A physical Ethernet connection that an AWS Direct Connect Partner provisions on behalf of a customer. Available bandwidths range from 50 Mbps to 10 Gbps.

In this tutorial, we'll focus on dedicated connections that you can create and manage directly through the AWS CLI.

### Connection States and Timing

Understanding connection states is crucial for working with Direct Connect:

- `requested`: Initial state for dedicated connections (can last 30+ minutes to hours)
- `pending`: Connection approved and being initialized
- `available`: Ready for use (required for creating virtual interfaces)
- `down`: Network link is down
- `rejected`: Connection request was rejected
- `deleted`: Connection has been deleted

**Important**: You cannot create virtual interfaces until the connection is in the `available` state.

## Listing available Direct Connect locations

Before creating a connection, you need to know the available Direct Connect locations in your region. Use the following command to list all available locations:

```bash
aws directconnect describe-locations
```

The output will show all available Direct Connect locations, including their location codes, names, regions, available port speeds, and service providers:

```json
{
    "locations": [
        {
            "locationCode": "EQC50",
            "locationName": "Equinix CH2, Chicago, IL",
            "region": "us-east-2",
            "availablePortSpeeds": [
                "100G",
                "1G",
                "10G"
            ],
            "availableProviders": [
                "Equinix, Inc.",
                "Zayo Group",
                "AT&T",
                "Verizon",
                "CenturyLink"
                // Additional providers omitted for brevity
            ],
            "availableMacSecPortSpeeds": [
                "100G",
                "10G"
            ]
        }
        // Additional locations omitted for brevity
    ]
}
```

Note the `locationCode` value for the location you want to use. You'll need this when creating your connection.

## Creating a dedicated connection

To create a dedicated connection, you need to specify the location code, bandwidth, and a name for your connection. The available bandwidth options are 1 Gbps, 10 Gbps, 100 Gbps, and 400 Gbps.

Use the following command to create a dedicated connection:

```bash
aws directconnect create-connection \
  --location "EQC50" \
  --bandwidth "1Gbps" \
  --connection-name "MyDedicatedConnection"
```

Replace `"EQC50"` with the location code from the previous step, and choose a meaningful name for your connection.

The output will include details about your connection, including the connection ID and state:

```json
{
    "ownerAccount": "123456789012",
    "connectionId": "dxcon-abcd1234",
    "connectionName": "MyDedicatedConnection",
    "connectionState": "requested",
    "region": "us-east-2",
    "location": "EQC50",
    "bandwidth": "1Gbps",
    "jumboFrameCapable": false,
    "hasLogicalRedundancy": "unknown",
    "tags": [],
    "macSecCapable": false
}
```

Make note of the `connectionId` value (e.g., `dxcon-abcd1234`). You'll need this ID for subsequent operations.

**Important**: When you first create a connection, it will be in the `requested` state. AWS needs to process your request and provision the connection, which can take some time (typically 30+ minutes to several hours for a physical connection). During this time, you might receive an email with a request for more information about your use case or the specified location.

## Viewing connection details

You can view the details of your connection using the following command:

```bash
aws directconnect describe-connections --connection-id dxcon-abcd1234
```

Replace `dxcon-abcd1234` with your actual connection ID.

The output will show detailed information about your connection, including its current state:

```json
{
    "connections": [
        {
            "ownerAccount": "123456789012",
            "connectionId": "dxcon-abcd1234",
            "connectionName": "MyDedicatedConnection",
            "connectionState": "requested",
            "region": "us-east-2",
            "location": "EQC50",
            "bandwidth": "1Gbps",
            "jumboFrameCapable": false,
            "hasLogicalRedundancy": "unknown",
            "tags": [],
            "macSecCapable": false
        }
    ]
}
```

### Monitoring Connection State

You can monitor the connection state with a simple loop:

```bash
# Check connection state periodically
while true; do
    STATE=$(aws directconnect describe-connections \
        --connection-id dxcon-abcd1234 \
        --query 'connections[0].connectionState' \
        --output text)
    echo "Connection state: $STATE"
    if [ "$STATE" == "available" ]; then
        echo "Connection is ready!"
        break
    elif [ "$STATE" == "rejected" ] || [ "$STATE" == "deleted" ]; then
        echo "Connection failed with state: $STATE"
        break
    fi
    sleep 30
done
```

## Updating a connection

You can update certain properties of your connection, such as its name or MACsec encryption mode. Use the following command to update the connection name:

```bash
aws directconnect update-connection \
  --connection-id dxcon-abcd1234 \
  --connection-name "NewConnectionName"
```

Replace `dxcon-abcd1234` with your actual connection ID and choose a new name for your connection.

The output will show the updated connection details:

```json
{
    "ownerAccount": "123456789012",
    "connectionId": "dxcon-abcd1234",
    "connectionName": "NewConnectionName",
    "connectionState": "requested",
    "region": "us-east-2",
    "location": "EQC50",
    "bandwidth": "1Gbps",
    "jumboFrameCapable": false,
    "hasLogicalRedundancy": "unknown",
    "macSecCapable": false
}
```

For dedicated connections that support MACsec encryption, you can also update the encryption mode:

```bash
aws directconnect update-connection \
  --connection-id dxcon-abcd1234 \
  --encryption-mode "should_encrypt"
```

The valid encryption mode values are:
- `should_encrypt`: Encryption is preferred but not required.
- `must_encrypt`: Encryption is required; the connection goes down if encryption is down.
- `no_encrypt`: No encryption.

## Downloading the LOA-CFA

After AWS processes your connection request, a Letter of Authorization and Connecting Facility Assignment (LOA-CFA) will be available for download. The LOA-CFA is required by your network provider to order a cross-connect for you.

Use the following command to download the LOA-CFA:

```bash
aws directconnect describe-loa \
  --connection-id dxcon-abcd1234 \
  --output text \
  --query loaContent | base64 --decode > loa-cfa.pdf
```

Replace `dxcon-abcd1234` with your actual connection ID.

**Note**: The LOA-CFA might not be immediately available after creating a connection. If you receive an error, wait a few minutes and try again. The LOA-CFA will be available once AWS begins provisioning your connection. If the LOA-CFA is still not available after 72 hours, contact AWS Support.

### Checking LOA-CFA Availability

You can check if the LOA-CFA is available without downloading it:

```bash
aws directconnect describe-loa --connection-id dxcon-abcd1234 2>&1
```

If you see an error message, the LOA-CFA is not yet available.

## Creating a virtual private gateway

Before creating a private virtual interface, you need to create a virtual private gateway (VGW). The VGW will be used to connect your Direct Connect connection to a VPC.

Use the following command to create a VGW:

```bash
aws ec2 create-vpn-gateway --type ipsec.1
```

The output will include details about the VGW, including its ID:

```json
{
    "VpnGateway": {
        "AmazonSideAsn": 64512,
        "VpnGatewayId": "vgw-abcd1234",
        "State": "pending",
        "Type": "ipsec.1",
        "VpcAttachments": []
    }
}
```

Make note of the `VpnGatewayId` value (e.g., `vgw-abcd1234`). You'll need this ID when creating a private virtual interface.

### Waiting for VGW to Become Available

The VGW must be in the `available` state before you can use it with virtual interfaces. You can monitor its state:

```bash
# Wait for VGW to become available
while true; do
    VGW_STATE=$(aws ec2 describe-vpn-gateways \
        --vpn-gateway-ids vgw-abcd1234 \
        --query 'VpnGateways[0].State' \
        --output text)
    echo "VGW state: $VGW_STATE"
    if [ "$VGW_STATE" == "available" ]; then
        echo "VGW is ready!"
        break
    elif [ "$VGW_STATE" == "failed" ]; then
        echo "VGW failed to become available"
        break
    fi
    sleep 10
done
```

To use the VGW with a VPC, you need to attach it to the VPC:

```bash
aws ec2 attach-vpn-gateway \
  --vpn-gateway-id vgw-abcd1234 \
  --vpc-id vpc-abcd1234
```

Replace `vgw-abcd1234` with your actual VGW ID and `vpc-abcd1234` with your VPC ID.

## Creating a private virtual interface

A private virtual interface allows you to connect to resources in your VPC using private IP addresses. To create a private virtual interface, you need your connection ID, a VLAN ID, your BGP ASN, and the virtual private gateway ID.

**Prerequisites**:
- Connection must be in `available` state
- Virtual private gateway must be in `available` state

Use the following command to create a private virtual interface:

```bash
aws directconnect create-private-virtual-interface \
  --connection-id dxcon-abcd1234 \
  --new-private-virtual-interface '{
      "virtualInterfaceName": "MyPrivateVIF",
      "vlan": 100,
      "asn": 65000,
      "authKey": "myauthkey",
      "amazonAddress": "192.168.1.1/30",
      "customerAddress": "192.168.1.2/30",
      "addressFamily": "ipv4",
      "virtualGatewayId": "vgw-abcd1234"
  }'
```

Replace `dxcon-abcd1234` with your actual connection ID and `vgw-abcd1234` with your actual VGW ID. Choose a unique VLAN ID between 1 and 4094, and specify your BGP ASN (a private ASN between 64512 and 65534 is recommended).

**Important**: You might not be able to create a virtual interface immediately after creating a connection. The connection needs to be in the `available` state first, which can take some time (typically 30+ minutes to several hours for a physical connection).

### Common Error Messages

If you encounter errors when creating virtual interfaces:

- `"The specified Connection ID is not available"`: Connection is not yet in `available` state
- `"The VirtualGateway vgw-xxx is not available"`: VGW is not yet in `available` state
- `"VLAN xxx is already in use"`: Choose a different VLAN ID

The output will include details about your private virtual interface:

```json
{
    "ownerAccount": "123456789012",
    "virtualInterfaceId": "dxvif-abcd1234",
    "location": "EQC50",
    "connectionId": "dxcon-abcd1234",
    "virtualInterfaceType": "private",
    "virtualInterfaceName": "MyPrivateVIF",
    "vlan": 100,
    "asn": 65000,
    "amazonSideAsn": 7224,
    "authKey": "myauthkey",
    "amazonAddress": "192.168.1.1/30",
    "customerAddress": "192.168.1.2/30",
    "addressFamily": "ipv4",
    "virtualInterfaceState": "pending",
    "customerRouterConfig": "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<logical_connection id=\"dxvif-abcd1234\">\n  <vlan>100</vlan>\n  <customer_address>192.168.1.2/30</customer_address>\n  <amazon_address>192.168.1.1/30</amazon_address>\n  <bgp_asn>65000</bgp_asn>\n  <bgp_auth_key>myauthkey</bgp_auth_key>\n  <amazon_bgp_asn>7224</amazon_bgp_asn>\n  <connection_type>private</connection_type>\n</logical_connection>\n",
    "virtualGatewayId": "vgw-abcd1234",
    "directConnectGatewayId": null,
    "routeFilterPrefixes": [],
    "bgpPeers": [],
    "region": "us-east-2",
    "tags": []
}
```

Make note of the `virtualInterfaceId` value (e.g., `dxvif-abcd1234`). You'll need this ID for subsequent operations.

## Creating a public virtual interface

A public virtual interface allows you to connect to AWS public services using public IP addresses. To create a public virtual interface, you need your connection ID, a VLAN ID, your BGP ASN, and the prefixes you want to advertise.

**Important Requirements for Public Virtual Interfaces**:
- You must own the public IP addresses you specify
- The IP addresses cannot be from private ranges (RFC 1918)
- AWS may take up to 72 hours to review and approve public virtual interface requests
- You need to provide proof of IP ownership

**Note**: The following example uses documentation IP ranges that won't work in production. Replace with your actual owned public IP addresses:

```bash
aws directconnect create-public-virtual-interface \
  --connection-id dxcon-abcd1234 \
  --new-public-virtual-interface '{
      "virtualInterfaceName": "MyPublicVIF",
      "vlan": 200,
      "asn": 65000,
      "authKey": "myauthkey",
      "amazonAddress": "YOUR_PUBLIC_IP_1/30",
      "customerAddress": "YOUR_PUBLIC_IP_2/30",
      "addressFamily": "ipv4",
      "routeFilterPrefixes": [
          {"cidr": "YOUR_PUBLIC_CIDR_1/24"},
          {"cidr": "YOUR_PUBLIC_CIDR_2/24"}
      ]
  }'
```

Replace:
- `dxcon-abcd1234` with your actual connection ID
- `YOUR_PUBLIC_IP_1/30` and `YOUR_PUBLIC_IP_2/30` with your owned public IP addresses
- `YOUR_PUBLIC_CIDR_1/24` and `YOUR_PUBLIC_CIDR_2/24` with your owned public CIDR blocks

Choose a unique VLAN ID between 1 and 4094 (different from the one used for the private virtual interface), and specify your BGP ASN.

The `routeFilterPrefixes` parameter specifies the prefixes that you want to advertise over BGP. These should be prefixes that you own.

## Creating a transit virtual interface

A transit virtual interface allows you to connect to one or more Amazon VPC Transit Gateways associated with Direct Connect gateways. To create a transit virtual interface, you need your connection ID, a VLAN ID, your BGP ASN, and the Direct Connect gateway ID.

First, create a Direct Connect gateway:

```bash
aws directconnect create-direct-connect-gateway \
  --direct-connect-gateway-name "MyDCGW" \
  --amazon-side-asn 64512
```

The output will include details about the Direct Connect gateway:

```json
{
    "directConnectGateway": {
        "directConnectGatewayId": "dx-gateway-abcd1234",
        "directConnectGatewayName": "MyDCGW",
        "amazonSideAsn": 64512,
        "ownerAccount": "123456789012",
        "directConnectGatewayState": "pending",
        "stateChangeError": ""
    }
}
```

Make note of the `directConnectGatewayId` value (e.g., `dx-gateway-abcd1234`). You'll need this ID when creating a transit virtual interface.

Now, create a transit virtual interface:

```bash
aws directconnect create-transit-virtual-interface \
  --connection-id dxcon-abcd1234 \
  --new-transit-virtual-interface '{
      "virtualInterfaceName": "MyTransitVIF",
      "vlan": 300,
      "asn": 65000,
      "authKey": "myauthkey",
      "amazonAddress": "192.168.2.1/30",
      "customerAddress": "192.168.2.2/30",
      "addressFamily": "ipv4",
      "directConnectGatewayId": "dx-gateway-abcd1234"
  }'
```

Replace `dxcon-abcd1234` with your actual connection ID and `dx-gateway-abcd1234` with your actual Direct Connect gateway ID. Choose a unique VLAN ID between 1 and 4094 (different from the ones used for other virtual interfaces), and specify your BGP ASN.

## Downloading router configuration

After creating a virtual interface, you can download the router configuration for your network device:

```bash
aws directconnect describe-router-configuration \
  --virtual-interface-id dxvif-abcd1234 \
  --router-type-identifier cisco
```

Replace `dxvif-abcd1234` with your actual virtual interface ID and `cisco` with the appropriate router type for your network device. Supported router types include `cisco`, `juniper`, and others.

## Listing virtual interfaces

You can view all your virtual interfaces using the following command:

```bash
aws directconnect describe-virtual-interfaces
```

To view details for a specific virtual interface, include the virtual interface ID:

```bash
aws directconnect describe-virtual-interfaces --virtual-interface-id dxvif-abcd1234
```

Replace `dxvif-abcd1234` with your actual virtual interface ID.

## Automated Script Example

For a complete automated example that handles timing and error conditions, see the `2-cli-script-v6.sh` script in this repository. The script demonstrates:

- Proper error handling
- Waiting for resources to become available
- Interactive and non-interactive modes
- Resource cleanup
- Production guidance

Run the script with:

```bash
./2-cli-script-v6.sh
```

## Deleting resources

When you no longer need your Direct Connect resources, you should delete them to avoid incurring unnecessary charges.

**Important**: Always delete resources in the correct order to avoid dependency issues.

### Deleting a virtual interface

Before you can delete a connection, you must first delete all virtual interfaces associated with it:

```bash
aws directconnect delete-virtual-interface --virtual-interface-id dxvif-abcd1234
```

Replace `dxvif-abcd1234` with your actual virtual interface ID.

### Deleting a Direct Connect gateway

If you created a Direct Connect gateway, you can delete it when it's no longer needed:

```bash
aws directconnect delete-direct-connect-gateway --direct-connect-gateway-id dx-gateway-abcd1234
```

Replace `dx-gateway-abcd1234` with your actual Direct Connect gateway ID.

### Deleting a connection

After all virtual interfaces have been deleted, you can delete the connection:

```bash
aws directconnect delete-connection --connection-id dxcon-abcd1234
```

Replace `dxcon-abcd1234` with your actual connection ID.

### Deleting a virtual private gateway

If you created a virtual private gateway, you need to detach it from the VPC before deleting it:

```bash
aws ec2 detach-vpn-gateway \
  --vpn-gateway-id vgw-abcd1234 \
  --vpc-id vpc-abcd1234
```

Replace `vgw-abcd1234` with your actual VGW ID and `vpc-abcd1234` with your VPC ID.

Then, delete the VGW:

```bash
aws ec2 delete-vpn-gateway --vpn-gateway-id vgw-abcd1234
```

Replace `vgw-abcd1234` with your actual VGW ID.

## Going to production

This tutorial demonstrates the basic steps for creating and managing AWS Direct Connect connections using the AWS CLI. However, for production environments, consider the following best practices:

### Implement redundancy

For production workloads, implement redundant connections for high availability. AWS recommends using the Direct Connect Resiliency Toolkit to help you implement a resilient architecture with one of the following options:

- **Maximum Resiliency**: Multiple connections terminating on multiple devices across multiple locations.
- **High Resiliency**: Multiple connections terminating on multiple devices in different locations.
- **Development and Test**: Multiple connections terminating on multiple devices in a single location.

### Security considerations

- Use private virtual interfaces whenever possible, and implement appropriate security controls such as network ACLs and security groups for your VPC resources.
- Consider enabling MACsec encryption for dedicated connections that support it.
- Implement proper BGP authentication and routing policies.
- Use least privilege IAM policies for users and roles that need to manage Direct Connect resources.

### Monitor your connections

Use Amazon CloudWatch to monitor your Direct Connect connections and set up alarms for connection state changes. Key metrics to monitor include:

- Connection state
- BGP status
- Bits in/out
- Packets in/out
- Packet drops

### Cost optimization

- Choose the appropriate bandwidth for your needs based on your traffic patterns.
- Consider using Direct Connect Gateway for connecting to multiple VPCs across different regions to reduce the number of required connections.
- For non-critical workloads, consider using AWS Site-to-Site VPN as a backup or alternative to Direct Connect.

### Automation and Infrastructure as Code

- Use AWS CloudFormation or Terraform for infrastructure as code
- Implement proper CI/CD pipelines for network changes
- Use the automated scripts as a foundation for your deployment processes
- Implement proper testing and validation procedures

## Troubleshooting

Here are some common issues you might encounter when working with AWS Direct Connect:

### Connection stays in "requested" state

If your connection remains in the "requested" state for more than 72 hours, contact AWS Support. You might need to provide additional information about your use case or the specified location.

### Cannot create virtual interfaces

If you receive an error when trying to create a virtual interface, check the following:

- The connection must be in the "available" state.
- The virtual private gateway must be in the "available" state (for private VIFs).
- The VLAN ID must be unique across all virtual interfaces on the connection.
- The BGP ASN must be valid (private ASNs are in the range 64512-65534 for 16-bit ASNs).

### BGP session not establishing

If the BGP session is not establishing after creating a virtual interface, check the following:

- Verify that your router configuration matches the configuration provided by AWS.
- Check that the BGP authentication key is correct.
- Ensure that the IP addresses and ASNs are configured correctly on both sides.
- Verify that there are no firewall rules blocking BGP traffic (TCP port 179).

### Public virtual interface issues

Common issues with public virtual interfaces:

- **"Amazon Address is not allowed to contain a private IP"**: You must use public IP addresses that you own
- **Long approval times**: AWS may take up to 72 hours to review public VIF requests
- **IP ownership verification**: You may need to provide proof of IP ownership

### Timing and State Issues

- **Resource not available**: Wait for dependencies to reach the correct state
- **Connection provisioning delays**: Physical connections can take 30+ minutes to several hours
- **LOA-CFA not available**: Wait for AWS to begin provisioning your connection

## Next steps

Now that you've learned how to create and manage AWS Direct Connect connections using the AWS CLI, you might want to explore the following topics:

- [Working with Direct Connect gateways](https://docs.aws.amazon.com/directconnect/latest/UserGuide/direct-connect-gateways.html)
- [Configuring routing for Direct Connect](https://docs.aws.amazon.com/directconnect/latest/UserGuide/routing-and-bgp.html)
- [Implementing Direct Connect resiliency](https://docs.aws.amazon.com/directconnect/latest/UserGuide/resiliency_toolkit.html)
- [Monitoring Direct Connect resources](https://docs.aws.amazon.com/directconnect/latest/UserGuide/monitoring-overview.html)
- [Using Transit Gateway with Direct Connect](https://docs.aws.amazon.com/directconnect/latest/UserGuide/direct-connect-transit-gateways.html)
