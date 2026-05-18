import boto3
import time
import random

suffix = str(int(time.time()))[-6:] + str(random.randint(1, 100))
client = boto3.client('keyspacesstreams', region_name='us-east-1')

try:
    response = client.list_streams()
    print("ListStreams:", response)

    if 'streams' in response:
        stream_name = response['streams'][0]['streamName']
        shard_id = response['streams'][0]['shards'][0]['shardId']
        
        shard_iterator = client.get_shard_iterator(
            streamName=stream_name,
            shardId=shard_id,
            shardIteratorType='TRIM_HORIZON'
        )
        shard_iterator_arn = shard_iterator['shardIterator']

        records = client.get_records(
            shardIterator=shard_iterator_arn,
            limit=10
        )
        print("GetRecords:", records)

        stream_details = client.get_stream(
            streamName=stream_name
        )
        print("GetStream:", stream_details)

    print("PASS")
except Exception as e:
    print("Error:", e)