import json
import os
from db import insert_event
import boto3

def get_db_credentials(secret_arn):
    client = boto3.client('secretsmanager')
    response = client.get_secret_value(SecretId=secret_arn)
    secret = json.loads(response['SecretString'])

    token = secret["token"]

    return token

def handler(event, context):
    body = json.loads(event["body"])
    event_type = body.get("event_type")
    timestamp = body.get("timestamp")
    
    if not event_type or not timestamp:
        return {
            "statusCode": 400,
            "body": "Missing event_type or timestamp"
        }

    secret_arn = os.environ["SECRET_ARN"]
    
    token = get_db_credentials(secret_arn)

    headers = event.get("headers", {})

    if headers.get("x-api-key") != token:
        print("Unauthorized request")
        return {
            "statusCode": 403,
            "body": json.dumps({"error": "Forbidden"})
        }
    else:
        success = insert_event(event_type, timestamp)

        if success:
            return {
                "statusCode": 200,
                "body": "Event inserted successfully"
            }
        else:
            return {
                "statusCode": 500,
                "body": "Failed to store event"
            }
