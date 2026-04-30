# Cognito: Create a user pool and manage users

## Source

https://docs.aws.amazon.com/cognito/latest/developerguide/getting-started-user-pools.html

## Use case

- **ID**: cognito/getting-started
- **Level**: beginner
- **Core actions**: `cognito-idp:CreateUserPool`, `cognito-idp:AdminCreateUser`

## Steps

1. Create a user pool with email sign-in and password policy
2. Create an app client for authentication
3. Create a user with admin API
4. Set a permanent password
5. List users in the pool
6. Describe the user pool

## Resources created

| Resource | Type |
|----------|------|
| `tut-pool-<random>` | Cognito user pool |
| `tutorial-app` | User pool app client |

## Cost

Free tier covers 50,000 monthly active users (MAUs). This tutorial creates no MAU charges because the user never authenticates through a hosted UI or token endpoint.

## Duration

~9 seconds

## Related docs

- [Getting started with user pools](https://docs.aws.amazon.com/cognito/latest/developerguide/getting-started-user-pools.html)
- [Creating a user pool](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pool-as-user-directory.html)
- [Managing users](https://docs.aws.amazon.com/cognito/latest/developerguide/how-to-manage-user-accounts.html)
- [Amazon Cognito pricing](https://aws.amazon.com/cognito/pricing/)

---

## Appendix

| Field | Value |
|-------|-------|
| Date | 2026-04-14 |
| Script lines | 85 |
| Exit code | 0 |
| Runtime | 9s |
| Steps | 6 |
| Issues | None |
| Version | v1 |
