data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_iam_role" "lambda_role" {
  name = "modulo1-shortener-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_dynamo_policy" {
  name = "modulo1-shortener-dynamo-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:PutItem"]
      Resource = var.shared_dynamodb_table_arn
    }]
  })
}

resource "aws_lambda_function" "shortener_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "modulo1-url-shortener"
  role             = aws_iam_role.lambda_role.arn
  
  # CRUCIAL: Debe coincidir con el nombre de tu archivo JS en /src (ej: index.js -> index.handler)
  handler          = "index.handler" 
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "nodejs20.x"

  environment {
    variables = {
      DYNAMODB_TABLE = var.shared_dynamodb_table_name
      JWT_SECRET = "peruEsClave" 
    }
  }
}

# Ruta Principal para Acortar
resource "aws_apigatewayv2_route" "shorten_route" {
  api_id    = var.shared_api_gateway_id
  route_key = "POST /shorten"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Ruta CORS Preflight para evitar bloqueos del navegador
resource "aws_apigatewayv2_route" "shorten_options_route" {
  api_id    = var.shared_api_gateway_id
  route_key = "OPTIONS /shorten"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = var.shared_api_gateway_id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.shortener_lambda.invoke_arn
}

resource "aws_lambda_permission" "api_gw_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.shortener_lambda.function_name
  principal     = "apigateway.amazonaws.com"
}