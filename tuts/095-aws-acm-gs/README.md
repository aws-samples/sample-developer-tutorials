# ACM: Request and manage certificates

Request an SSL/TLS certificate with DNS validation, inspect the certificate, list certificates, and add tags using the AWS CLI.

## Source

https://docs.aws.amazon.com/acm/latest/userguide/gs.html

## Use case

- ID: acm/getting-started
- Phase: create
- Complexity: beginner
- Core actions: acm:RequestCertificate, acm:DescribeCertificate

## What it does

1. Requests a certificate with DNS validation
2. Describes the certificate
3. Shows the DNS validation record
4. Lists certificates
5. Adds tags to the certificate

## Running

```bash
bash aws-acm-gs.sh
```

## Resources created

- ACM certificate (pending validation)

The certificate is free. ACM-issued public certificates have no cost. The script prompts you to clean up when it finishes.

## Estimated time

- Run: ~7 seconds

## Cost

Free. There is no charge for ACM-issued public SSL/TLS certificates.

## Related docs

- [Getting started with ACM](https://docs.aws.amazon.com/acm/latest/userguide/gs.html)
- [Requesting a public certificate](https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-request-public.html)
- [DNS validation](https://docs.aws.amazon.com/acm/latest/userguide/dns-validation.html)
- [Tagging ACM certificates](https://docs.aws.amazon.com/acm/latest/userguide/tags.html)
- [Deleting certificates](https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-delete.html)
