# Variables

variable "domain" {}
variable "profile" {}
variable "region" {}
variable "system" {}
variable "studioAuthBaseURL" {}
variable "studioBaseURL" {}
variable "studioClientID" {}
variable "studioClientSecret" {}

variable "zoneid" {
  type        = string
  default     = ""
  description = "Route 53 zone id"
}

# General settings

variable "vpcCidrBlock" {
  type        = string
  default     = "10.0.0.0/16"
  description = "VPC network configuration"
}

variable "logRetentionDays" {
  type        = number
  default     = 90
  description = "Number of days to retain log events"
}

# ECS container settings

variable "containerCPU" {
  type        = string
  default     = "256"
  description = "ECS container CPU size (1024 === 1 vCPU)"
}

variable "containerMemory" {
  type        = string
  default     = "512"
  description = "ECS container memory size in MB"
}

variable "cotainerCount" {
  type        = number
  default     = 1
  description = "Number of scale-out ECS task containers"
}

variable "containerImage" {
  type        = string
  default     = "docker.io/avnerbraverman/reshuffle"
  description = "URL for ECS task contaner image"
}

variable "containerPort" {
  type        = number
  default     = 4141
  description = "Port exposed from the ECS task container"
}

# Locals

locals {
  defaultTags = {
    terraform = true
    reshuffle = true
    system    = var.system
  }
}
