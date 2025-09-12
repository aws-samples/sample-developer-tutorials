# Getting started with Amazon Kinesis Video Streams using the AWS CLI

This tutorial guides you through the process of creating an Amazon Kinesis Video Streams stream, retrieving endpoints for uploading and viewing video data, and cleaning up resources using the AWS Command Line Interface (AWS CLI).

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI installed and configured. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. Basic familiarity with command line interfaces.
4. Sufficient permissions to create and manage Kinesis Video Streams resources in your AWS account.

### Cost information

This tutorial creates AWS resources that may incur charges to your account. The estimated cost for running the resources in this tutorial for one hour is approximately $0.0183, primarily for the Kinesis video stream. Additional costs may apply if you send video data to the stream:
- Data ingestion: $0.017 per GB
- Storage: $0.023 per GB-month
- Retrieval: $0.002 per GB

To avoid ongoing charges, follow the cleanup instructions at the end of this tutorial.

## Create a Kinesis video stream

First, you'll create a Kinesis video stream that will store and process your video data. The stream acts as a resource that continuously captures, processes, and stores video data.

The following command creates a new Kinesis video stream with a 24-hour data retention period, and save this ARN to a variable for easy reference:

```
$ STREAM_ARN=$(aws kinesisvideo create-stream --stream-name "MyKinesisVideoStream" --data-retention-in-hours 24 --query "StreamARN" --output text)
```

After running this command, you'll receive a response containing the stream's Amazon Resource Name (ARN):

```
{
    "StreamARN": "arn:aws:kinesisvideo:us-west-2:123456789012:stream/MyKinesisVideoStream/1234567890123"
}
```

The stream ARN uniquely identifies your stream and will be used in subsequent commands.



## Verify stream creation

After creating your stream, you should verify that it was created successfully and check its details. This helps confirm that the stream is active and properly configured.

Use the following command to retrieve information about your stream:

```
$ aws kinesisvideo describe-stream --stream-name "MyKinesisVideoStream"
```

The response includes detailed information about your stream:

```
{
    "StreamInfo": {
        "StreamName": "MyKinesisVideoStream",
        "StreamARN": "arn:aws:kinesisvideo:us-west-2:123456789012:stream/MyKinesisVideoStream/1234567890123",
        "KmsKeyId": "arn:aws:kms:us-west-2:123456789012:alias/aws/kinesisvideo",
        "Version": "abcd1234",
        "Status": "ACTIVE",
        "CreationTime": 1673596800.0,
        "DataRetentionInHours": 24
    }
}
```

You can also list all the Kinesis video streams in your account to see your newly created stream along with any existing ones:

```
$ aws kinesisvideo list-streams
```

The response will include a list of all your streams:

```
{
    "StreamInfoList": [
        {
            "StreamName": "MyKinesisVideoStream",
            "StreamARN": "arn:aws:kinesisvideo:us-west-2:123456789012:stream/MyKinesisVideoStream/1234567890123",
            "KmsKeyId": "arn:aws:kms:us-west-2:123456789012:alias/aws/kinesisvideo",
            "Version": "abcd1234",
            "Status": "ACTIVE",
            "CreationTime": 1673596800.0,
            "DataRetentionInHours": 24
        }
    ]
}
```

## Get data endpoints

Before you can send video data to your stream or retrieve video for playback, you need to get the appropriate data endpoints. Kinesis Video Streams provides different endpoints for different operations.

**Get the endpoint for uploading video data**

To upload video data to your stream, you need the PUT_MEDIA endpoint:

```
$ aws kinesisvideo get-data-endpoint --stream-name "MyKinesisVideoStream" --api-name PUT_MEDIA
```

The response includes the endpoint URL:

```
{
    "DataEndpoint": "https://s-abcd1234.kinesisvideo.us-west-2.amazonaws.com"
}
```

You can save this endpoint to a variable for later use:

```
$ PUT_ENDPOINT=$(aws kinesisvideo get-data-endpoint --stream-name "MyKinesisVideoStream" --api-name PUT_MEDIA --query "DataEndpoint" --output text)
```

**Get the endpoint for viewing video data**

To view your video stream using HLS (HTTP Live Streaming), you need the GET_HLS_STREAMING_SESSION_URL endpoint:

```
$ aws kinesisvideo get-data-endpoint --stream-name "MyKinesisVideoStream" --api-name GET_HLS_STREAMING_SESSION_URL
```

The response includes the endpoint URL:

```
{
    "DataEndpoint": "https://b-abcd1234.kinesisvideo.us-west-2.amazonaws.com"
}
```

You can save this endpoint to a variable as well:

```
$ HLS_ENDPOINT=$(aws kinesisvideo get-data-endpoint --stream-name "MyKinesisVideoStream" --api-name GET_HLS_STREAMING_SESSION_URL --query "DataEndpoint" --output text)
```

## Send data to your Kinesis video stream

To send video data to your Kinesis video stream, you'll need to use the Kinesis Video Streams Producer SDK. The SDK provides libraries and tools for capturing, encoding, and streaming video to your Kinesis video stream.

