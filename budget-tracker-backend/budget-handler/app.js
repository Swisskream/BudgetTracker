const AWS = require("aws-sdk");
const { v4: uuidv4 } = require("uuid");
//comment: This is a simple AWS Lambda function to handle budget items

const dynamoDb = new AWS.DynamoDB.DocumentClient();
const TABLE_NAME = process.env.BUDGET_TABLE;

exports.handler = async (event) => {
  const method = event.httpMethod;

  if (method === "POST") {
    const { name, amount, category } = JSON.parse(event.body);

    const item = {
      id: uuidv4(),
      name,
      amount,
      category,
      date: new Date().toISOString(),
    };

    await dynamoDb
      .put({
        TableName: TABLE_NAME,
        Item: item,
      })
      .promise();

    return {
      statusCode: 200,
      body: JSON.stringify({ message: "Budget item saved", item }),
    };
  }

  if (method === "GET") {
    const result = await dynamoDb
      .scan({
        TableName: TABLE_NAME,
      })
      .promise();

    return {
      statusCode: 200,
      body: JSON.stringify(result.Items),
    };
  }

  return {
    statusCode: 400,
    body: JSON.stringify({ message: "Unsupported method" }),
  };
};

