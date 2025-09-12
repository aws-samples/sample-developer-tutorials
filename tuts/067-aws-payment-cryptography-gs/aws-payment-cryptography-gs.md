# Getting started with AWS Payment Cryptography

This tutorial walks you through the process of using AWS Payment Cryptography to create a key and perform cryptographic operations for card verification values (CVV2). You'll learn how to create a key, generate a CVV2 value, verify the value, and perform a negative test to understand validation failures.

## Prerequisites

Before you begin, make sure that:

- You have an AWS account with permission to access the AWS Payment Cryptography service. For more information, see [IAM policies](https://docs.aws.amazon.com/payment-cryptography/latest/userguide/security_iam_service-with-iam.html).
- You have the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) installed and configured with your credentials.
- You are using a region where AWS Payment Cryptography is available.

This tutorial takes approximately 10 minutes to complete and uses minimal AWS resources. The only resource created is a cryptographic key, which has no direct cost, but standard AWS Payment Cryptography service rates apply for API operations. The total cost for running this tutorial is approximately $0.00154 (less than one cent) if you delete the key immediately after completing the tutorial. If you don't delete the key, it will continue to incur a storage cost of approximately $1.00 per month.

## Create a key

The first step is to create a card verification key (CVK) that will be used for generating and verifying CVV/CVV2 values. AWS Payment Cryptography uses the TR-31 standard to categorize keys, and for card verification, we'll use a TR31_C0_CARD_VERIFICATION_KEY type.

Run the following command to create a double-length 3DES (2KEY TDES) key:

```bash
aws payment-cryptography create-key \
  --exportable \
  --key-attributes KeyAlgorithm=TDES_2KEY,KeyUsage=TR31_C0_CARD_VERIFICATION_KEY,KeyClass=SYMMETRIC_KEY,KeyModesOfUse='{Generate=true,Verify=true}'
```

The command creates a key with the ability to generate and verify card validation data. The response includes details about the key:

```json
{
    "Key": {
        "KeyArn": "arn:aws:payment-cryptography:us-east-2:123456789012:key/abcd1234",
        "KeyAttributes": {
            "KeyUsage": "TR31_C0_CARD_VERIFICATION_KEY",
            "KeyClass": "SYMMETRIC_KEY",
            "KeyAlgorithm": "TDES_2KEY",
            "KeyModesOfUse": {
                "Encrypt": false,
                "Decrypt": false,
                "Wrap": false,
                "Unwrap": false,
                "Generate": true,
                "Sign": false,
                "Verify": true,
                "DeriveKey": false,
                "NoRestrictions": false
            }
        },
        "KeyCheckValue": "4A2C40",
        "KeyCheckValueAlgorithm": "ANSI_X9_24",
        "Enabled": true,
        "Exportable": true,
        "KeyState": "CREATE_COMPLETE",
        "KeyOrigin": "AWS_PAYMENT_CRYPTOGRAPHY",
        "CreateTimestamp": "2025-01-13T06:41:46.648000-07:00",
        "UsageStartTimestamp": "2025-01-13T06:41:46.626000-07:00"
    }
}
```

Take note of the `KeyArn` value as you'll need it for subsequent steps. The KeyArn uniquely identifies your key in AWS Payment Cryptography.

## Generate a CVV2 value

Now that you have a key, you can use it to generate a CVV2 value for a given Primary Account Number (PAN) and expiration date. CVV2 is a security code printed on payment cards that helps verify that the person making a transaction has physical possession of the card.

Run the following command, replacing `<key-arn>` with the KeyArn from the previous step:

```bash
aws payment-cryptography-data generate-card-validation-data \
  --key-identifier <key-arn> \
  --primary-account-number=171234567890123 \
  --generation-attributes CardVerificationValue2={CardExpiryDate=0123}
```

The command generates a CVV2 value based on the provided PAN and expiration date. The response includes:

```json
{
    "KeyArn": "arn:aws:payment-cryptography:us-east-2:123456789012:key/abcd1234",
    "KeyCheckValue": "4A2C40",
    "ValidationData": "163"
}
```

The `ValidationData` field contains the generated CVV2 value (in this example, "163"). This is the three-digit security code that would be printed on the back of a payment card. Make note of this value for the next step.

## Verify the CVV2 value

In a real-world scenario, when a customer enters their CVV2 during a transaction, you need to verify that the entered value matches the expected value. Let's verify the CVV2 value we just generated.

Run the following command, replacing `<key-arn>` with your KeyArn and `<cvv2-value>` with the ValidationData from the previous step:

```bash
aws payment-cryptography-data verify-card-validation-data \
  --key-identifier <key-arn> \
  --primary-account-number=171234567890123 \
  --verification-attributes CardVerificationValue2={CardExpiryDate=0123} \
  --validation-data <cvv2-value>
```

If the verification is successful, you'll receive a response like this:

```json
{
    "KeyArn": "arn:aws:payment-cryptography:us-east-2:123456789012:key/abcd1234",
    "KeyCheckValue": "4A2C40"
}
```

The HTTP 200 response indicates that the CVV2 value was successfully validated. This means the provided CVV2 matches what would be expected for the given PAN and expiration date.

