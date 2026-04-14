# Lex: Create a chatbot

Create an Amazon Lex V2 chatbot with an IAM role, English locale, and a sample intent, then build the bot locale.

## Source

https://docs.aws.amazon.com/lexv2/latest/dg/getting-started.html

## Use case

- **ID**: lex/getting-started
- **Level**: intermediate
- **Core actions**: `lexv2-models:CreateBot`, `lexv2-models:CreateIntent`, `lexv2-models:CreateBotLocale`, `lexv2-models:BuildBotLocale`

## Steps

1. Create an IAM role for the bot
2. Create a bot
3. Create an English locale
4. Create an OrderPizza intent with sample utterances
5. Build the bot locale
6. Describe the bot

## Resources created

| Resource | Type |
|----------|------|
| `tut-bot-<random>` | Lex V2 bot |
| `lex-tut-role-<random>` | IAM role (with Polly policy) |

## Duration

~40 seconds

## Cost

No charge for bot creation. Lex charges per text or speech request when the bot processes conversations. This tutorial does not send conversation requests.

## Related docs

- [Getting started with Amazon Lex V2](https://docs.aws.amazon.com/lexv2/latest/dg/getting-started.html)
- [Creating a bot](https://docs.aws.amazon.com/lexv2/latest/dg/build-create.html)
- [Adding intents](https://docs.aws.amazon.com/lexv2/latest/dg/build-intents.html)
- [Amazon Lex pricing](https://aws.amazon.com/lex/pricing/)

---

## Appendix

| Field | Value |
|-------|-------|
| Date | 2026-04-14 |
| Script lines | 106 |
| Exit code | 0 |
| Runtime | 40s |
| Steps | 6 |
| Issues | Fixed bot/locale wait timing |
| Version | v1 |
