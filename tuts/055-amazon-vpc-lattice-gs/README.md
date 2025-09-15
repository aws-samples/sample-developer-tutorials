# Amazon VPC Lattice getting started

This tutorial guides you through the process of creating and managing an Amazon VPC Lattice service network using the AWS Command Line Interface (AWS CLI). You'll learn how to create a service network, create a service, associate the service with the service network, and associate a VPC with the service network to enable secure communication between your applications.

You can either run the automated shell script (`amazon-vpc-lattice-getting-started.sh`) to quickly set up the entire VPC Lattice configuration, or follow the step-by-step instructions in the tutorial (`amazon-vpc-lattice-getting-started.md`) to understand each component and manually execute the commands.

## Resources Created

The script creates the following AWS resources in order:

- Vpc-Lattice service network
- Vpc-Lattice service
- Vpc-Lattice service network service association
- Vpc-Lattice service network vpc association

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.