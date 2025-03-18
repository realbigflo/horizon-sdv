# Copyright (c) 2024-2025 Accenture, All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Description:
# Configuration file containing variables for the "sdv-bastion-host" module.

variable "service_account" {
  description = "Define the Service account"
  type        = string
}

variable "network" {
  description = "Define the Network"
  type        = string
}

variable "subnetwork" {
  description = "Define the Sub Network"
  type        = string
}

variable "source_image" {
  description = "Define the Source image"
  type        = string
  default     = "projects/debian-cloud/global/images/debian-12-bookworm-v20240815"
}

variable "host_name" {
  description = "Define the host name"
  type        = string
}

variable "zone" {
  description = "Define the zone"
  type        = string
}

variable "members" {
  description = "List of members allowed to access the bastion server"
  type        = list(string)
}

variable "machine_type" {
  description = "Machine type for the bastion host"
  type        = string
  default     = "n1-standard-1"
}
