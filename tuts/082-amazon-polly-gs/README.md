# Amazon Polly getting started

This tutorial guides you through the process of using Amazon Polly with the AWS Command Line Interface (AWS CLI). Amazon Polly is a service that turns text into lifelike speech, allowing you to create applications that talk and build entirely new categories of speech-enabled products. You'll learn how to explore available voices, synthesize speech from text, and save the audio output to files.

You can either run the automated shell script (`amazon-polly-getting-started.sh`) to execute all the examples at once, or follow the step-by-step instructions in the tutorial (`amazon-polly-getting-started.md`) to understand each command in detail. The shell script includes logging and error handling, making it easy to see what commands are being executed and their results.

## Files in this tutorial

- `amazon-polly-getting-started.sh` - Automated shell script that demonstrates Amazon Polly functionality
- `amazon-polly-getting-started.md` - Step-by-step tutorial with detailed explanations
- `README.md` - This file

## Resources Created

The script creates the following AWS resources in order:

- Polly lexicon

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.
## Prerequisites

- AWS CLI installed and configured with appropriate credentials
- Sufficient permissions to use Amazon Polly in your AWS account
- Basic familiarity with command line operations