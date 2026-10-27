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
        # Atomic update: adds 1 in a single call, so two visits at the same time
        # can't overwrite each other. If the item doesn't exist yet, it starts at 0.
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

        # Response shape for an API Gateway proxy integration
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
        # Re-raise so Lambda records a failed invocation. Returning a 500 here
        # would count as a success, and the CloudWatch Errors alarm would never fire.
        raise
