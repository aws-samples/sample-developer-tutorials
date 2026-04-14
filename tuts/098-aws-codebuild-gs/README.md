# CodeBuild: Create a project and run a build

Create an S3-sourced CodeBuild project, run a build, and verify artifacts using the AWS CLI.

## Source

https://docs.aws.amazon.com/codebuild/latest/userguide/getting-started-cli.html

## Use case

- ID: codebuild/getting-started
- Phase: create
- Complexity: intermediate
- Core actions: codebuild:CreateProject, codebuild:StartBuild

## What it does

1. Creates an S3 bucket for source and artifacts
2. Creates source files (buildspec.yml + index.html) and uploads as zip
3. Creates an IAM service role for CodeBuild
4. Creates a build project with S3 source
5. Starts a build
6. Waits for completion and checks artifacts

## Running

```bash
bash aws-codebuild-gs.sh
```

## Resources created

- S3 bucket (source and artifacts)
- CodeBuild project
- IAM role (with S3 and CloudWatch Logs policies)
- CloudWatch log group (created automatically by CodeBuild)

No persistent resources remain after cleanup. The script prompts you to delete all resources when it finishes.

## Estimated time

- Run: ~37 seconds (includes build execution)

## Cost

CodeBuild free tier includes 100 build minutes per month on general1.small. No charges expected for this tutorial under the free tier.

## Related docs

- [Getting started with CodeBuild (CLI)](https://docs.aws.amazon.com/codebuild/latest/userguide/getting-started-cli.html)
- [Build specification reference](https://docs.aws.amazon.com/codebuild/latest/userguide/build-spec-ref.html)
- [Build environment reference](https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref.html)
- [CodeBuild pricing](https://aws.amazon.com/codebuild/pricing/)

---

## Appendix: Generation details

| Field | Value |
|-------|-------|
| Generation date | 2026-04-14 |
| Source script | New, 138 lines |
| Script test result | EXIT 0, 37s, 6 steps, no issues |
| Issues encountered | None |
| Iterations | v1 |
