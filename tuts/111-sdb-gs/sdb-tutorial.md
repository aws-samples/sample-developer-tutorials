# SimpleDB Tutorial

## Prerequisites

- Install and configure the AWS CLI.
- Ensure you have the necessary permissions to create and manage SimpleDB domains.

## Steps

1. **Create a Domain**

   ```bash
   $ aws sdb create-domain --domain-name "test-domain-$SUFFIX"
   ```

2. **Put Attributes**

   ```bash
   $ aws sdb put-attributes --domain-name "$DOMAIN" --item-name "item1" --attributes "Name=color,Value=red" "Name=size,Value=large"
   ```

3. **Get Attributes**

   ```bash
   $ aws sdb get-attributes --domain-name "$DOMAIN" --item-name "item1" --query 'Attributes[].Value' --output text
   ```

   Output:
   ```
   red large
   ```

4. **List Domains**

   ```bash
   $ aws sdb list-domains --query 'DomainNames' --output text
   ```

   Output:
   ```
   test-domain-xmpl 123456789012
   ```

## Clean up

Run the following command to delete the created domain and clean up temporary files.

```bash
$ trap cleanup_resources EXIT
```

## Next steps

- Explore more SimpleDB operations such as batch putting attributes, selecting data, and deleting domains.
- Review the [AWS SimpleDB documentation](https://docs.aws.amazon.com/simpledb/latest/dg/Welcome.html) for advanced use cases and best practices.
