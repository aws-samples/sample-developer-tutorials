import boto3
import time
import random

suffix = str(int(time.time()))[-6:] + str(random.randint(1, 100))
client = boto3.client('simpledbv2', region_name='us-east-1')

try:
    # List exports
    response = client.list_exports()
    print("ListExports:", response)
    
    # Start domain export
    domain_export_name = f"example-domain-export-{suffix}"
    response = client.start_domain_export(DomainExportName=domain_export_name, DomainName="example-domain")
    print("StartDomainExport:", response)
    
    # Get export
    export_id = response['ExportId']
    response = client.get_export(ExportId=export_id)
    print("GetExport:", response)
    
    print("PASS")
except Exception as e:
    print("Error:", e)

finally:
    # Clean up
    try:
        client.delete_domain_export(DomainExportName=domain_export_name)
        print("Cleaned up domain export")
    except:
        pass