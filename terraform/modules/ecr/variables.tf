variable "name" {
  description = "ECR repository name."
  type        = string
}

variable "scan_on_push" {
  description = "Enable image scan on push."
  type        = bool
  default     = true
}

variable "image_tag_mutability" {
  description = "Image tag mutability for the repository."
  type        = string
  default     = "MUTABLE"
}

variable "max_image_count" {
  description = "How many images to keep in lifecycle policy."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags applied to ECR resources."
  type        = map(string)
  default     = {}
}
