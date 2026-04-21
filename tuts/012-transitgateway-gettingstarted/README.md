# AWS Transit Gateway getting started

This tutorial demonstrates how to set up and configure AWS Transit Gateway using the AWS CLI. You'll learn to create transit gateways, attach VPCs, configure route tables, and implement scalable network connectivity between multiple VPCs and on-premises networks.

You can either run the automated script `transitgateway-gettingstarted.sh` to execute all operations automatically with comprehensive error handling and resource cleanup, or follow the step-by-step instructions in the `transitgateway-gettingstarted.md` tutorial to understand each AWS CLI command and concept in detail. The script includes interactive prompts and built-in safeguards, while the tutorial provides detailed explanations of features and best practices.

## Resources Created

The script creates the following AWS resources in order:

- EC2 vpc
- EC2 subnet
- EC2 subnet (b)
- EC2 vpc (b)
- EC2 subnet (c)
- EC2 subnet (d)
- EC2 transit gateway
- EC2 transit gateway vpc attachment
- EC2 transit gateway vpc attachment (b)
- EC2 route
- EC2 route (b)

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.


## SDK examples

This tutorial is also available as SDK examples in Python and JavaScript (with scaffolds for 9 additional languages). Each implements the same scenario with wrapper classes, a scenario orchestrator, and unit tests.

### Run with Python

```bash
cd tuts/012-transitgateway-gettingstarted/python
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python3 scenario_getting_started.py
```

### Run with JavaScript

```bash
cd tuts/012-transitgateway-gettingstarted/javascript
npm install
node scenarios/getting-started.js
```

See the `python/` and `javascript/` directories for source code and tests.
## CloudFormation

This tutorial includes a CloudFormation template that creates the same resources as the CLI script.

**Resources created:** Transit gateway with two VPCs

### Deploy with CloudFormation

```bash
./deploy.sh 012-transitgateway-gettingstarted
```

### Run the interactive steps

Once deployed, run the interactive tutorial steps against the CloudFormation-created resources. Each command is displayed with resolved values so you can run them individually.

```bash
bash tuts/012-transitgateway-gettingstarted/transitgateway-gettingstarted-cfn.sh
```

### Clean up

```bash
./cleanup.sh 012-transitgateway-gettingstarted
```
