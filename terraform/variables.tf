variable "shared_api_gateway_id" {
  type        = string
  description = "El ID del API Gateway compartido (visto en los outputs de shared)"
}

variable "shared_dynamodb_table_arn" {
  type        = string
  description = "El ARN de la tabla DynamoDB compartida"
}

variable "shared_dynamodb_table_name" {
  type        = string
  description = "El Nombre de la tabla DynamoDB compartida"
}