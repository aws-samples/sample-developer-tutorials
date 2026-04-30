# Shared tutorial VPC

Creates a shared VPC with public and private subnets used by tutorials that need networking infrastructure. Tutorials check for this stack automatically.

## Deploy

```bash
bash tuts/000-prereqs-vpc/prereqs-vpc.sh
```

## Clean up

```bash
bash tuts/000-prereqs-vpc/cleanup-prereqs-vpc.sh
```

## Resources created

- VPC with public and private subnets
- Internet gateway, NAT gateway
- Route tables, security groups
- CloudFormation stack `tutorial-prereqs-vpc-public`

## Used by

Tutorials that create VPCs or need networking:
002, 008, 012, 015, 047, 055, 064, 075
