import os
import json
import ssl
import pg8000.native
import boto3

ssl_context = ssl.create_default_context()

def get_db_credentials(secret_arn):
    client = boto3.client('secretsmanager')
    response = client.get_secret_value(SecretId=secret_arn)
    secret = json.loads(response['SecretString'])

    username = secret["username"]
    password = secret["password"]
    print(f"Connecting with user={username} to host={os.environ['DB_HOST']}")

    return username, password

def insert_event(event_type, timestamp):
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
    # Create table if not exists
    create_table_sql = """
    CREATE TABLE IF NOT EXISTS events (
        id SERIAL PRIMARY KEY,
        event_type VARCHAR(50) NOT NULL,
        timestamp TIMESTAMP NOT NULL
    );
    """
    try:
        conn.run(create_table_sql)
        print("Table 'events' ensured.")
    except Exception as e:
        print(f"Error creating table: {e}")
        conn.close()
        return False

    # Insert event
    print(f"Inserting event_type={event_type}, timestamp={timestamp} ({type(event_type)}, {type(timestamp)})")
    event = event_type
    time = timestamp
    try:
        #conn.run("INSERT INTO events (event_type, timestamp) VALUES ('login', '2025-08-15T14:00:00Z')")
        query = f"INSERT INTO events (event_type, timestamp) VALUES ('{event_type}', '{timestamp}')"
        conn.run(query)
        print("Insert successful.")
    except Exception as e:
        print(f"DB insert error: {e}")
        conn.close()
        return False
    
    rows = conn.run("SELECT id, event_type, timestamp FROM events")
    for row in rows:
        print(row)
    

    conn.close()
    return True