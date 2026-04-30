# Synthesize speech from text with Amazon Polly

## Overview

In this tutorial, you use the AWS CLI to synthesize speech from text using Amazon Polly. You list available voices, generate audio with the standard and neural engines, use SSML markup to control speech, list supported languages, and synthesize speech in Spanish.

## Prerequisites

- AWS CLI installed and configured with appropriate permissions.
- An IAM principal with permissions for `polly:DescribeVoices` and `polly:SynthesizeSpeech`.

## Step 1: List available voices

List English voices available in Amazon Polly.

```bash
aws polly describe-voices --language-code en-US \
    --query 'Voices[:5].{Name:Name,Gender:Gender,Engine:SupportedEngines[0]}' --output table
```

Each voice supports one or more engines: `standard`, `neural`, or `generative`. Neural voices sound more natural but are available for fewer languages.

## Step 2: Synthesize speech with the standard engine

Generate an MP3 file from plain text using the Joanna voice.

```bash
aws polly synthesize-speech \
    --text "Hello! This is Amazon Polly synthesizing speech from text." \
    --output-format mp3 \
    --voice-id Joanna \
    standard.mp3 > /dev/null
```

The `synthesize-speech` command writes audio directly to the output file. Supported formats are `mp3`, `ogg_vorbis`, and `pcm`.

## Step 3: Synthesize speech with the neural engine

Use the `--engine neural` flag for more natural-sounding speech.

```bash
aws polly synthesize-speech \
    --text "This is the neural engine. It sounds more natural and expressive." \
    --output-format mp3 \
    --voice-id Joanna \
    --engine neural \
    neural.mp3 > /dev/null
```

Neural voices use a different pricing tier than standard voices. Not all voices support the neural engine.

## Step 4: Synthesize with SSML markup

Use SSML to control emphasis, pauses, speech rate, and pitch.

```bash
aws polly synthesize-speech \
    --text-type ssml \
    --text '<speak>Welcome to <emphasis level="strong">Amazon Polly</emphasis>. <break time="500ms"/> You can control <prosody rate="slow">speech rate</prosody> and <prosody pitch="high">pitch</prosody>.</speak>' \
    --output-format mp3 \
    --voice-id Joanna \
    ssml.mp3 > /dev/null
```

SSML tags supported by Polly include `<break>`, `<emphasis>`, `<prosody>`, `<say-as>`, and `<phoneme>`. Set `--text-type ssml` when using SSML input.

## Step 5: List available languages

Query the unique languages supported by Polly.

```bash
aws polly describe-voices --query 'Voices[].LanguageName' --output text \
    | tr '\t' '\n' | sort -u | head -10
```

Polly supports dozens of languages and regional variants. Each language has one or more voices.

## Step 6: Synthesize in Spanish

Use a Spanish voice to synthesize text in another language.

```bash
aws polly synthesize-speech \
    --text "Hola, esto es Amazon Polly hablando en español." \
    --output-format mp3 \
    --voice-id Lucia \
    spanish.mp3 > /dev/null
```

Match the voice to the language of the text. Lucia is a Castilian Spanish voice.

## Cleanup

No cleanup needed. Polly is a stateless API — no AWS resources are created. Delete the local MP3 files when you no longer need them.

The script automates all steps:

```bash
bash amazon-polly-gs.sh
```

## Related resources

- [Getting started with Amazon Polly](https://docs.aws.amazon.com/polly/latest/dg/getting-started-cli.html)
- [Voices in Amazon Polly](https://docs.aws.amazon.com/polly/latest/dg/voicelist.html)
- [Using SSML](https://docs.aws.amazon.com/polly/latest/dg/ssml.html)
- [Supported languages](https://docs.aws.amazon.com/polly/latest/dg/SupportedLanguage.html)
