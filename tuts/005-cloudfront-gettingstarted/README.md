# Amazon CloudFront getting started

This tutorial demonstrates how to set up and configure Amazon CloudFront distributions using the AWS CLI. You'll learn to create distributions, configure origins, set up caching behaviors, and implement content delivery optimization for global web applications.

You can either run the automated script `cloudfront-gettingstarted.sh` to execute all operations automatically with comprehensive error handling and resource cleanup, or follow the step-by-step instructions in the `cloudfront-gettingstarted.md` tutorial to understand each AWS CLI command and concept in detail. The script includes interactive prompts and built-in safeguards, while the tutorial provides detailed explanations of features and best practices.

## Resources Created

The script creates the following AWS resources in order:

- CloudFront origin access control
- CloudFront distribution
- S3 bucket policy

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.


## SDK examples

This tutorial is also available as SDK examples in Python and JavaScript (with scaffolds for 9 additional languages). Each implements the same scenario with wrapper classes, a scenario orchestrator, and unit tests.

### Run with Python

```bash
cd tuts/005-cloudfront-gettingstarted/python
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python3 scenario_getting_started.py
```

### Run with JavaScript

```bash
cd tuts/005-cloudfront-gettingstarted/javascript
npm install
node scenarios/getting-started.js
```

See the `python/` and `javascript/` directories for source code and tests.
## CloudFormation

This tutorial includes a CloudFormation template that creates the same resources as the CLI script.

**Resources created:** CloudFront distribution with S3 origin

### Deploy with CloudFormation

```bash
./deploy.sh 005-cloudfront-gettingstarted
```

### Run the interactive steps

Once deployed, run the interactive tutorial steps against the CloudFormation-created resources. Each command is displayed with resolved values so you can run them individually.

```bash
bash tuts/005-cloudfront-gettingstarted/cloudfront-gettingstarted-cfn.sh
```

### Clean up

```bash
./cleanup.sh 005-cloudfront-gettingstarted
```
