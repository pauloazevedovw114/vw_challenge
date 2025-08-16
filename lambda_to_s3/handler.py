import os
import json
import ssl
import pg8000.native
import boto3
from datetime import datetime

ssl_context = ssl.create_default_context()

def get_db_credentials(secret_arn):
    client = boto3.client('secretsmanager')
    response = client.get_secret_value(SecretId=secret_arn)
    secret = json.loads(response['SecretString'])

    username = secret["username"]
    password = secret["password"]
    print(f"Connecting with user={username} to host={os.environ['DB_HOST']}")

    return username, password


def upload_to_s3(message):
    timestamp = datetime.utcnow().strftime("%Y-%m-%dT%H-%M-%S")
    object_key = f"count-{timestamp}.txt"
    s3 = boto3.client("s3")
    bucket_name = "vwchallengebucket"

    try:
        s3.put_object(
            Bucket=bucket_name,
            Key=object_key,
            Body=message.encode("utf-8")
        )
        print(f"Uploaded to s3://{bucket_name}/{object_key}")
    except Exception as e:
        print(f"Failed to upload to S3: {e}")
        conn.close()
        return False


def handler(event, context):
    print("Starting insert_event...")
    secret_arn = os.environ["SECRET_ARN"]
    print(f"Fetching DB credentials from secret: {secret_arn}")
    
    username, password = get_db_credentials(secret_arn)
    print("Credentials retrieved. Attempting DB connection...")

    
    conn = pg8000.native.Connection(
        user=username,
        password=password,
        host=os.environ["DB_HOST"],
        database=os.environ["DB_NAME"],
        port=int(os.environ.get("DB_PORT", 5432)),
        ssl_context=ssl_context
    )

    try:
        result = conn.run("SELECT COUNT(*) as count FROM events")
        count = result[0][0]
        message = f"Total events: {count}"
        upload_to_s3(message)
    except Exception as e:
        print(f"Error creating table: {e}")
        conn.close()
        return False

    

    conn.close()
    return True