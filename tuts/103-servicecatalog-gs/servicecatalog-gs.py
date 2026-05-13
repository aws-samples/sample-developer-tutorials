import boto3
import time
import uuid

# Initialize the Service Catalog client
client = boto3.client('servicecatalog', region_name='us-east-1')

# Generate a unique suffix
suffix = str(int(time.time()))[-6:]

# Create a portfolio
print("Creating portfolio...")
create_portfolio_response = client.create_portfolio(
    DisplayName=f'my-portfolio-{suffix}',
    Description='This is a test portfolio',
    ProviderName='MyOrg',
    IdempotencyToken=str(uuid.uuid4())
)
port_id = create_portfolio_response['PortfolioDetail']['Id']
print(f"Portfolio created with ID: {port_id}")

# Describe the created portfolio
print("Describing portfolio...")
describe_portfolio_response = client.describe_portfolio(
    Id=port_id
)
print(f"Portfolio description: {describe_portfolio_response['PortfolioDetail']}")

# List all portfolios
print("Listing all portfolios...")
list_portfolios_response = client.list_portfolios()
print(f"Portfolios: {list_portfolios_response['PortfolioDetails']}")

# Delete the created portfolio
print("Deleting portfolio...")
client.delete_portfolio(
    Id=port_id
)
print(f"Portfolio with ID {port_id} deleted")

print("PASS")