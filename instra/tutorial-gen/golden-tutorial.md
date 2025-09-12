# Using Amazon Lightsail with the AWS CLI

This tutorial guides you through common Amazon Lightsail operations using the AWS Command Line Interface (AWS CLI). You'll learn how to create and manage Lightsail resources including key pairs, instances, storage, and snapshots.

## Topics

- [Prerequisites](#getstarted-awscli-prerequisites)
- [Generate SSH key pairs](#getstarted-awscli-generate-ssh-key-pairs)
- [Create and manage instances](#getstarted-awscli-create-and-manage-instances)
- [Connect to your instance](#getstarted-awscli-connect-to-your-instance)
- [Add storage to your instance](#getstarted-awscli-add-storage-to-your-instance)
- [Create and use snapshots](#getstarted-awscli-create-and-use-snapshots)
- [Clean up resources](#getstarted-awscli-clean-up-resources)
- [Next steps](#getstarted-awscli-next-steps)

## Prerequisites

Before you begin this tutorial, make sure you have the following.

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html). You can also [use AWS CloudShell](https://docs.aws.amazon.com/lightsail/latest/userguide/amazon-lightsail-cloudshell.html), which includes the AWS CLI.
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. Basic familiarity with command line interfaces and SSH concepts.
4. [Sufficient permissions](https://docs.aws.amazon.com/lightsail/latest/userguide/security_iam_service-with-iam.html) to create and manage Lightsail resources in your AWS account.

Before you start, set the `AWS_REGION` environment variable to the same Region that you configured the AWS CLI to use, if it's not already set This environment variable is used in example commands to specify an availability zone for Lightsail resources.

```
$ [ -z "${AWS_REGION}" ] && export AWS_REGION=$(aws configure get region)
```

Let's get started with creating and managing Amazon Lightsail resources using the CLI.

## Generate SSH key pairs

SSH key pairs allow you to securely connect to your Lightsail instances without using passwords. In this section, you'll create a new key pair and retrieve its information.

**Create a new key pair**

The following command creates a new SSH key pair named "cli-tutorial-keys" and saves the private key to your local machine.

```
$ aws lightsail create-key-pair --key-pair-name cli-tutorial-keys \
        --query privateKeyBase64 --output text > ~/.ssh/cli-tutorial-keys.pem
$ chmod 400 ~/.ssh/cli-tutorial-keys.pem
```

After running this command, the private key is saved to your `~/.ssh` directory with appropriate permissions. The `chmod` command ensures that only you can read the private key file, which is a security requirement for SSH.

**Retrieve key pair information**

You can verify your key pair was created successfully by retrieving its information.

```
$ aws lightsail get-key-pair --key-pair-name cli-tutorial-keys
{
    "keyPair": {
        "name": "cli-tutorial-keys",
        "arn": "arn:aws:lightsail:us-east-2:123456789012:KeyPair/e00xmpl-6a6a-434a-bff1-87f2bb815e21",
        "supportCode": "123456789012/cli-tutorial-keys",
        "createdAt": 1673596800.000,
        "location": {
            "availabilityZone": "all",
            "regionName": "us-east-2"
        },
        "resourceType": "KeyPair",
        "tags": [],
        "fingerprint": "d0:0d:30:db:5a:24:df:f6:17:f0:e2:15:45:77:3d:bb:d0:6d:fc:81"
    }
}
```

The output shows details about your key pair, including its name, ARN, creation time, Region, and fingerprint. This fingerprint can be used to verify the key's authenticity when connecting to instances.
## Create and manage instances

Lightsail instances are virtual private servers that run applications or websites. In this section, you'll create a WordPress instance and retrieve its details.

**Create a WordPress instance**

The following command creates a new WordPress instance using the `nano_3_0` bundle (the smallest Lightsail instance size) and associates it with your key pair. The command uses the `AWS_REGION` environment variable to create the instance in an availability zone in your configured Region.

```
$ aws lightsail create-instances --instance-names cli-tutorial \
        --availability-zone ${AWS_REGION}a --blueprint-id wordpress \
        --bundle-id nano_3_0 --key-pair-name cli-tutorial-keys
{
    "operations": [
        {
            "id": "f30xmpl-3727-492a-9d42-5c94ad3ef9a8",
            "resourceName": "cli-tutorial",
            "resourceType": "Instance",
            "createdAt": 1673596800.000,
            "location": {
                "availabilityZone": "us-east-2a",
                "regionName": "us-east-2"
            },
            "isTerminal": false,
            "operationType": "CreateInstance",
            "status": "Started",
            "statusChangedAt": 1673596800.000
        }
    ]
}
```

The response indicates that the instance creation operation has started. It may take a few minutes for your instance to become available.

**Get instance details**

Once your instance is created, you can retrieve its details using the following command.

```
$ aws lightsail get-instance --instance-name cli-tutorial
{
    "instance": {
        "name": "cli-tutorial",
        "arn": "arn:aws:lightsail:us-east-2:123456789012:Instance/7d3xmpl-ae2e-44d5-bbd9-22f9ec2abe1f",
        "supportCode": "123456789012/i-099cxmpl5dad5923c",
        "createdAt": 1673596800.000,
        "location": {
            "availabilityZone": "us-east-2a",
            "regionName": "us-east-2"
        },
        "resourceType": "Instance",
        "tags": [],
        "blueprintId": "wordpress",
        "blueprintName": "WordPress",
        "bundleId": "nano_3_0",
        "isStaticIp": false,
        "privateIpAddress": "172.26.6.136",
        "publicIpAddress": "203.0.113.75",
        "ipv6Addresses": [
            "2600:1f14:ab4:3800:ceef:89e2:f57:f25"
        ],
        "ipAddressType": "dualstack",
        "hardware": {
            "cpuCount": 2,
            "disks": [
                {
                    "createdAt": 1673596800.000,
                    "sizeInGb": 20,
                    "isSystemDisk": true,
                    "iops": 100,
                    "path": "/dev/xvda",
                    "attachedTo": "cli-tutorial",
                    "attachmentState": "attached"
                }
            ],
            "ramSizeInGb": 0.5
        },
        "networking": {
            "monthlyTransfer": {
                "gbPerMonthAllocated": 1024
            },
            "ports": [
                {
                    "fromPort": 80,
                    "toPort": 80,
                    "protocol": "tcp",
                    "accessFrom": "Anywhere (0.0.0.0/0 and ::/0)",
                    "accessType": "public",
                    "commonName": "",
                    "accessDirection": "inbound",
                    "cidrs": [
                        "0.0.0.0/0"
                    ],
                    "ipv6Cidrs": [
                        "::/0"
                    ],
                    "cidrListAliases": []
                },
                {
                    "fromPort": 22,
                    "toPort": 22,
                    "protocol": "tcp",
                    "accessFrom": "Anywhere (0.0.0.0/0 and ::/0)",
                    "accessType": "public",
                    "commonName": "",
                    "accessDirection": "inbound",
                    "cidrs": [
                        "0.0.0.0/0"
                    ],
                    "ipv6Cidrs": [
                        "::/0"
                    ],
                    "cidrListAliases": []
                },
                {
                    "fromPort": 443,
                    "toPort": 443,
                    "protocol": "tcp",
                    "accessFrom": "Anywhere (0.0.0.0/0 and ::/0)",
                    "accessType": "public",
                    "commonName": "",
                    "accessDirection": "inbound",
                    "cidrs": [
                        "0.0.0.0/0"
                    ],
                    "ipv6Cidrs": [
                        "::/0"
                    ],
                    "cidrListAliases": []
                }
            ]
        },
        "state": {
            "code": 16,
            "name": "running"
        },
        "username": "bitnami",
        "sshKeyName": "cli-tutorial-keys",
        "metadataOptions": {
            "state": "applied",
            "httpTokens": "optional",
            "httpEndpoint": "enabled",
            "httpPutResponseHopLimit": 1,
            "httpProtocolIpv6": "disabled"
        }
    }
}
```

The output provides comprehensive information about your instance, including its IP addresses, hardware specifications, networking configuration, and state. Note the public IP address and username, as you'll need these to connect to your instance.
## Connect to your instance

After creating your instance, you can connect to it using SSH with the key pair you created earlier. This section shows you how to establish an SSH connection and manage security settings.

**SSH into your instance**

Use the following command to connect to your instance via SSH, replacing the IP address with your instance's public IP.

```
$ ssh -i ~/.ssh/cli-tutorial-keys.pem bitnami@203.0.113.75
Linux ip-172-26-6-136 6.1.0-32-cloud-amd64 #1 SMP PREEMPT_DYNAMIC Debian 6.1.129-1 (2025-03-06) x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
       ___ _ _                   _
      | _ |_) |_ _ _  __ _ _ __ (_)
      | _ \ |  _| ' \/ _` | '  \| |
      |___/_|\__|_|_|\__,_|_|_|_|_|

  *** Welcome to the Bitnami package for WordPress 6.7.2           ***
  *** Documentation:  https://docs.bitnami.com/aws/apps/wordpress/ ***
  ***                 https://docs.bitnami.com/aws/                ***
  *** Bitnami Forums: https://github.com/bitnami/vms/              ***
  
bitnami@ip-172-26-6-136:~$ df
Filesystem      1K-blocks    Used Available Use% Mounted on
udev               217920       0    217920   0% /dev
tmpfs               45860     480     45380   2% /run
/dev/nvme0n1p1   20403592 3328832  16142256  18% /
tmpfs              229292       0    229292   0% /dev/shm
tmpfs                5120       0      5120   0% /run/lock
/dev/nvme0n1p15    126678   11840    114838  10% /boot/efi
tmpfs               45856       0     45856   0% /run/user/1000
```

Once connected, you can manage your WordPress installation, configure your server, or install additional software. The example above shows the disk usage on the instance using the `df` command.

**Close public ports**

When you are not using SSH, you can close the public ports on your instance. This helps protect your instance from unauthorized access attempts.

```
$ aws lightsail close-instance-public-ports --instance-name cli-tutorial \
        --port-info fromPort=22,protocol=TCP,toPort=22
{
    "operation": {
        "id": "6cdxmpl-9f39-4357-a66d-230096140b4f",
        "resourceName": "cli-tutorial",
        "resourceType": "Instance",
        "createdAt": 1673596800.000,
        "location": {
            "availabilityZone": "us-east-2a",
            "regionName": "us-east-2"
        },
        "isTerminal": true,
        "operationDetails": "22/tcp",
        "operationType": "CloseInstancePublicPorts",
        "status": "Succeeded",
        "statusChangedAt": 1673596800.000
    }
}
```

> **Note**
>
> Closing port 22 prevents all SSH connections, including those initiated from the Lightsail console. For more information, see the following topics.
>
> * [Manage SSH key pairs and connect to your Lightsail instances](https://docs.aws.amazon.com/lightsail/latest/userguide/understanding-ssh-in-amazon-lightsail.html)
> * [Control instance traffic with firewalls in Lightsail](https://docs.aws.amazon.com/lightsail/latest/userguide/understanding-firewall-and-port-mappings-in-amazon-lightsail.html)

The response confirms that port 22 has been closed successfully. When you need to reconnect via SSH, you can reopen the port using the `open-instance-public-ports` command.
## Add storage to your instance

As your application grows, you might need additional storage space. Lightsail allows you to create and attach additional disks to your instances. This section demonstrates how to add extra storage.

**Create a disk**

The following command creates a new 32GB disk.

```
$ aws lightsail create-disk --disk-name cli-tutorial-disk \
        --availability-zone ${AWS_REGION}a --size-in-gb 32
{
    "operations": [
        {
            "id": "070xmpl-3364-4aa2-bff2-3c589de832fc",
            "resourceName": "cli-tutorial-disk",
            "resourceType": "Disk",
            "createdAt": 1673596800.000,
            "location": {
                "availabilityZone": "us-east-2a",
                "regionName": "us-east-2"
            },
            "isTerminal": false,
            "operationType": "CreateDisk",
            "status": "Started",
            "statusChangedAt": 1673596800.000
        }
    ]
}
```

The response indicates that the disk creation operation has started. It may take a few moments for the disk to become available.

**Attach the disk to your instance**

Once the disk is created, you can attach it to your instance using the following command.

```
$ aws lightsail attach-disk --disk-name cli-tutorial-disk \
        --disk-path /dev/xvdf --instance-name cli-tutorial
{
    "operations": [
        {
            "id": "d17xmpl-2bdb-4292-ac63-ba5537522cea",
            "resourceName": "cli-tutorial-disk",
            "resourceType": "Disk",
            "createdAt": 1673596800.000,
            "location": {
                "availabilityZone": "us-east-2a",
                "regionName": "us-east-2"
            },
            "isTerminal": false,
            "operationDetails": "cli-tutorial",
            "operationType": "AttachDisk",
            "status": "Started",
            "statusChangedAt": 1673596800.000
        },
        {
            "id": "01exmpl-c04e-42d4-aa6b-45ce50562a54",
            "resourceName": "cli-tutorial",
            "resourceType": "Instance",
            "createdAt": 1673596800.000,
            "location": {
                "availabilityZone": "us-east-2a",
                "regionName": "us-east-2"
            },
            "isTerminal": false,
            "operationDetails": "cli-tutorial-disk",
            "operationType": "AttachDisk",
            "status": "Started",
            "statusChangedAt": 1673596800.000
        }
    ]
}
```

The disk-path parameter specifies where the disk will be attached in the Linux file system. After attaching the disk, you'll need to format and mount it from within your instance.

**Verify disk attachment**

You can confirm that the disk is properly attached by retrieving its details.

```
$ aws lightsail get-disk --disk-name cli-tutorial-disk
{
    "disk": {
        "name": "cli-tutorial-disk",
        "arn": "arn:aws:lightsail:us-east-2:123456789012:Disk/1a9xmpl-8a34-46a4-b87e-19184f0cca9c",
        "supportCode": "123456789012/vol-0dacxmplc1c3108e2",
        "createdAt": 1673596800.000,
        "location": {
            "availabilityZone": "us-east-2a",
            "regionName": "us-east-2"
        },
        "resourceType": "Disk",
        "tags": [],
        "sizeInGb": 32,
        "isSystemDisk": false,
        "iops": 100,
        "path": "/dev/xvdf",
        "state": "in-use",
        "attachedTo": "cli-tutorial",
        "isAttached": true,
        "attachmentState": "attached"
    }
}
```

The output confirms that the disk is attached to your instance. The "state" field shows "in-use" and "isAttached" is set to true, indicating a successful attachment.
## Create and use snapshots

Snapshots provide a way to back up your instance and create new instances from the backup. This is useful for disaster recovery, testing, or creating duplicate environments.

**Create an instance snapshot**

The following command creates a snapshot of your instance.

```
$ aws lightsail create-instance-snapshot --instance-name cli-tutorial \
         --instance-snapshot-name cli-tutorial-snapshot
{
    "operations": [
        {
            "id": "41bxmpl-7824-4591-bfcc-1b1c341613a4",
            "resourceName": "cli-tutorial-snapshot",
            "resourceType": "InstanceSnapshot",
            "createdAt": 1673596800.000,
            "location": {
                "availabilityZone": "all",
                "regionName": "us-east-2"
            },
            "isTerminal": false,
            "operationDetails": "cli-tutorial",
            "operationType": "CreateInstanceSnapshot",
            "status": "Started",
            "statusChangedAt": 1673596800.000
        },
        {
            "id": "725xmpl-158e-46f6-bd49-27b0e6805aa2",
            "resourceName": "cli-tutorial",
            "resourceType": "Instance",
            "createdAt": 1673596800.000,
            "location": {
                "availabilityZone": "us-east-2a",
                "regionName": "us-east-2"
            },
            "isTerminal": false,
            "operationDetails": "cli-tutorial-snapshot",
            "operationType": "CreateInstanceSnapshot",
            "status": "Started",
            "statusChangedAt": 1673596800.000
        }
    ]
}
```

The response indicates that the snapshot process has started. There is one asynchronous operation for the instance getting the snapshot, and one for the snapshot being created. The snapshot includes all disks attached to the instance.

**Create a new instance from a snapshot**

Once the snapshot is complete, you can use it to create a new instance.

```
$ aws lightsail create-instances-from-snapshot --availability-zone ${AWS_REGION}b \
        --instance-snapshot-name cli-tutorial-snapshot --instance-name cli-tutorial-bup --bundle-id small_3_0
{
    "operations": [
        {
            "id": "a35xmpl-efa1-4d6c-958e-9d58fd258f5f",
            "resourceName": "cli-tutorial-bup",
            "resourceType": "Instance",
            "createdAt": 1673596800.000,
            "location": {
                "availabilityZone": "us-east-2b",
                "regionName": "us-east-2"
            },
            "isTerminal": false,
            "operationType": "CreateInstancesFromSnapshot",
            "status": "Started",
            "statusChangedAt": 1673596800.000
        }
    ]
}
```

This command creates a new instance named `cli-tutorial-bup` in availability zone `us-east-2b` using the `small_3_0` bundle size. Note that you can choose a different bundle size for the new instance, which can be useful for scaling up or down.
## Clean up resources

When you're finished with your Lightsail resources, you should delete them to avoid incurring additional charges. This section shows you how to clean up all the resources created in this tutorial.

**Delete an instance snapshot**

To delete a snapshot that you no longer need, use the following command.

```
$ aws lightsail delete-instance-snapshot --instance-snapshot-name cli-tutorial-snapshot
{
    "operations": [
        {
            "id": "cf8xmpl-0ec7-43ec-9cbc-6dedd9d8eda8",
            "resourceName": "cli-tutorial-snapshot",
            "resourceType": "InstanceSnapshot",
            "createdAt": 1673596800.000,
            "location": {
                "availabilityZone": "all",
                "regionName": "us-east-2"
            },
            "isTerminal": true,
            "operationDetails": "",
            "operationType": "DeleteInstanceSnapshot",
            "status": "Succeeded",
            "statusChangedAt": 1673596800.000
        }
    ]
}
```

The response confirms that the snapshot deletion operation has succeeded.

**Delete an instance**

To delete an instance, use the following command.

```
$ aws lightsail delete-instance --instance-name cli-tutorial
{
    "operations": [
        {
            "id": "f4bxmpl-2df1-4740-90d7-e30adaf7e3a1",
            "resourceName": "cli-tutorial",
            "resourceType": "Instance",
            "createdAt": 1673596800.000,
            "location": {
                "availabilityZone": "us-east-2a",
                "regionName": "us-east-2"
            },
            "isTerminal": true,
            "operationDetails": "",
            "operationType": "DeleteInstance",
            "status": "Succeeded",
            "statusChangedAt": 1673596800.000
        }
    ]
}
```

Remember to delete all instances you created, including any instances created from snapshots.

**Delete a disk**

To delete a disk that's no longer needed, use the following command.

```
$ aws lightsail delete-disk --disk-name cli-tutorial-disk
{
    "operations": [
        {
            "id": "aacxmpl-8626-4edd-8b3b-bf108d6b279c",
            "resourceName": "cli-tutorial-disk",
            "resourceType": "Disk",
            "createdAt": 1673596800.000,
            "location": {
                "availabilityZone": "us-east-2a",
                "regionName": "us-east-2"
            },
            "isTerminal": true,
            "operationDetails": "",
            "operationType": "DeleteDisk",
            "status": "Succeeded",
            "statusChangedAt": 1673596800.000
        }
    ]
}
```

If the disk is attached to an instance, you'll need to detach it first using the `detach-disk` command.

**Delete a key pair**

Finally, delete the key pair you created at the beginning of this tutorial.

```
$ aws lightsail delete-key-pair --key-pair-name cli-tutorial-keys
{
    "operation": {
        "id": "dbfxmpl-c954-4a45-93a4-ab3e627d2c23",
        "resourceName": "cli-tutorial-keys",
        "resourceType": "KeyPair",
        "createdAt": 1673596800.000,
        "location": {
            "availabilityZone": "all",
            "regionName": "us-east-2"
        },
        "isTerminal": true,
        "operationDetails": "",
        "operationType": "DeleteKeyPair",
        "status": "Succeeded",
        "statusChangedAt": 1673596800.000
    }
}
```

This command only deletes the key pair from AWS. Now you can delete the local copy as well.

```
$ rm ~/.ssh/cli-tutorial-keys.pem
```
## Next steps

Now that you've learned the basics of managing Lightsail resources using the AWS CLI, explore other Lightsail features.

1. **Domains** – [Assign a domain name](https://docs.aws.amazon.com/lightsail/latest/userguide/amazon-lightsail-domain-registration.html) to your application.
2. **Load balancers** – [Route traffic to multiple instances](https://docs.aws.amazon.com/lightsail/latest/userguide/understanding-lightsail-load-balancers.html) to increase capacity and resilience.
3. **Automatic snapshots** – [Back up your application data automatically](https://docs.aws.amazon.com/lightsail/latest/userguide/amazon-lightsail-configuring-automatic-snapshots.html).
4. **Metrics** – [Monitor your resources' health](https://docs.aws.amazon.com/lightsail/latest/userguide/amazon-lightsail-resource-health-metrics.html), get notifications, and set up alarms.
5. **Databases** – [Connect your application to a relational database](https://docs.aws.amazon.com/lightsail/latest/userguide/amazon-lightsail-databases.html).

For more information about available AWS CLI commands, see the [AWS CLI Command Reference for Lightsail](https://docs.aws.amazon.com/cli/latest/reference/lightsail/).
