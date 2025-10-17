variable "name" {
  description = "Friendly name prefix for the Aurora cluster"
  type        = string
}

variable "engine" {
  description = "Aurora engine"
  type        = string
  default     = "aurora-postgresql"
}

variable "engine_version" {
  description = "Aurora engine version"
  type        = string
}

variable "parameter_family" {
  description = "DB parameter group family"
  type        = string
}

variable "master_username" {
  description = "Master username"
  type        = string
}

variable "master_password" {
  description = "Master password"
  type        = string
  sensitive   = true
}

variable "database_name" {
  description = "Initial database name"
  type        = string
  default     = "app"
}

variable "subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC id"
  type        = string
}

variable "port" {
  description = "Aurora port"
  type        = number
  default     = 5432
}

variable "instance_class" {
  description = "Aurora instance class"
  type        = string
}

variable "instance_count" {
  description = "Number of Aurora instances"
  type        = number
  default     = 2
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks permitted to reach the cluster"
  type        = list(string)
  default     = []
}

variable "allowed_security_group_ids" {
  description = "Additional security groups permitted to reach the cluster"
  type        = list(string)
  default     = []
}

variable "additional_security_group_ids" {
  description = "Security groups to add to the cluster alongside the managed group"
  type        = list(string)
  default     = []
}

variable "kms_key_id" {
  description = "KMS key for encryption"
  type        = string
  default     = null
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on deletion"
  type        = bool
  default     = false
}

variable "apply_immediately" {
  description = "Apply changes immediately"
  type        = bool
  default     = false
}

variable "preferred_backup_window" {
  description = "Backup window"
  type        = string
  default     = "03:00-05:00"
}

variable "preferred_maintenance_window" {
  description = "Maintenance window"
  type        = string
  default     = "sun:05:00-sun:07:00"
}

variable "backup_retention_period" {
  description = "Backup retention in days"
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "cluster_parameters" {
  description = "Custom cluster parameters"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "instance_parameters" {
  description = "Custom instance parameters"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "serverlessv2_scaling_configuration" {
  description = "Optional serverless v2 scaling configuration"
  type = object({
    min_capacity = number
    max_capacity = number
  })
  default = null
}

variable "global" {
  description = "Global database settings"
  type = object({
    enabled                   = bool
    global_cluster_identifier = string
    is_primary                = bool
    primary_region            = optional(string)
  })
  default = {
    enabled                   = false
    global_cluster_identifier = ""
    is_primary                = true
    primary_region            = null
  }
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
