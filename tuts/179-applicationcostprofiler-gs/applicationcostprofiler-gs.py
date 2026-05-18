import boto3
import time
import random

suffix = str(int(time.time()))[-6:] + str(random.randint(1, 100))
client = boto3.client('applicationcostprofiler', region_name='us-east-1')

try:
    response = client.list_report_definitions()
    print("ListReportDefinitions:", response)

    report_id = response['reportDefinitions'][0]['reportId'] if response['reportDefinitions'] else None
    if report_id:
        response = client.get_report_definition(reportId=report_id)
        print("GetReportDefinition:", response)

    report_name = f"example-report-{suffix}"
    response = client.put_report_definition(
        reportId=f"example-report-id-{suffix}",
        reportDescription="Example report",
        reportType="DIMENSIONAL",
        format="CSV",
        destinationS3Location={"bucket": "example-bucket", "prefix": "example-prefix"},
        reportConfiguration={"timeGranularity": "MONTHLY"}
    )
    print("PutReportDefinition:", response)

    time.sleep(10)  # Wait for the report definition to be created

    response = client.list_report_definitions()
    print("ListReportDefinitions after creation:", response)

    response = client.delete_report_definition(reportId=f"example-report-id-{suffix}")
    print("DeleteReportDefinition:", response)

    print("PASS")
except Exception as e:
    print("FAIL:", e)