# S3 Outposts Tutorial

## Prerequisites

- Aws account
- Aws cli installed and configured
- Python installed
- Boto3 python library installed

## Steps

**1. List outposts with s3**

```bash
$ python script.py
```

**Output:**

```python
{'Outposts': [{'OutpostId': 'op-1234567890abcdef0', 'OutpostArn': 'arn:aws:outposts:us-east-1:123456789012:outpost/op-1234567890abcdef0'}]}
```

**2. List endpoints**

```bash
$ python script.py
```

**Output:**

```python
{'Endpoints': [{'EndpointId': 'ep-12345678', 'EndpointArn': 'arn:aws:s3outposts:us-east-1:123456789012:endpoint/ep-12345678'}]}
```

**3. List shared endpoints**

```bash
$ python script.py
```

**Output:**

```python
{'SharedEndpoints': [{'EndpointId': 'ep-12345678', 'EndpointArn': 'arn:aws:s3outposts:us-east-1:123456789012:endpoint/ep-12345678'}]}
```

**4. Create endpoint**

```bash
$ python script.py
```

**Output:**

```python
{'EndpointId': 'ep-12345678'}
```

**5. List endpoints after creation**

```bash
$ python script.py
```

**Output:**

```python
{'Endpoints': [{'EndpointId': 'ep-12345678', 'EndpointArn': 'arn:aws:s3outposts:us-east-1:123456789012:endpoint/ep-12345678'}]}
```

**6. Delete endpoint**

```bash
$ python script.py
```

**Output:**

```python
{}
```

**7. List endpoints after deletion**

```bash
$ python script.py
```

**Output:**

```python
{'Endpoints': []}
```

## Clean up

- Review and delete any aws resources created during this tutorial to avoid unnecessary costs.

## Next steps

- Explore more s3 outposts features and functionalities.
- Refer to the [aws documentation](https://docs.aws.amazon.com/s3-outposts/latest/userguide/what-is-s3-outposts.html) for detailed information.