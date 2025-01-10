import json

def lambda_handler(event, context):
    # Return a simple message
    return {
        'statusCode': 200,
        'body': json.dumps('Hello, World!')
    }
