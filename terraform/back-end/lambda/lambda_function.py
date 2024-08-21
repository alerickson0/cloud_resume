"""Lambda function to update a specific DynamoDB table and return its current value"""

import json

import boto3

# Get the service resource
dynamodb = boto3.resource("dynamodb")

# Instantiate a table resource object without actually
# creating a DynamoDB table. Note that the attributes of this table
# are lazy-loaded: a request is not made nor are the attribute
# values populated until the attributes
# on the table resource are accessed or its load() method is called
table = dynamodb.Table("visitor_counter_count")


def scan_table_and_add_item():
    """Method to look in a specific DynamoDB table for a specific item and then create it if
    necessary"""
    response = table.scan()

    if response:
        items = response["Items"]
        if not items:
            table.put_item(
                Item={
                    "number_of_visitors": "number_of_visitors_key",
                    "number_of_visitors_count": 1,
                }
            )
            return True
        return False
    return False


def lambda_handler(event, context):
    """Method to update a specific DynamoDB table's item"""
    if event is not None and context is not None:
        scan_table_and_add_item()
        # Updating the number_of_visitors_count
        table.update_item(
            Key={"number_of_visitors": "number_of_visitors_key"},
            UpdateExpression="SET number_of_visitors_count = number_of_visitors_count + :val1",
            ExpressionAttributeValues={":val1": 1},
        )

        # Let's see if 'number_of_visitors_count' has been updated
        response = table.get_item(Key={"number_of_visitors": "number_of_visitors_key"})
        item = response["Item"]
        number_of_visitors_count = item["number_of_visitors_count"]

        return {
            "statusCode": 200,
            "body": json.dumps("Visitor count: " + str(number_of_visitors_count)),
        }
    return {
        "statusCode": 400,
        "body": json.dumps("event and context were empty or null"),
    }
