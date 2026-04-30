# S3 Cors

An AWS CLI tutorial that demonstrates S3 operations.

## Running

```bash
bash s3-cors.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash s3-cors.sh
```

## What it does

1. Creating bucket"; aws s3api create-bucket --bucket "$B
2. Setting CORS"; aws s3api put-bucket-cors --bucket "$B" --cors-configuration '{"CORSRules":[{"AllowedOrigins":["https://example.com"],"AllowedMethods":["GET","PUT"],"AllowedHeaders":["*"],"MaxAgeSeconds
3. Getting CORS"; aws s3api get-bucket-cors --bucket "$B

## Resources created

- Bucket
- Bucket Cors

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI s3 reference](https://docs.aws.amazon.com/cli/latest/reference/s3/index.html)
- [AWS CLI s3api reference](https://docs.aws.amazon.com/cli/latest/reference/s3api/index.html)

