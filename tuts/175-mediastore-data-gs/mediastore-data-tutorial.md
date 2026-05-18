# Tutorial for Getting Started with Mediastore Data

## Prerequisites
- An AWS account
- Python installed
- Boto3 library installed
- An AWS Elemental MediaStore container created (e.g., `example-container`)
- A file named `example-file.txt` in your working directory

## Steps

1. **Set up your environment**

    Ensure you have the necessary packages installed:
    ```bash
    pip install boto3
    ```

2. **Initialize the MediaStore Data client**

    ```python
    import boto3
    import time
    import random

    suffix = str(int(time.time()))[-6:] + str(random.randint(1, 100))
    client = boto3.client('mediastore-data', region_name='us-east-1')
    ```

3. **List items in the container**

    ```python
    try:
        response = client.list_items(ContainerName='example-container')
        print("ListItems:", response)
    except Exception as e:
        print("Error:", e)
    ```

4. **Describe an object**

    ```python
    object_name = 'example-object'
    try:
        response = client.describe_object(ContainerName='example-container', Path=f'/{object_name}')
        print("DescribeObject:", response)
    except Exception as e:
        print("Error:", e)
    ```

5. **Get an object**

    ```python
    try:
        response = client.get_object(ContainerName='example-container', Path=f'/{object_name}')
        print("GetObject:", response)
    except Exception as e:
        print("Error:", e)
    ```

6. **Put an object**

    ```python
    object_name_with_suffix = f'example-object-{suffix}'
    try:
        with open('example-file.txt', 'rb') as file_data:
            client.put_object(
                ContainerName='example-container', 
                Path=f'/{object_name_with_suffix}', 
                Body=file_data, 
                Tags=[{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'mediastore-data-gs'}]
            )
    except Exception as e:
        print("Error:", e)
    ```

7. **Describe the new object**

    ```python
    try:
        response = client.describe_object(ContainerName='example-container', Path=f'/{object_name_with_suffix}')
        print("DescribeObject (new):", response)
    except Exception as e:
        print("Error:", e)
    ```

8. **Delete the object**

    ```python
    try:
        client.delete_object(ContainerName='example-container', Path=f'/{object_name_with_suffix}')
        print("Object deleted successfully")
    except Exception as e:
        print("Error:", e)
    ```

## Clean up
Ensure you delete any objects or containers you created to avoid unnecessary charges.

## Next steps
Explore more features of AWS Elemental MediaStore, such as setting object lifecycle policies or integrating with other AWS services.