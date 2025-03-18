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
# Main configuration file for the "sdv-bastion-host" module.
# Provision bastion host for the GKE cluster from GCE instance template.
# Also, create and bind required IAM resources.

data "google_project" "project" {}

resource "google_service_account" "vm_sa" {
  project      = data.google_project.project.project_id
  account_id   = var.service_account
  display_name = "Service Account for the bastion host"
}

# A testing VM to allow OS Login + IAP tunneling.
module "instance_template" {
  source  = "terraform-google-modules/vm/google//modules/instance_template"
  version = "~> 12.0"

  project_id   = data.google_project.project.project_id
  machine_type = var.machine_type
  subnetwork   = var.subnetwork
  service_account = {
    email  = google_service_account.vm_sa.email
    scopes = ["cloud-platform"]
  }
  metadata = {
    enable-oslogin = "TRUE"
  }
  source_image = var.source_image
}

resource "google_compute_instance_from_template" "vm" {
  project = data.google_project.project.project_id
  name    = var.host_name
  zone    = var.zone
  network_interface {
    subnetwork = var.subnetwork
  }
  source_instance_template = module.instance_template.self_link
}

# Additional OS login IAM bindings.
# https://cloud.google.com/compute/docs/instances/managing-instance-access#granting_os_login_iam_roles
resource "google_service_account_iam_member" "service_account_user" {
  for_each           = toset(var.members)
  service_account_id = google_service_account.vm_sa.id
  role               = "roles/iam.serviceAccountUser"
  member             = each.key
}

resource "google_project_iam_member" "os_admin_login_bindings" {
  for_each = toset(var.members)
  project  = data.google_project.project.id
  role     = "roles/compute.osAdminLogin"
  member   = each.key
}

resource "google_project_iam_member" "kubernetes_engine_admin" {
  for_each = toset(var.members)
  project  = data.google_project.project.id
  role     = "roles/container.admin"
  member   = each.key
}

module "iap_tunneling" {
  source  = "terraform-google-modules/bastion-host/google//modules/iap-tunneling"
  version = "~> 7.0"

  fw_name_allow_ssh_from_iap = "bastion-allow-ssh-from-iap-to-tunnel"
  project                    = data.google_project.project.project_id
  network                    = var.network
  service_accounts           = [google_service_account.vm_sa.email]
  instances = [{
    name = google_compute_instance_from_template.vm.name
    zone = var.zone
  }]
  members = var.members
}

#
# Allows the bastion host SA to manage the GKE cluster
#
resource "google_project_iam_member" "container_admin_iam_member" {
  project = data.google_project.project.id
  role    = "roles/container.admin"
  member  = "serviceAccount:${google_service_account.vm_sa.email}"
}

resource "google_project_iam_member" "storage_object_viewer" {
  project = data.google_project.project.id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.vm_sa.email}"
}

resource "google_project_iam_member" "artifact_registry_writer" {
  project = data.google_project.project.id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.vm_sa.email}"
}

resource "google_project_iam_member" "artifact_secret_accessor" {
  project = data.google_project.project.id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.vm_sa.email}"
}
