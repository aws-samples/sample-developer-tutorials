# Getting started with Amazon Polly using the AWS CLI

This tutorial guides you through the process of using Amazon Polly with the AWS Command Line Interface (AWS CLI). Amazon Polly is a service that turns text into lifelike speech, allowing you to create applications that talk and build entirely new categories of speech-enabled products.

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. [Sufficient permissions](https://docs.aws.amazon.com/polly/latest/dg/security_iam_service-with-iam.html) to use Amazon Polly in your AWS account.

**Cost Information**: This tutorial uses Amazon Polly, which offers a Free Tier for the first 12 months of your AWS account. The Free Tier includes 5 million characters per month for standard voices and 1 million characters per month for neural voices. The examples in this tutorial use approximately 150 characters, which would cost less than $0.001 if you're not using the Free Tier.

Let's get started with using Amazon Polly through the AWS CLI.

## Explore available voices

Amazon Polly provides multiple voices in various languages. Let's explore the available voices before converting text to speech.

**List all available voices**

To list all available voices in Amazon Polly:

```bash
aws polly describe-voices
```

This command returns a list of all available voices with details such as language code, gender, and name. The output will be quite long as Amazon Polly supports many voices across different languages.

**Filter voices by language**

To filter voices by a specific language (for example, English - US):

```bash
aws polly describe-voices --language-code en-US
```

This command returns only the voices that support US English. You'll see output similar to this:

```json
{
    "Voices": [
        {
            "Gender": "Female",
            "Id": "Joanna",
            "LanguageCode": "en-US",
            "LanguageName": "US English",
            "Name": "Joanna",
            "SupportedEngines": [
                "neural",
                "standard"
            ]
        },
        {
            "Gender": "Female",
            "Id": "Salli",
            "LanguageCode": "en-US",
            "LanguageName": "US English",
            "Name": "Salli",
            "SupportedEngines": [
                "neural",
                "standard"
            ]
        },
        {
            "Gender": "Male",
            "Id": "Matthew",
            "LanguageCode": "en-US",
            "LanguageName": "US English",
            "Name": "Matthew",
            "SupportedEngines": [
                "neural",
                "standard"
            ]
        }
    ]
}

Take note of the voice IDs (like "Joanna" or "Matthew") as you'll need them in the next steps.

## Convert text to speech

Now that you've explored the available voices, let's convert some text to speech and save it as an audio file.

**Basic text-to-speech conversion**

Run the following command to convert a simple text phrase to speech:

```bash
aws polly synthesize-speech \
    --output-format mp3 \
    --voice-id Joanna \
    --text "Hello, welcome to Amazon Polly. This is a sample text to speech conversion." \
    output.mp3
```

This command:
- Uses the `synthesize-speech` operation
- Specifies MP3 as the output format
- Uses the "Joanna" voice (a female English US voice)
- Converts the provided text to speech
- Saves the audio to a file named "output.mp3"

After running this command, you'll have an MP3 file that you can play with any audio player on your system. The command will output information like this:

```json
{
    "ContentType": "audio/mpeg",
    "RequestCharacters": 75
}
```

This confirms that the speech was synthesized successfully and shows how many characters were processed.

## Use SSML for enhanced speech

Speech Synthesis Markup Language (SSML) gives you more control over how Amazon Polly generates speech from the text you provide.

**Converting SSML text to speech**

Run the following command to use SSML features:

```bash
aws polly synthesize-speech \
    --output-format mp3 \
    --voice-id Matthew \
    --text-type ssml \
    --text "<speak>Hello! <break time='1s'/> This is a sample of <emphasis>SSML enhanced speech</emphasis>.</speak>" \
    ssml-output.mp3
```

This command:
- Specifies that the input text is SSML format using the `--text-type ssml` parameter
- Uses SSML tags to add a 1-second pause (`<break time='1s'/>`) and emphasis (`<emphasis>`)
- Uses the "Matthew" voice (a male English US voice)
- Saves the output to a file named "ssml-output.mp3"

SSML allows you to control aspects like pauses, pronunciation, volume, pitch, and more. This gives you finer control over the speech output.

**Tip**: When using SSML, make sure your XML is well-formed. Missing closing tags or incorrect syntax will cause errors.

## Work with lexicons

Lexicons allow you to customize how Amazon Polly pronounces specific words or phrases. This is particularly useful for acronyms, brand names, or technical terms.

**Create a lexicon file**

First, create a lexicon file that defines custom pronunciations. You can create the file directly from the command prompt using the following command:

```bash
cat << 'EOF' > example.pls
<?xml version="1.0" encoding="UTF-8"?>
<lexicon version="1.0"
      xmlns="http://www.w3.org/2005/01/pronunciation-lexicon"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="http://www.w3.org/2005/01/pronunciation-lexicon
        http://www.w3.org/TR/2007/CR-pronunciation-lexicon-20071212/pls.xsd"
      alphabet="ipa"
      xml:lang="en-US">
  <lexeme>
    <grapheme>AWS</grapheme>
    <alias>Amazon Web Services</alias>
  </lexeme>
</lexicon>
EOF
```

This command creates a file named `example.pls` with the XML content that defines how to pronounce "AWS".

This lexicon defines that the acronym "AWS" should be pronounced as "Amazon Web Services" instead of as individual letters.

**Upload the lexicon**

Upload the lexicon to Amazon Polly:

```bash
aws polly put-lexicon --name exampleLexicon --content file://example.pls
```

This command uploads your lexicon with the name "exampleLexicon". Note that lexicon names must be alphanumeric and no longer than 20 characters.

**List available lexicons**

To see all lexicons in your account:

```bash
aws polly list-lexicons
```

This command returns a list of all lexicons you've uploaded, similar to:

```
{
    "Lexicons": [
        {
            "Name": "exampleLexicon",
            "Attributes": {
                "Alphabet": "ipa",
                "LanguageCode": "en-US",
                "LastModified": "2025-07-17T20:40:31.922000+00:00",
                "LexiconArn": "arn:aws:polly:us-east-1:123456789012:lexicon/examplelexicon",
                "LexemesCount": 1,
                "Size": 486
            }
        }
    ]
}

```

**Get details about a specific lexicon**

To get details about a specific lexicon:

```bash
aws polly get-lexicon --name exampleLexicon
```

This command returns detailed information about the specified lexicon, including its attributes and content.

**Use the lexicon when synthesizing speech**

Now, use the lexicon when converting text to speech:

```bash
aws polly synthesize-speech \
    --output-format mp3 \
    --voice-id Joanna \
    --lexicon-names exampleLexicon \
    --text "I work with AWS every day." \
    lexicon-output.mp3
```

This command uses your custom lexicon when synthesizing speech. When you play the resulting audio file, you'll hear "I work with Amazon Web Services every day" instead of "I work with A-W-S every day".


## Clean up resources

After completing this tutorial, you may want to clean up the resources you created.

**Delete lexicons**

To delete your lexicon:

```bash
aws polly delete-lexicon --name exampleLexicon
```

This command removes the lexicon from your Amazon Polly resources. The local audio files (output.mp3, ssml-output.mp3, and lexicon-output.mp3) will remain on your system. You can delete them manually if you no longer need them.

## Going to production

This tutorial demonstrates basic Amazon Polly functionality for educational purposes. When implementing Amazon Polly in a production environment, consider these additional factors:

1. **IAM Permissions**: Use the principle of least privilege by creating IAM policies that grant only the permissions needed for your specific use case. See [Identity-based policies for Amazon Polly](https://docs.aws.amazon.com/polly/latest/dg/security_iam_id-based-policy-examples.html).

2. **Scaling Considerations**: For large-scale applications:
   - Use asynchronous processing with `start-speech-synthesis-task` for longer text
   - Implement caching strategies for frequently used speech outputs
   - Be aware of [Amazon Polly service quotas](https://docs.aws.amazon.com/polly/latest/dg/limits.html)

3. **Error Handling**: Implement robust error handling and retry mechanisms for production applications.

4. **Integration**: Consider how Amazon Polly will integrate with your broader application architecture, including storage solutions for audio files and delivery mechanisms to end users.

For more information on building production-ready applications on AWS, refer to the [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/).

## Next steps

Now that you've learned the basics of using Amazon Polly with the AWS CLI, you can explore more advanced features:

1. **Neural voices** - Use [neural text-to-speech voices](https://docs.aws.amazon.com/polly/latest/dg/NTTS-main.html) for even more natural-sounding speech.
2. **Long-form synthesis** - Process [longer text content](https://docs.aws.amazon.com/polly/latest/dg/asynchronous.html) using asynchronous synthesis.
3. **Speech marks** - Generate [metadata about the speech](https://docs.aws.amazon.com/polly/latest/dg/speechmarks.html) for visual animations or highlighting.
4. **Custom pronunciations** - Create more complex [pronunciation lexicons](https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html) for your specific use case.
5. **Brand Voice** - Develop a [custom voice](https://docs.aws.amazon.com/polly/latest/dg/brand-voice.html) that represents your brand identity.

For more information about available AWS CLI commands for Amazon Polly, see the [AWS CLI Command Reference for Amazon Polly](https://docs.aws.amazon.com/cli/latest/reference/polly/index.html).
