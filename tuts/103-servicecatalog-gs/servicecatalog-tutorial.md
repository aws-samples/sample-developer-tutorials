# AWS Service Catalog Tutorial

This tutorial demonstrates how to create, describe, and list portfolios using AWS Service Catalog.

## Topics

- [Prerequisites](#aws-service-catalog-tutorial-prerequisites)
- [Create a portfolio](#aws-service-catalog-tutorial-create-a-portfolio)
- [Describe the created portfolio](#aws-service-catalog-tutorial-describe-the-created-portfolio)
- [List all portfolios](#aws-service-catalog-tutorial-list-all-portfolios)
- [Next steps](#aws-service-catalog-tutorial-next-steps)

## Prerequisites

Before you begin this tutorial, make sure you have the following.

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html). You can also [use AWS CloudShell](https://docs.aws.amazon.com/cloudshell/latest/userguide/what-is-cloudshell.html), which includes the AWS CLI.
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. Basic familiarity with command line interfaces.
4. [Sufficient permissions](https://docs.aws.amazon.com/servicecatalog/latest/adminguide/controlling-access.html) to create, describe, and list portfolios in AWS Service Catalog.

## Create a portfolio

Creating a portfolio is the first step in organizing your AWS Service Catalog. A portfolio groups related products and is a way to manage access and governance.

**Create a portfolio**

```bash
PORT_ID=$(aws servicecatalog create-portfolio \
    --display-name "my-portfolio-${SUFFIX}" \
    --description "This is a test portfolio" \
    --provider-name "MyOrg" \
    --idempotency-token "${SUFFIX}" \
    --query 'PortfolioDetail.Id' --output text)
CREATED_RESOURCES+=("${PORT_ID}")
echo "Result: Portfolio created with ID: ${PORT_ID}"
```

The command above creates a portfolio with a unique display name and description. The portfolio ID is stored for later use.

## Describe the created portfolio

Describing a portfolio allows you to view its details, including display name and description. This is useful for verifying that the portfolio was created correctly.

**Describe the created portfolio**

```bash
DESCRIBE_PORTFOLIO_RESPONSE=$(aws servicecatalog describe-portfolio \
    --id "${PORT_ID}")
echo "Result: Portfolio description: ${DESCRIBE_PORTFOLIO_RESPONSE}"
```

The command above describes the portfolio you created, showing its details.

## List all portfolios

Listing all portfolios helps you keep track of the portfolios you have created. This is essential for managing your AWS Service Catalog environment.

**List all portfolios**

```bash
LIST_PORTFOLIOS_RESPONSE=$(aws servicecatalog list-portfolios \
    --query 'PortfolioDetails[].DisplayName' --output text)
echo "Result: Portfolios: ${LIST_PORTFOLIOS_RESPONSE}"
```

The command above lists all portfolios in your AWS Service Catalog, showing their display names.

## Next steps

In this tutorial, you learned how to:

1. Create a portfolio in AWS Service Catalog.
2. Describe the created portfolio to verify its details.
3. List all portfolios to manage your Service Catalog environment.

For more information, see the [AWS Service Catalog User Guide](https://docs.aws.amazon.com/servicecatalog/latest/adminguide/introduction.html).