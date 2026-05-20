output "lambda_arn" {
  value       = aws_lambda_function.shortener_lambda.arn
  description = "El ARN de la Lambda de acortamiento (útil para auditoría)"
}

output "route_url" {
  value       = "POST -> /shorten"
  description = "Ruta registrada con éxito en el API Gateway compartido"
}