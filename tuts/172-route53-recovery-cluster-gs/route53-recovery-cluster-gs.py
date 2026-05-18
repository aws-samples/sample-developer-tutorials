import boto3
import time
import random

suffix = str(int(time.time()))[-6:] + str(random.randint(1, 100))
client = boto3.client('route53-recovery-cluster', region_name='us-east-1')

try:
    print("Listing routing controls:")
    response = client.list_routing_controls()
    print(response)
    
    if 'RoutingControls' in response:
        routing_control_arn = response['RoutingControls'][0]['RoutingControlArn']
        
        print("\nGetting routing control state:")
        state_response = client.get_routing_control_state(RoutingControlArn=routing_control_arn)
        print(state_response)
        
        new_state = 'Off' if state_response['RoutingControlState'] == 'On' else 'On'
        
        print(f"\nUpdating routing control state to {new_state}:")
        update_response = client.update_routing_control_state(RoutingControlArn=routing_control_arn, RoutingControlState=new_state)
        print(update_response)
        
        print("\nGetting updated routing control state:")
        state_response = client.get_routing_control_state(RoutingControlArn=routing_control_arn)
        print(state_response)
    
    print("\nPASS")
    
except Exception as e:
    print(f"An error occurred: {e}")