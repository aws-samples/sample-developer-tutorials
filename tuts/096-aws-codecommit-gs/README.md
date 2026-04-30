# CodeCommit: Create a repository and manage code

Create a CodeCommit repository, add files, branch, compare changes, and retrieve metadata using the AWS CLI.

## Source

https://docs.aws.amazon.com/codecommit/latest/userguide/getting-started-cc.html

## Use case

- ID: codecommit/getting-started
- Phase: create
- Complexity: beginner
- Core actions: codecommit:CreateRepository, codecommit:PutFile, codecommit:CreateBranch

## What it does

1. Creates a CodeCommit repository
2. Adds a file using fileb://
3. Retrieves the file metadata
4. Creates a feature branch
5. Adds a file to the feature branch
6. Compares branches with get-differences
7. Gets repository metadata

## Running

```bash
bash aws-codecommit-gs.sh
```

## Resources created

- CodeCommit repository

No persistent resources remain after cleanup. The script prompts you to delete the repository when it finishes.

## Estimated time

- Run: ~11 seconds

## Cost

CodeCommit is free for up to 5 active users per month (unlimited repositories). No charges for this tutorial under the free tier.

## Related docs

- [Getting started with CodeCommit](https://docs.aws.amazon.com/codecommit/latest/userguide/getting-started-cc.html)
- [put-file CLI reference](https://docs.aws.amazon.com/cli/latest/reference/codecommit/put-file.html)
- [Working with branches](https://docs.aws.amazon.com/codecommit/latest/userguide/how-to-create-branch.html)
- [CodeCommit quotas](https://docs.aws.amazon.com/codecommit/latest/userguide/limits.html)
- [CodeCommit pricing](https://aws.amazon.com/codecommit/pricing/)
