import os
import json
import boto3
from uuid import uuid4

region_name = os.environ.get('AWS_REGION', 'us-west-1') 
dynamodb = boto3.resource('dynamodb', region_name=region_name)
table = dynamodb.Table('BudgetItems')

def lambda_handler(event, context):
    print('Received event:', json.dumps(event, indent=2))


    method = event.get('httpMethod', '')
    
    if method == 'POST':
        try:
            body = json.loads(event.get('body', '{}'))

            required_fields = ['description', 'amount', 'date']
            if not all(field in body for field in required_fields):
                return {
                    "statusCode": 400,
                    "headers": {"Access-Control-Allow-Origin": "*",
                        "Access-Control-Allow-Headers": "*",
                        "Access-Control-Allow-Methods": "OPTIONS,*"
                        },
                    "body": json.dumps({"message": "Missing required fields"})
                }

            body['BudgetTrackerKey'] = str(uuid4())

            table.put_item(Item=body)

            return {
                "statusCode": 200,
                "headers": {"Access-Control-Allow-Origin": "*",
                    "Access-Control-Allow-Headers": "*",
                    "Access-Control-Allow-Methods": "OPTIONS,*"
                    },
                "body": json.dumps({"message": "Success", "item": body})
            }

        except Exception as e:
            print(e)
            return {
                "statusCode": 500,
                "headers": {"Access-Control-Allow-Origin": "*",
                    "Access-Control-Allow-Headers": "*",
                    "Access-Control-Allow-Methods": "OPTIONS,*"
                    },
                "body": json.dumps({"message": str(e)})
            }

    elif method == 'GET':
        try:
            response = table.scan()
            items = response.get('Items', [])
            return {
                "statusCode": 200,
                "headers": {"Access-Control-Allow-Origin": "*",
                    "Access-Control-Allow-Headers": "*",
                    "Access-Control-Allow-Methods": "OPTIONS,*"
                    },
                "body": json.dumps(items)
            }

        except Exception as e:
            print(e)
            return {
                "statusCode": 500,
                "headers": {"Access-Control-Allow-Origin": "*",
                    "Access-Control-Allow-Headers": "*",
                    "Access-Control-Allow-Methods": "OPTIONS,*"
                    },
                "body": json.dumps({"message": str(e)})
            }

    else:
        return {
            "statusCode": 405,
            "headers": {"Access-Control-Allow-Origin": "*",
                    "Access-Control-Allow-Headers": "*",
                    "Access-Control-Allow-Methods": "OPTIONS,*"
                    },
            "body": json.dumps({"message": "Method not allowed"})
        }