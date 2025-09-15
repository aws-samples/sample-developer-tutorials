# Amazon MQ getting started tutorial

This tutorial provides a comprehensive introduction to Amazon MQ using the AWS CLI. You'll learn how to create and configure managed message brokers, set up queues and topics, and integrate messaging capabilities into your applications using Apache ActiveMQ or RabbitMQ.

You can either run the provided shell script to automatically set up your Amazon MQ broker and basic messaging infrastructure, or follow the step-by-step instructions in the tutorial markdown file to understand each component and customize the configuration for your specific messaging requirements.

## Resources Created

The script creates the following AWS resources in order:

- Secrets Manager secret
- Mq broker

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.