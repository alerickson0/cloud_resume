resource "aws_dynamodb_table" "visitor_counter_count_table" {
  name           = "visitor_counter_count"
  hash_key       = "number_of_visitors"
  read_capacity  = 1
  write_capacity = 1

  attribute {
    name = "number_of_visitors"
    type = "S"
  }

}
