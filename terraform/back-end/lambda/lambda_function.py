import json
import boto3

# Get the service resource
dynamodb = boto3.resource('dynamodb')

# Instantiate a table resource object without actually
# creating a DynamoDB table. Note that the attributes of this table
# are lazy-loaded: a request is not made nor are the attribute
# values populated until the attributes
# on the table resource are accessed or its load() method is called
table = dynamodb.Table('visitor_counter_count')

def scan_table_and_add_item():
    response = table.scan()

    if response:
        items = response['Items']
        if not items:
            table.put_item(
                Item={
                    'number_of_visitors': 'number_of_visitors_key',
                    'number_of_visitors_count': 1,
                }
            )
            return True
        else:
            return False
    else:
        return False

def lambda_handler(event, context):
    scan_table_and_add_item()
    # Updating the number_of_visitors_count
    table.update_item(
        Key={
            'number_of_visitors': 'number_of_visitors_key'
        },
        UpdateExpression='SET number_of_visitors_count = number_of_visitors_count + :val1',
        ExpressionAttributeValues={
        ':val1': 1
        }
    )
    
    # Let's see if 'number_of_visitors_count' has been updated
    response = table.get_item(
        Key={
            'number_of_visitors': 'number_of_visitors_key'
        }
    )
    item = response['Item']
    number_of_visitors_count = item['number_of_visitors_count']

    return {
        'statusCode': 200,
        'body': json.dumps('Visitor count: ' + str(number_of_visitors_count)) # Simple access test: table.table_name
    }
