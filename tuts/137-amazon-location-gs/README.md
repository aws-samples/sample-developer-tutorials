# Amazon Location Gs

An AWS CLI tutorial that demonstrates Location operations.

## Running

```bash
bash amazon-location-gs.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash amazon-location-gs.sh
```

## What it does

1. Creating map: $MAP_NAME
2. Creating place index: $INDEX_NAME
3. Searching for a place
4. Reverse geocoding
5. Listing maps

## Resources created

- Map
- Place Index

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI location reference](https://docs.aws.amazon.com/cli/latest/reference/location/index.html)

