# Secrets Manager: Store and retrieve secrets

## Source

https://docs.aws.amazon.com/secretsmanager/latest/userguide/getting-started.html

## Use case

- **ID**: secretsmanager/getting-started
- **Level**: beginner
- **Core actions**: `secretsmanager:CreateSecret`, `secretsmanager:GetSecretValue`, `secretsmanager:PutSecretValue`

## Steps

1. Create a secret with JSON credentials
2. Retrieve the secret
3. Update the secret value
4. Retrieve the updated secret
5. Describe the secret metadata
6. Tag the secret

## Resources created

| Resource | Type |
|----------|------|
| `tutorial/db-creds-<random>` | Secret |

## Cost

$0.40/month per secret. The secret is deleted immediately during cleanup, so no ongoing cost.

## Duration

~7 seconds

## Related docs

- [Getting started with Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/getting-started.html)
- [Create and manage secrets](https://docs.aws.amazon.com/secretsmanager/latest/userguide/managing-secrets.html)
- [Rotate secrets automatically](https://docs.aws.amazon.com/secretsmanager/latest/userguide/rotating-secrets.html)
- [Tag secrets](https://docs.aws.amazon.com/secretsmanager/latest/userguide/managing-secrets_tagging.html)

---

## Appendix

| Field | Value |
|-------|-------|
| Date | 2026-04-14 |
| Script lines | 78 |
| Exit code | 0 |
| Runtime | 7s |
| Steps | 6 |
| Issues | None |
| Version | v1 |
