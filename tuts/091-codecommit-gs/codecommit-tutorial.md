# AWS CodeCommit Repository Creation Tutorial

This tutorial demonstrates how to create an AWS CodeCommit repository using the AWS CLI. You will also learn how to log actions and clean up resources automatically.

## Topics

- [Prerequisites](#aws-codecommit-repository-creation-tutorial-prerequisites)
- [Generate a unique suffix](#aws-codecommit-repository-creation-tutorial-generate-a-unique-suffix)
- [Create a temporary directory for logs](#aws-codecommit-repository-creation-tutorial-create-a-temporary-directory-for-logs)
- [Create a CodeCommit repository](#aws-codecommit-repository-creation-tutorial-create-a-codecommit-repository)
- [Verify repository creation](#aws-codecommit-repository-creation-tutorial-verify-repository-creation)
- [Clean up resources](#aws-codecommit-repository-creation-tutorial-clean-up-resources)
- [Next steps](#aws-codecommit-repository-creation-tutorial-next-steps)

## Prerequisites

Before you begin this tutorial, make sure you have the following.

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html). You can also [use AWS CloudShell](https://docs.aws.amazon.com/cloudshell/latest/userguide/what-is-cloudshell.html), which includes the AWS CLI.
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. Basic familiarity with command line interfaces and Git concepts.

## Generate a unique suffix

We generate a unique suffix to ensure that the repository name is unique. This prevents naming conflicts with existing repositories.

**Generate a unique suffix:**

```bash
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
```

The generated suffix is: `${SUFFIX}`.

## Create a temporary directory for logs

A temporary directory is created to store log files. This helps in organizing and managing log files efficiently.

**Create a temporary directory:**

```bash
TEMP_DIR=$(mktemp -d)
LOG_FILE="${TEMP_DIR}/log.txt"
```

The temporary directory is: `${TEMP_DIR}`.

## Create a CodeCommit repository

We will now create a CodeCommit repository using the AWS CLI. CodeCommit is a version control service that hosts secure Git-based repositories.

**Create a CodeCommit repository:**

```bash
REPO_NAME="test-repo-${SUFFIX}"
aws codecommit create-repository --repository-name "${REPO_NAME}"
```

The repository `${REPO_NAME}` has been created.

## Verify repository creation

We check the log file to verify that the repository was created successfully. This step ensures that the repository ARN is retrieved and logged.

**Verify repository creation:**

```bash
if grep -q 'repositoryName' "$LOG_FILE"; then
    echo "PASS"
    CREATED_RESOURCES+=("repo:$REPO_NAME")
else
    echo "Failed to retrieve repository ARN."
    exit 1
fi
```

The repository creation has been verified.

## Clean up resources

The script automatically cleans up the created resources to avoid unnecessary charges.

**Clean up resources:**

```bash
cleanup_resources() {
    for (( i=${#CREATED_RESOURCES[@]}-1; i>=0; i-- )); do
        TYPE_ID=(${CREATED_RESOURCES[$i]})
        case ${TYPE_ID[0]} in
            "repo")
                aws codecommit delete-repository --repository-name "${TYPE_ID[1]}" || true
                ;;
        esac
    done
    rm -rf "$TEMP_DIR"
}
trap cleanup_resources EXIT
```

All created resources have been cleaned up.

## Next steps

- Learn more about [AWS CodeCommit](https://docs.aws.amazon.com/codecommit/latest/userguide/welcome.html).
- Explore how to [clone a CodeCommit repository](https://docs.aws.amazon.com/codecommit/latest/userguide/how-to-connect.html).
- Discover how to [set up access control](https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control.html) for your repositories.