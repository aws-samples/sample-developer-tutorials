# EFS: Create a file system

## Source

https://docs.aws.amazon.com/efs/latest/ug/getting-started.html

## Use case

- **ID**: efs/getting-started
- **Level**: intermediate
- **Core actions**: `elasticfilesystem:CreateFileSystem`, `elasticfilesystem:CreateMountTarget`, `elasticfilesystem:PutLifecycleConfiguration`

## Steps

1. Create an encrypted file system
2. Wait for the file system to be available
3. Describe the file system
4. Create a mount target in the default VPC
5. Wait for the mount target
6. Describe mount targets
7. Set a lifecycle policy

## Resources created

| Resource | Type |
|----------|------|
| `tutorial-efs-<random>` | EFS file system |
| Mount target in default VPC subnet | Mount target |

## Cost

Per-GB pricing. $0.30/GB-month (Standard), $0.025/GB-month (Infrequent Access). An empty file system has no storage cost. Clean up promptly to avoid charges.

## Duration

~114 seconds (mount target creation accounts for most of the wait)

## Related docs

- [Getting started with Amazon EFS](https://docs.aws.amazon.com/efs/latest/ug/getting-started.html)
- [Creating file systems](https://docs.aws.amazon.com/efs/latest/ug/creating-using-create-fs.html)
- [Creating mount targets](https://docs.aws.amazon.com/efs/latest/ug/accessing-fs.html)
- [EFS lifecycle management](https://docs.aws.amazon.com/efs/latest/ug/lifecycle-management-efs.html)
