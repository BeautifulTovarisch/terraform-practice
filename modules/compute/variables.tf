variable "subnet_ids" {
  description = "VPC subnet identifiers"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group identifiers"
  type        = list(string)
}

variable "tags" {
  description = "Instance Tags"
  type        = map(any)
  default     = {}
}
