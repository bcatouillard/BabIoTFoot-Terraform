output "babyfoot_matches_table-arn" {
  description = "BabyFoot Matches DynamoDB Table"
  value       = aws_dynamodb_table.babyfoot_matches_table.arn
}