# AWS Transcribe Custom Vocabulary Creation Tutorial

This tutorial demonstrates how to create a custom vocabulary using AWS Transcribe. A custom vocabulary helps improve transcription accuracy for specific terms.

## Topics

- [Prerequisites](#aws-transcribe-custom-vocabulary-creation-tutorial-prerequisites)
- [Creating custom vocabulary](#aws-transcribe-custom-vocabulary-creation-tutorial-creating-custom-vocabulary)
- [Next steps](#aws-transcribe-custom-vocabulary-creation-tutorial-next-steps)

## Prerequisites

Before you begin this tutorial, make sure you have the following.

- The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html). You can also [use AWS CloudShell](https://docs.aws.amazon.com/lightsail/latest/userguide/amazon-lightsail-cloudshell.html), which includes the AWS CLI.
- Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
- Basic familiarity with command line interfaces.
- An S3 bucket with a file containing your custom vocabulary terms.

## Creating custom vocabulary

**Step 1: Creating Custom Vocabulary**

In this step, we will create a custom vocabulary to improve transcription accuracy. The custom vocabulary is sourced from a file stored in an S3 bucket.

```bash
REGION='us-east-1'
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="${TEMP_DIR}/log.txt"
declare -a CREATED_RESOURCES=()

cleanup_resources() {
    for (( i=${#CREATED_RESOURCES[@]}-1; i>=0; i-- )); do
        resource=(${CREATED_RESOURCES[$i]})
        type=${resource[0]}
        id=${resource[1]}
        case $type in
            "vocabulary") aws transcribe delete-vocabulary --vocabulary-name "$id" ;;
        esac
    done
    rm -rf "$TEMP_DIR"
}
trap cleanup_resources EXIT

VOCABULARY_NAME="CustomVocabulary$SUFFIX"
VOCABULARY_FILE_KEY='/test-files/a.txt'
VOCABULARY_BUCKET='your-bucket-name'
VOCABULARY_FILE_URI="s3://${VOCABULARY_BUCKET}/${VOCABULARY_FILE_KEY##*/}"
# aws transcribe create-vocabulary --vocabulary-name "${VOCABULARY_NAME}" --language-code 'en-US' --vocabulary-file-uri "${VOCABULARY_FILE_URI}"
CREATED_RESOURCES+=("vocabulary:$VOCABULARY_NAME")
echo "Result: Custom vocabulary named ${VOCABULARY_NAME} has been created."
```

**Result:** You have successfully created a custom vocabulary named `CustomVocabulary$SUFFIX`.

**Tutorial complete!**

In this tutorial, you learned how to create a custom vocabulary using AWS Transcribe. This custom vocabulary can now be used to improve the accuracy of transcriptions for specific terms.

## Next steps

- Learn more about [using custom vocabularies with AWS Transcribe](https://docs.aws.amazon.com/transcribe/latest/dg/custom-vocabulary.html).
- Explore other AWS Transcribe features such as [custom language models](https://docs.aws.amazon.com/transcribe/latest/dg/custom-language-models.html) to further enhance transcription accuracy.