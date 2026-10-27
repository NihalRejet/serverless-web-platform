import json
import os
import boto3

# Initialize DynamoDB outside the handler so it can be reused across invocations
dynamodb = boto3.resource('dynamodb')

# Fetch the table name from the environment variable instead of hardcoding it
TABLE_NAME = os.environ.get('TABLE_NAME')
table = dynamodb.Table(TABLE_NAME)

def lambda_handler(event, context):
    try:
        # Atomic update: Adds 1 to the count, creating the attribute at 0 if missing
        response = table.update_item(
            Key={
                'id': 'visits'
            },
            UpdateExpression='ADD visits :inc',
            ExpressionAttributeValues={
                ':inc': 1
            },
            ReturnValues='UPDATED_NEW'
        )

        # DynamoDB returns numbers as a Decimal type. Cast it to an int so json.dumps works.
        visit_count = int(response['Attributes']['visits'])

        # Return the exact dictionary format required by API Gateway
        return {
            "statusCode": 200,
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Content-Type": "application/json"
            },
            "body": json.dumps({"count": visit_count})
        }

    except Exception as e:
        print(f"Error: {e}")
        raise
