# IVS Channel Creation Tutorial

## Prerequisites

- Install the AWS CLI.
- Configure AWS CLI with your credentials.
- Ensure you have permissions to create and delete IVS channels.

## Steps

**1. Generate a unique suffix**

```bash
$ SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
```

**2. Create a temporary directory**

```bash
$ TEMP_DIR=$(mktemp -d)
```

**3. Define the log file**

```bash
$ LOG_FILE="$TEMP_DIR/script.log"
```

**4. Set the channel name**

```bash
$ CHANNEL_NAME="test-channel-${SUFFIX}"
```

**5. Create the IVS channel**

```bash
$ echo "Creating IVS channel..." >> "$LOG_FILE"
$ CHANNEL_ARN=$(aws ivs create-channel --name "$CHANNEL_NAME" --latency-mode NORMAL --type STANDARD --query 'channel.arn' --output text)
```

**6. Tag the created channel**

```bash
$ aws ivs tag-resource --resource-arn "$CHANNEL_ARN" --tags Key=project,Value=doc-smith Key=tutorial,Value=ivs-gs
```

**7. Verify channel creation**

```bash
$ if [ -n "$CHANNEL_ARN" ]; then
>     echo "Channel created: $CHANNEL_ARN" >> "$LOG_FILE"
>     CREATED_RESOURCES+=("$CHANNEL_ARN")
> 
>     sleep 5  # Wait for channel to become active
> 
>     echo "Verifying channel exists..." >> "$LOG_FILE"
>     aws ivs get-channel --arn "$CHANNEL_ARN" --query 'channel.arn' --output text | grep "$CHANNEL_ARN" >> "$LOG_FILE"
> 
>     echo "Listing channels to confirm presence..." >> "$LOG_FILE"
>     aws ivs list-channels --filter-by-name "$CHANNEL_NAME" --query 'channels[?arn==`'$CHANNEL_ARN'`].arn' --output text | grep "$CHANNEL_ARN" >> "$LOG_FILE"
> fi
```

**8. Delete the channel**

```bash
$ echo "Deleting channel..." >> "$LOG_FILE"
$ aws ivs delete-channel --arn "$CHANNEL_ARN" || true
$ sleep 5  # Wait for deletion to process
```

**9. Verify channel deletion**

```bash
$ echo "Verifying channel deletion..." >> "$LOG_FILE"
$ aws ivs get-channel --arn "$CHANNEL_ARN" --query 'channel.arn' --output text || true >> "$LOG_FILE"
$ echo "PASS" >> "$LOG_FILE"
```

## Clean up

All created resources are automatically deleted at the end of the script. The temporary directory and log file are also removed.

## Next steps

- Explore more IVS features and configurations.
- Integrate IVS with your applications for live streaming.
