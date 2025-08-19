# Inline Node.js 22 code packaged to ZIP
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda.zip"

  source {
    content  = <<-JS
      export const handler = async (event) => {
        // Basic health + example DB env var echo
        return {
          statusCode: 200,
          headers: { "content-type": "application/json" },
          body: JSON.stringify({
            ok: true,
            message: "Hello from Lambda backend",
            db_host: process.env.DB_HOST
          })
        };
      };
    JS
    filename = "index.mjs"
  }
}

# IAM role for Lambda
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.project}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda function in VPC (to reach RDS)
resource "aws_lambda_function" "backend" {
  function_name = "${var.project}-backend"
  role          = aws_iam_role.lambda.arn
  filename      = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  handler       = "index.handler"
  runtime       = "nodejs22.x"

  environment {
    variables = {
      DB_HOST = aws_db_instance.mysql.address
      DB_USER = aws_db_instance.mysql.username
      DB_PASS = random_password.db.result
      DB_NAME = "appdb"
    }
  }

  vpc_config {
    subnet_ids         = [for s in aws_subnet.private : s.id]
    security_group_ids = [aws_security_group.lambda.id]
  }
}

# Allow API Gateway to invoke Lambda
resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backend.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}
