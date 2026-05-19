# AWS CodeArtifact Tutorial

This tutorial demonstrates how to create and manage resources in AWS CodeArtifact. You will create a temporary domain and repository, and then clean up the resources at the end.

## Topics

- [Prerequisites](#aws-codeartifact-tutorial-prerequisites)
- [Create a temporary domain](#aws-codeartifact-tutorial-create-a-temporary-domain)
- [Create a temporary repository](#aws-codeartifact-tutorial-create-a-temporary-repository)
- [Next steps](#aws-codeartifact-tutorial-next-steps)

## Prerequisites

Before you begin this tutorial, make sure you have the following.

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html). You can also [use AWS CloudShell](https://docs.aws.amazon.com/cloudshell/latest/userguide/what-is-cloudshell.html), which includes the AWS CLI.
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. Basic familiarity with command line interfaces.
4. [Sufficient permissions](https://docs.aws.amazon.com/codeartifact/latest/ug/auth-and-access-control.html) to create and delete domains and repositories in AWS CodeArtifact.

## Create a temporary domain

Creating a temporary domain is essential for organizing and managing your CodeArtifact repositories. Each domain can contain multiple repositories, and domains help in applying policies and permissions.

**Create a temporary domain**

```bash
aws codeartifact create-domain --domain "dom$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)"
```

After running the command, you should see output similar to the following:

```
{
    "domain": {
        "name": "domabc123",
        "owner": "123456789012",
        "arn": "arn:aws:codeartifact:us-west-2:123456789012:domain/domabc123",
        "status": "Active",
        "createdTime": "2023-01-13T12:34:56.789Z"
    }
}
```

The domain has been successfully created.

## Create a temporary repository

Repositories within a domain store your package versions. Creating a repository allows you to upload and manage packages.

**Create a temporary repository**

```bash
aws codeartifact create-repository --domain "dom$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)" --repository "repo$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)"
```

After running the command, you should see output similar to the following:

```
{
    "repository": {
        "name": "repoabc123",
        "administratorAccount": "123456789012",
        "domainName": "domabc123",
        "domainOwner": "123456789012",
        "arn": "arn:aws:codeartifact:us-west-2:123456789012:repository/domabc123/repoabc123",
        "description": "",
        "upstreams": [],
        "externalConnections": [],
        "createdTime": "2023-01-13T12:34:56.789Z"
    }
}
```

The repository has been successfully created in the domain.

## Next steps

- Learn more about [domains](https://docs.aws.amazon.com/codeartifact/latest/ug/domains.html) in AWS CodeArtifact.
- Explore how to [manage repositories](https://docs.aws.amazon.com/codeartifact/latest/ug/repos.html) within your domains.
- Discover how to [publish and consume packages](https://docs.aws.amazon.com/codeartifact/latest/ug/using-packages.html) using AWS CodeArtifact.