The most common way to send video data is using the GStreamer framework with the Kinesis Video Streams GStreamer plugin. This requires setting up the development environment and building the necessary components.

Here's a high-level overview of the process:

1. Install the required dependencies
2. Clone and build the Kinesis Video Streams Producer SDK
3. Configure your AWS credentials as environment variables
4. Use the GStreamer plugin to send video data

For detailed instructions on setting up the Producer SDK and sending video data, refer to the [Kinesis Video Streams Producer Libraries](https://docs.aws.amazon.com/kinesisvideostreams/latest/dg/producer-sdk.html) documentation.

## View your video stream

You can view your video stream either through the AWS Management Console or programmatically using the HLS endpoint.

**View in the AWS Management Console**

1. Open the Kinesis Video Streams console
2. Select your stream from the list
3. Expand the Media playback section to view your video

**View programmatically using HLS**

To view your stream programmatically, you first need to get an HLS streaming session URL using the endpoint you retrieved earlier:

```
$ aws kinesis-video-archived-media get-hls-streaming-session-url \
  --endpoint-url $HLS_ENDPOINT \
  --stream-name "MyKinesisVideoStream" \
  --playback-mode LIVE
```

The response includes the HLS URL that you can use in a video player:

```
{
    "HLSStreamingSessionURL": "https://b-abcd1234.kinesisvideo.us-west-2.amazonaws.com/hls/v1/getHLSMasterPlaylist.m3u8?SessionToken=CiAx..."
}
```

You can use this URL in any HLS-compatible video player to view your stream.

## Troubleshooting

Here are some common issues you might encounter when working with Kinesis Video Streams and how to resolve them:

**Stream not active**

If your stream doesn't become active immediately after creation, wait a few moments and check again:

```
$ aws kinesisvideo describe-stream --stream-name "MyKinesisVideoStream"
```

**Permission denied errors**

If you receive permission denied errors, verify that your IAM user or role has the necessary permissions to work with Kinesis Video Streams. You might need the following permissions:
- kinesisvideo:CreateStream
- kinesisvideo:DescribeStream
- kinesisvideo:GetDataEndpoint
- kinesisvideo:DeleteStream

**Endpoint connection issues**

If you have trouble connecting to the data endpoints, ensure that:
1. You're using the correct endpoint for the operation
2. Your AWS credentials are properly configured
3. Your network allows connections to the endpoint

## Clean up resources

When you're done with your Kinesis video stream, you should delete it to avoid incurring unnecessary charges. Use the following command to delete your stream:

```
$ aws kinesisvideo delete-stream --stream-arn $STREAM_ARN
```

This command doesn't produce any output if successful. You can verify that the stream was deleted by listing your streams again:

```
$ aws kinesisvideo list-streams
```

If the deletion was successful, your stream should no longer appear in the list.

## Going to production

This tutorial is designed to help you learn how to use the Kinesis Video Streams API, not to build a production-ready application. When moving to a production environment, consider the following best practices:

### Security considerations

1. **IAM permissions**: Follow the principle of least privilege by creating IAM roles with only the permissions needed for your specific use case.

2. **Credential management**: Instead of using environment variables for AWS credentials, use IAM roles for EC2 instances or container tasks, or the AWS credential provider chain.

3. **Network security**: Consider using VPC endpoints for Kinesis Video Streams to keep traffic within the AWS network.

4. **Encryption**: While Kinesis Video Streams encrypts data at rest by default, review your encryption requirements and consider using customer-managed KMS keys for additional control.

5. **Monitoring and auditing**: Set up AWS CloudTrail to monitor API calls and CloudWatch to monitor stream metrics.

### Architecture considerations

1. **Scaling**: Design your producer and consumer applications to handle multiple streams and high volumes of video data.

2. **Error handling**: Implement robust error handling and retry mechanisms in your producer and consumer applications.

3. **Monitoring**: Set up CloudWatch alarms to monitor stream health and performance.

4. **Cost optimization**: Optimize your video encoding and retention settings based on your specific requirements.

For more information on building production-ready applications with AWS services, refer to:
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)
- [AWS Architecture Center](https://aws.amazon.com/architecture/)

## Next steps

Now that you've learned the basics of working with Amazon Kinesis Video Streams using the AWS CLI, you can explore more advanced features:

- Learn how to [process video streams with AWS Lambda](https://docs.aws.amazon.com/kinesisvideostreams/latest/dg/examples-lambda.html)
- Explore [stream parsing with the Kinesis Video Streams Parser Library](https://docs.aws.amazon.com/kinesisvideostreams/latest/dg/parser-library.html)
- Set up [real-time video analytics using Amazon Rekognition](https://docs.aws.amazon.com/kinesisvideostreams/latest/dg/kv-rekognition.html)
- Implement [secure streaming with encrypted streams](https://docs.aws.amazon.com/kinesisvideostreams/latest/dg/how-kms.html)
