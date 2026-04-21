# Amazon Lightsail getting started

This tutorial demonstrates how to get started with Amazon Lightsail using the AWS CLI. You'll learn the fundamental concepts and operations for working with this AWS service through command-line interface.

You can either run the automated script `lightsail-gs.sh` to execute all operations automatically with comprehensive error handling and resource cleanup, or follow the step-by-step instructions in the `lightsail-gs.md` tutorial to understand each AWS CLI command and concept in detail. The script includes interactive prompts and built-in safeguards, while the tutorial provides detailed explanations of features and best practices.

## Resources Created

The script creates the following AWS resources in order:

- Lightsail instance (nano_3_0 bundle with Amazon Linux 2023)
- Lightsail disk (8 GB block storage disk)
- Lightsail instance snapshot (backup of the instance)

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.


## SDK examples

This tutorial is also available as SDK examples in Python and JavaScript (with scaffolds for 9 additional languages). Each implements the same scenario with wrapper classes, a scenario orchestrator, and unit tests.

### Run with Python

```bash
cd tuts/001-lightsail-gs/python
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python3 scenario_getting_started.py
```

### Run with JavaScript

```bash
cd tuts/001-lightsail-gs/javascript
npm install
node scenarios/getting-started.js
```

See the `python/` and `javascript/` directories for source code and tests.
## CloudFormation

This tutorial includes a CloudFormation template that creates the same resources as the CLI script.

**Resources created:** Lightsail instance and disk

### Deploy with CloudFormation

```bash
./deploy.sh 001-lightsail-gs
```

### Run the interactive steps

Once deployed, run the interactive tutorial steps against the CloudFormation-created resources. Each command is displayed with resolved values so you can run them individually.

```bash
bash tuts/001-lightsail-gs/lightsail-gs-cfn.sh
```

### Clean up

```bash
./cleanup.sh 001-lightsail-gs
```
