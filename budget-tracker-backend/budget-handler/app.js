const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();
const tableName = process.env.BUDGET_TABLE;

exports.lambdaHandler = async (event) => {
  console.info('Received event:', JSON.stringify(event));

  const method = event.requestContext?.http?.method;

  try {
    if (method === 'GET') {
      const data = await dynamodb.scan({ TableName: tableName }).promise();

      const validItems = (data.Items || []).filter(item =>
        item &&
        typeof item.amount === 'number' &&
        typeof item.description === 'string' &&
        typeof item.date === 'string'
      );

      return {
        statusCode: 200,
        headers: {
          'Access-Control-Allow-Origin': '*',
        },
        body: JSON.stringify(data.Items),
      };
    }

    if (method === 'POST') {
      const body = JSON.parse(event.body);
      const { description, amount, date } = body;

      if (
        typeof description !== 'string' ||
        typeof amount !== 'number' ||
        typeof date !== 'string'
      ) {
        return {
          statusCode: 400,
          headers: {
            'Access-Control-Allow-Origin': '*',
          },
          body: JSON.stringify({ message: 'Invalid request: description (string), amount (number), and date (string) are required.' }),
        };
      }

      const item = {
        id: Date.now().toString(),
        description: body.description,
        amount: body.amount,
        date: body.date,
      };

      await dynamodb.put({
        TableName: tableName,
        Item: item,
      }).promise();

      return {
        statusCode: 200,
        headers: {
          'Access-Control-Allow-Origin': '*',
        },
        body: JSON.stringify(validItems),
      };
    }

    return {
      statusCode: 405,
      headers: {
        'Access-Control-Allow-Origin': '*',
      },
      body: JSON.stringify({ message: 'Method Not Allowed!' }),
    };
  } catch (err) {
    console.error(err);
    return {
      statusCode: 500,
      headers: {
        'Access-Control-Allow-Origin': '*',
      },
      body: JSON.stringify({ message: 'Server error', error: err.message }),
    };
  }
};