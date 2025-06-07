variable "key_name" {
  description = "AWS Key Pair name"
  type        = string
  default     = "your-key-pair-name"  # REPLACE WITH YOUR KEY NAME
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
