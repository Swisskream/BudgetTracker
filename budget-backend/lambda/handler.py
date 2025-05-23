# import os
# import json
# import boto3
# from uuid import uuid4

# region_name = os.environ.get('AWS_REGION', 'us-west-1') 
# dynamodb = boto3.resource('dynamodb', region_name=region_name)
# table = dynamodb.Table('BudgetItems')

# def lambda_handler(event, context):
#     print('Received event:', json.dumps(event, indent=2))


#     # method = event.get('httpMethod', '')
#     method = event.get('httpMethod') or event.get('requestContext', {}).get('http', {}).get('method', '')

#     print("Detected HTTP method:", method)
    
#     if method == 'POST':
#         try:
#             body = json.loads(event.get('body', '{}'))

#             required_fields = ['description', 'amount', 'date']
#             if not all(field in body for field in required_fields):
#                 return {
#                     "statusCode": 400,
#                     "headers": {"Access-Control-Allow-Origin": "*",
#                         "Access-Control-Allow-Headers": "*",
#                         "Access-Control-Allow-Methods": "OPTIONS,*"
#                         },
#                     "body": json.dumps({"message": "Missing required fields"})
#                 }

#             body['BudgetTrackerKey'] = str(uuid4())

#             table.put_item(Item=body)

#             return {
#                 "statusCode": 200,
#                 "headers": {"Access-Control-Allow-Origin": "*",
#                     "Access-Control-Allow-Headers": "*",
#                     "Access-Control-Allow-Methods": "OPTIONS,*"
#                     },
#                 "body": json.dumps({"message": "Success", "item": body})
#             }

#         except Exception as e:
#             print(e)
#             return {
#                 "statusCode": 500,
#                 "headers": {"Access-Control-Allow-Origin": "*",
#                     "Access-Control-Allow-Headers": "*",
#                     "Access-Control-Allow-Methods": "OPTIONS,*"
#                     },
#                 "body": json.dumps({"message": str(e)})
#             }

#     elif method == 'GET':
#         try:
#             response = table.scan()
#             items = response.get('Items', [])
#             return {
#                 "statusCode": 200,
#                 "headers": {"Access-Control-Allow-Origin": "*",
#                     "Access-Control-Allow-Headers": "*",
#                     "Access-Control-Allow-Methods": "OPTIONS,*"
#                     },
#                 "body": json.dumps(items)
#             }

#         except Exception as e:
#             print(e)
#             return {
#                 "statusCode": 500,
#                 "headers": {"Access-Control-Allow-Origin": "*",
#                     "Access-Control-Allow-Headers": "*",
#                     "Access-Control-Allow-Methods": "OPTIONS,*"
#                     },
#                 "body": json.dumps({"message": str(e)})
#             }

#     else:
#         return {
#             "statusCode": 405,
#             "headers": {"Access-Control-Allow-Origin": "*",
#                     "Access-Control-Allow-Headers": "*",
#                     "Access-Control-Allow-Methods": "OPTIONS,*"
#                     },
#             "body": json.dumps({"message": "Method not allowed"})
#         }

import json
import boto3
from boto3.dynamodb.conditions import Attr

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('BudgetItems')

def lambda_handler(event, context):
    try:
        #claims = event['requestContext']['authorizer']['jwt']['claims']
        claims = event.get('requestContext', {}).get('authorizer', {}).get('jwt', {}).get('claims')
        if not claims:
            raise Exception("JWT claims not found in requestContext")
        user_id = claims['sub']

        method = event['requestContext']['http']['method']
        if method == "POST":
            body = json.loads(event['body'])
            item = {
                "BudgetTrackerKey": body['id'],  # must be unique
                "amount": body['amount'],
                "description": body.get('description', ''),
                "timestamp": body.get('timestamp', ''),
                "userId": user_id  # optional: use this if you want to filter by user
            }
            table.put_item(Item=item)
            response_body = {"message": "Item added successfully!"}

        elif method == "GET":
            data = table.scan(
                FilterExpression=Attr('userId').eq(user_id)
            )
            response_body = data.get("Items", [])

        elif method == "OPTIONS":
            return {
                "statusCode": 200,
                "headers": cors_headers(),
                "body": json.dumps({"message": "CORS preflight passed"})
            }

        else:
            return {
                "statusCode": 405,
                "headers": cors_headers(),
                "body": json.dumps({"message": "Method not allowed"})
            }

        return {
            "statusCode": 200,
            "headers": cors_headers(),
            "body": json.dumps(response_body)
        }

    except Exception as e:
        print("Error:", str(e))
        return {
            "statusCode": 500,
            "headers": cors_headers(),
            "body": json.dumps({"message": str(e)})
        }

def cors_headers():
    return {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "Authorization,Content-Type",
        "Access-Control-Allow-Methods": "OPTIONS,GET,POST"
    }
