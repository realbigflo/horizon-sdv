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
# Main configuration file for the "sdv-apis" module.
# This module enables the specified Google Cloud APIs from a provided list.

data "google_project" "project" {}

resource "google_project_service" "service" {
  for_each = var.list_of_apis

  service            = each.key
  project            = data.google_project.project.project_id
  disable_on_destroy = false
}
