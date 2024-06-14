resource "aws_dynamodb_table" "visitor_counter_count_table" {
  name = "visitor_counter_count"
  hash_key = "number_of_visitors"

  attribute {
    name = "visitor_counter_count"
    type = "S"
  }

  attribute {
    name = "number_of_visitors_count"
    type = "N"
  }
}
