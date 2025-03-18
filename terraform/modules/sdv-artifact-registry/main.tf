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
# Description
# Main configuration file for the "sdv-artifact registry" module.
# Creates Google Artifact Registry repository with required IAM resources.

data "google_project" "project" {}

resource "google_artifact_registry_repository" "docker_repo" {
  location      = var.location
  repository_id = var.repository_id
  format        = "DOCKER"
  description   = "Docker repository for Horizon SDV Dev"
}

resource "google_project_iam_member" "artifact_registry_writer" {
  for_each = toset(var.members)

  project = data.google_project.project.project_id
  role    = "roles/artifactregistry.writer"
  member  = each.value
}

resource "google_project_iam_member" "artifact_registry_reader" {
  for_each = toset(var.reader_members)

  project = data.google_project.project.project_id
  role    = "roles/artifactregistry.reader"
  member  = each.value
}
