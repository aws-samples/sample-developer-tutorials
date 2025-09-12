# Amazon SES getting started

This tutorial demonstrates how to get started with Amazon Simple Email Service (Amazon SES) by setting up email sending capabilities, verifying email addresses and domains, and sending transactional emails.

You can run the shell script to automatically configure the Amazon SES resources and verify email addresses, or follow the step-by-step instructions in the tutorial to manually set up your email sending infrastructure.

## Resources Created

The script creates the following AWS resources in order:

- SES email identity verification
- SES domain identity verification (optional)
- SES DKIM setup (optional)

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.