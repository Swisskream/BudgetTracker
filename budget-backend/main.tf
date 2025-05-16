provider "aws" {
  region = var.aws_region
}

resource "aws_dynamodb_table" "budget_table" {
  name           = "BudgetItems"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "BudgetTrackerKey"
  attribute {
    name = "BudgetTrackerKey"
    type = "S"
  }
}

resource "aws_iam_policy" "dynamodb_rw_policy" {
  name        = "DynamoDBReadWriteBudget"
  description = "Allow read/write access to BudgetItems table"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Scan",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem"
        ],
        Effect   = "Allow",
        Resource = aws_dynamodb_table.budget_table.arn
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "dynamodb_rw_policy_attach" {
  name       = "AttachDynamoDBPolicy"
  roles      = [aws_iam_role.lambda_exec_role.name]
  policy_arn = aws_iam_policy.dynamodb_rw_policy.arn
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy_attachment" "lambda_policy" {
  name       = "lambda_policy_attachment"
  roles      = [aws_iam_role.lambda_exec_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "budget_lambda" {
  filename         = "${path.module}/lambda/handler.zip"
  function_name    = "budgetLambda"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "handler.handler"
  runtime          = "python3.12"
  source_code_hash = filebase64sha256("${path.module}/lambda/handler.zip")

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.budget_table.name
    }
  }
}

resource "aws_apigatewayv2_api" "http_api" {
  name          = "budget-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.budget_lambda.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /budget"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "get_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /budget"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.budget_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}
