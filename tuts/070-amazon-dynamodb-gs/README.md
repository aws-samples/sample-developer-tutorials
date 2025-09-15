# Amazon DynamoDB getting started

This tutorial demonstrates how to get started with Amazon DynamoDB, a fully managed NoSQL database service that provides fast and predictable performance with seamless scalability. You'll learn the fundamental concepts of DynamoDB including creating tables, adding items, querying data, and performing basic operations using both the AWS CLI and SDK examples.

You can either run the automated shell script (`amazon-dynamodb-gs.sh`) to quickly set up and explore DynamoDB operations, or follow the step-by-step instructions in the tutorial (`amazon-dynamodb-gs.md`) to understand each concept in detail. Both approaches will help you understand the core functionality of DynamoDB and prepare you to build applications that leverage this powerful database service.

## Resources Created

The script creates the following AWS resources in order:

- DynamoDB table
- DynamoDB item
- DynamoDB item (b)
- DynamoDB item (c)
- DynamoDB item (d)

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.