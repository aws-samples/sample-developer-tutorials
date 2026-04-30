# Request and manage certificates with AWS Certificate Manager

This tutorial shows you how to request an SSL/TLS certificate with DNS validation, inspect the certificate and its validation record, list certificates, and add tags.

## Prerequisites

- AWS CLI configured with credentials and a default region
- Permissions for `acm:RequestCertificate`, `acm:DescribeCertificate`, `acm:ListCertificates`, `acm:AddTagsToCertificate`, `acm:ListTagsForCertificate`, `acm:DeleteCertificate`

## Step 1: Request a certificate

Request a certificate for a domain using DNS validation:

```bash
CERT_ARN=$(aws acm request-certificate \
    --domain-name "$DOMAIN" \
    --validation-method DNS \
    --query 'CertificateArn' --output text)
echo "Certificate ARN: $CERT_ARN"
```

ACM creates the certificate in `PENDING_VALIDATION` status. The certificate won't be issued until you add the DNS validation record to your domain's DNS configuration.

> **Note:** The script uses a subdomain of `example.com`, which is a reserved domain. The certificate will stay in `PENDING_VALIDATION` because DNS validation can't complete for a domain you don't own.

## Step 2: Describe the certificate

```bash
aws acm describe-certificate --certificate-arn "$CERT_ARN" \
    --query 'Certificate.{Domain:DomainName,Status:Status,Type:Type,Validation:DomainValidationOptions[0].ValidationMethod}' \
    --output table
```

This shows the domain name, current status, certificate type (AMAZON_ISSUED), and validation method.

## Step 3: Show the DNS validation record

```bash
aws acm describe-certificate --certificate-arn "$CERT_ARN" \
    --query 'Certificate.DomainValidationOptions[0].ResourceRecord.{Name:Name,Type:Type,Value:Value}' \
    --output table
```

ACM provides a CNAME record that you add to your domain's DNS to prove ownership. In production, you would create this record in Route 53 or your DNS provider.

The validation record may be empty on the first describe call. The script waits briefly before querying.

## Step 4: List certificates

```bash
aws acm list-certificates \
    --query 'CertificateSummaryList[?contains(DomainName, `tutorial-`)].{Domain:DomainName,Status:Status,ARN:CertificateArn}' \
    --output table
```

## Step 5: Add tags

```bash
aws acm add-tags-to-certificate --certificate-arn "$CERT_ARN" \
    --tags Key=Environment,Value=tutorial Key=Project,Value=acm-gs
aws acm list-tags-for-certificate --certificate-arn "$CERT_ARN" \
    --query 'Tags[].{Key:Key,Value:Value}' --output table
```

Tags help you organize and track certificates. You can add up to 50 tags per certificate.

## Cleanup

Delete the certificate:

```bash
aws acm delete-certificate --certificate-arn "$CERT_ARN"
```

Certificates in `PENDING_VALIDATION` status can be deleted immediately. Certificates that are in use by another AWS service (such as an Elastic Load Balancer) must be disassociated first.

The script automates all steps including cleanup:

```bash
bash aws-acm-gs.sh
```
