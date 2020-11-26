# Variables

variable "domain" {}
variable "profile" {}
variable "region" {}
variable "system" {}
variable "containerImage" {}

variable "zoneid" {
  type        = string
  default     = ""
  description = "Route 53 zone id"
}

variable "config" {
  type        = string
  default     = ""
  description = "CONFIG env var"
}

variable "studioClientID" {}
variable "studioClientSecret" {}
variable "studioClientUsername" {}
variable "studioClientPassword" {}
variable "studioBaseURL" {}

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

variable "containerPort" {
  type        = number
  default     = 8000
  description = "Port exposed from the ECS task container"
}

variable "nodeEnv" {
  type        = string
  default     = "production"
  description = "NodeJS execution environment"
}

# Database settings

variable "dbAllocatedGB" {
  type        = number
  default     = 10
  description = "Stroage to allocate (GB)"
}

variable "dbAllocatedMaxGB" {
  type        = number
  default     = 100
  description = "Max storage scaling (GB)"
}

variable "dbBackupRetentionDays" {
  type        = number
  default     = 14
  description = "Number of days to retain backups for (0 - 35)"
}

variable "dbInstanceClass" {
  type        = string
  default     = "db.t3.micro"
  description = "Replica instance type"
}

variable "dbInstanceCount" {
  type        = number
  default     = 0
  description = "Number of instances (primary + replicas)"
}

# Locals

locals {
  defaultTags = {
    terraform = true
    reshuffle = true
    system    = var.system
  }
}
