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
  filename         = "${path.module}/lambda/lambda.zip"
  function_name    = "budgetLambda"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = filebase64sha256("${path.module}/lambda/lambda.zip")

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.budget_table.name
    }
  }
}

resource "aws_apigatewayv2_api" "http_api" {
  name          = "budget-tracker-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization"]
  }
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.budget_lambda.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_authorizer" "cognito_auth" {
  name          = "budget-cognito-authorizer"
  api_id        = aws_apigatewayv2_api.http_api.id
  authorizer_type = "JWT"
  identity_sources = ["$request.header.Authorization"]

  jwt_configuration {
    audience = [aws_cognito_user_pool_client.budget_user_pool_client.id]
    issuer = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.budget_user_pool.id}"
  }
}

resource "aws_apigatewayv2_route" "route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /budget"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
}

resource "aws_apigatewayv2_route" "get_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /budget"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
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

output "api_gateway_url" {
  value = "${aws_apigatewayv2_api.http_api.api_endpoint}/budget"
}

resource "aws_cognito_user_pool" "budget_user_pool" {
  name = "budget-user-pool"
}

resource "aws_cognito_user_pool_client" "budget_user_pool_client" {
  name         = "budget-user-pool-client"
  user_pool_id = aws_cognito_user_pool.budget_user_pool.id
  generate_secret = false
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows = ["code"]
  allowed_oauth_scopes = ["email", "openid", "profile"]
  callback_urls = ["http://localhost:3000"] # Change to your frontend
  logout_urls = ["http://localhost:3000"]
  supported_identity_providers = ["COGNITO"]
}
