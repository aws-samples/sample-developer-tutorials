# KMS: Create a key and encrypt data

Create a customer managed KMS key, encrypt and decrypt data, and generate a data key using the AWS CLI.

## Source

https://docs.aws.amazon.com/kms/latest/developerguide/getting-started.html

## Use case

- ID: kms/getting-started
- Phase: create
- Complexity: beginner
- Core actions: kms:CreateKey, kms:Encrypt, kms:Decrypt

## What it does

1. Creates a customer managed KMS key
2. Creates an alias for the key
3. Describes the key metadata
4. Encrypts data using fileb://
5. Decrypts the ciphertext
6. Generates a data key for client-side encryption
7. Lists KMS keys and aliases

## Running

```bash
bash aws-kms-gs.sh
```

## Resources created

- KMS customer managed key (with alias)

The key costs $1/month until deleted. The script prompts you to clean up when it finishes. Cleanup schedules the key for deletion with a 7-day waiting period.

## Estimated time

- Run: ~7 seconds

## Cost

$1/month for the customer managed key. Delete the key promptly to avoid charges.

## Related docs

- [Getting started with AWS KMS](https://docs.aws.amazon.com/kms/latest/developerguide/getting-started.html)
- [Creating keys](https://docs.aws.amazon.com/kms/latest/developerguide/create-keys.html)
- [Encrypting and decrypting data](https://docs.aws.amazon.com/kms/latest/developerguide/programming-encryption.html)
- [Data keys](https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#data-keys)
- [Deleting KMS keys](https://docs.aws.amazon.com/kms/latest/developerguide/deleting-keys.html)

---

## Appendix: Generation details

| Field | Value |
|-------|-------|
| Generation date | 2026-04-14 |
| Source script | New, 88 lines |
| Script test result | EXIT 0, 7s, 7 steps, no issues |
| Issues encountered | None |
| Iterations | v1 (direct to publish) |