## Perform a negative test

To understand how validation failures work, let's try verifying an incorrect CVV2 value. This simulates what happens when a customer enters the wrong CVV2 during checkout.

Run the following command, using "999" as an incorrect CVV2 value:

```bash
aws payment-cryptography-data verify-card-validation-data \
  --key-identifier <key-arn> \
  --primary-account-number=171234567890123 \
  --verification-attributes CardVerificationValue2={CardExpiryDate=0123} \
  --validation-data 999
```

This will result in an error:

```
An error occurred (VerificationFailedException) when calling the VerifyCardValidationData operation: Card validation data verification failed.
```

The service returns an HTTP 400 response with the message "Card validation data verification failed." This is the expected behavior when an incorrect CVV2 is provided, and your application should handle this error appropriately.

## Clean up resources

If you no longer need the key you created, you should delete it to maintain good security hygiene and avoid ongoing charges. AWS Payment Cryptography implements a waiting period for key deletion to prevent accidental data loss.

Run the following command to schedule the key for deletion:

```bash
aws payment-cryptography delete-key \
  --key-identifier <key-arn>
```

The response will show that the key is scheduled for deletion:

```json
{
    "Key": {
        "KeyArn": "arn:aws:payment-cryptography:us-east-2:123456789012:key/abcd1234",
        "KeyAttributes": {
            "KeyUsage": "TR31_C0_CARD_VERIFICATION_KEY",
            "KeyClass": "SYMMETRIC_KEY",
            "KeyAlgorithm": "TDES_2KEY",
            "KeyModesOfUse": {
                "Encrypt": false,
                "Decrypt": false,
                "Wrap": false,
                "Unwrap": false,
                "Generate": true,
                "Sign": false,
                "Verify": true,
                "DeriveKey": false,
                "NoRestrictions": false
            }
        },
        "KeyCheckValue": "4A2C40",
        "KeyCheckValueAlgorithm": "ANSI_X9_24",
        "Enabled": true,
        "Exportable": true,
        "KeyState": "DELETE_PENDING",
        "KeyOrigin": "AWS_PAYMENT_CRYPTOGRAPHY",
        "CreateTimestamp": "2025-01-13T08:27:51.795000-07:00",
        "DeletePendingTimestamp": "2025-01-20T13:37:12.114000-07:00",
        "UsageStartTimestamp": "2025-01-13T08:27:51.753000-07:00"
    }
}
```

Note that:
- The `DeletePendingTimestamp` is set to seven days in the future by default
- The `KeyState` is set to `DELETE_PENDING`

If you change your mind before the scheduled deletion time, you can cancel the deletion with the following command:

```bash
aws payment-cryptography restore-key --key-identifier <key-arn>
```

## Going to production

This tutorial demonstrates the basic functionality of AWS Payment Cryptography for educational purposes. When implementing payment cryptography in a production environment, consider the following additional aspects:

### Key Management

- **Key Rotation**: Implement regular key rotation policies based on your security requirements and industry standards.
- **Key Exportability**: Only make keys exportable if there's a specific business need, following the principle of least privilege.
- **Multiple Keys**: Use different keys for different purposes or environments (development, testing, production).

### Monitoring and Observability

- Set up CloudWatch metrics and alarms to monitor cryptographic operations.
- Implement logging with CloudTrail for audit and compliance purposes.
- Create operational dashboards to track usage patterns and detect anomalies.

### Scaling and Resilience

- Implement proper error handling and retry strategies for API calls.
- Consider multi-region deployment for global availability and disaster recovery.
- Design your application to handle high volumes of cryptographic operations efficiently.

### Security Best Practices

- Follow the [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/) security pillar guidelines.
- Implement the principle of least privilege for IAM permissions.
- Consider using [AWS KMS](https://docs.aws.amazon.com/kms/latest/developerguide/overview.html) for additional key management capabilities.

For more information on building production-ready applications with AWS Payment Cryptography, refer to:
- [AWS Payment Cryptography Security Best Practices](https://docs.aws.amazon.com/payment-cryptography/latest/userguide/security-best-practices.html)
- [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html)
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)

## Next steps

Now that you've learned the basics of AWS Payment Cryptography, you might want to explore more advanced features:

- Learn about other types of [card data operations](https://docs.aws.amazon.com/payment-cryptography/latest/userguide/card-data-operations.html) such as PIN verification and EMV cryptograms
- Explore [key management](https://docs.aws.amazon.com/payment-cryptography/latest/userguide/key-management.html) features like key import, export, and rotation
- Set up [key aliases](https://docs.aws.amazon.com/payment-cryptography/latest/userguide/key-aliases.html) for easier key management
- Implement [encryption and decryption](https://docs.aws.amazon.com/payment-cryptography/latest/userguide/encrypt-decrypt.html) of sensitive payment data

For more examples and deployment patterns, check out the [AWS Payment Cryptography Workshop](https://catalog.us-east-1.prod.workshops.aws/workshops/b85843d4-a5e4-40fc-9a96-de0a99312a4b/en-US) or explore sample projects on [GitHub](https://github.com/aws-samples/samples-for-payment-cryptography-service).
