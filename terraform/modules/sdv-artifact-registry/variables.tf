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
# Configuration file containing variables for the "sdv-artifact-registry" module.

variable "repository_id" {
  description = "Define the name of the artifact repository"
  type        = string
}

variable "location" {
  description = "Define the location of the artifact registry"
  type        = string
}

variable "members" {
  description = "Define the users that have write access to the artifact registry"
  type        = list(string)
}

variable "reader_members" {
  description = "Define the users that have reader access to the artifact registry"
  type        = list(string)
}
