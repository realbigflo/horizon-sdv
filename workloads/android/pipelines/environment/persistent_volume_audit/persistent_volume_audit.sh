#!/usr/bin/env bash

# Copyright (c) 2025 Accenture, All Rights Reserved.
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

# Description:
# Audit kubernetes build persistent volumes against GCE disks
#
# This script enables users to compare Kubernetes build persistent volumes
# with disks reported in Google Compute Engine (GCE). It identifies
# discrepancies and provides options to delete or ignore them.
#
#    Identification Criteria:
#    - Storage class: "reclaimable-storage-class"
#    - Volume size: 2TB
#
# This script helps ensure consistency between Kubernetes build persistent
# volumes and GCE disks, allowing for efficient management and cleanup of
# unused resources.
#
# Usage:
# Run from bastion host with appropriate role/permissions to get/delete
# persistent volumes in kubernetes (k8s). e.g.
#    VOLUME_ACTION="INFO_ONLY" \
#    ZONE="europe-west1-d" ./persistent_volume_audit.sh
#
# Options:
# VOLUME_ACTION:
#     INFO_ONLY  : Information only. Review discrepancies to ensure accuracy.
#     DELETE_K8S : Delete only volumes that exist in k8s but not in GCE disks.
#     DELETE_GCE : Delete only volumes that exist in GCE disks but not in k8s.
#     DELETE_ALL : Delete all volumes in both GCE disks and k8s.
#
# Output Summary
# In addition to console output, this script generates a summary HTML file
# (persistent_volume_audit_report.html) that provides a comparison of:
#
# - Kubernetes persistent volumes
# - Google Compute Engine (GCE) disks
# - Common volumes/disks between k8s and GCE
# - Discrepancies between k8s and GCE volumes/disks

# Environment variables that can be overridden from command line.
OUTPUT_HTML_FILENAME=${OUTPUT_HTML_FILENAME:-persistent_volume_audit_report.html}
JENKINS_NAMESPACE=${JENKINS_NAMESPACE:-jenkins}
VOLUME_ACTION=${VOLUME_ACTION:-INFO_ONLY}
ZONE=${ZONE:-europe-west1-d}

# Create the lists of PVs in k8s and GCE Disks, and then compare.
# shellcheck disable=SC2207
K8S_PV=($(kubectl get pv -n "${JENKINS_NAMESPACE}" -o jsonpath='{.items[?(@.spec.storageClassName=="reclaimable-storage-class")].metadata.name}'))
# shellcheck disable=SC2207
GCE_PV=($(gcloud compute disks list --zones="${ZONE}" --filter="type:(pd-balanced) AND sizeGb=2000" 2>/dev/null | tail -n +2 | awk '{print $1}'))
# shellcheck disable=SC2207
COMMON=($(comm -12 <(printf "%s\n" "${K8S_PV[@]}" | sort) <(printf "%s\n" "${GCE_PV[@]}" | sort)))
# shellcheck disable=SC2207
K8S_ONLY=($(comm -23 <(printf "%s\n" "${K8S_PV[@]}" | sort) <(printf "%s\n" "${GCE_PV[@]}" | sort)))
# shellcheck disable=SC2207
GCE_ONLY=($(comm -13 <(printf "%s\n" "${K8S_PV[@]}" | sort) <(printf "%s\n" "${GCE_PV[@]}" | sort)))

# Pretty up the HTML
HEADER=$(cat <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>K8S PVs and GCE Disks Comparison</title>
    <style>
        body {
            font-family: monospace;
        }
        h2 {
            color: #14a66e;
        }
    </style>
</head>
<body>
EOF
)

FOOTER=$(cat <<EOF
</body>
</html>
EOF
)

# Function to print results
print_results() {
    echo "${HEADER}" > "${OUTPUT_HTML_FILENAME}"

    if [ "${#K8S_PV[@]}" -gt 0 ]; then
        echo "K8S Persistent Volumes:"
        echo "<h2>K8S Persistent Volumes:</h2><ul>" >> "${OUTPUT_HTML_FILENAME}"
        for pv in "${K8S_PV[@]}"; do
            echo "- $pv"
            echo "<li>$pv</li>" >> "${OUTPUT_HTML_FILENAME}"
        done
        echo ""
        echo "</ul>" >> "${OUTPUT_HTML_FILENAME}"
    fi

    if [ "${#GCE_PV[@]}" -gt 0 ]; then
        echo "GCE Disks:"
        echo "<h2>GCE Disks:</h2><ul>" >> "${OUTPUT_HTML_FILENAME}"
        for disk in "${GCE_PV[@]}"; do
            echo "- https://console.cloud.google.com/compute/disksDetail/zones/${ZONE}/disks/$disk"
            echo "<li><a href=\"https://console.cloud.google.com/compute/disksDetail/zones/${ZONE}/disks/$disk\" target=\"_blank\">$disk</a></li>" >> "${OUTPUT_HTML_FILENAME}"
        done
        echo ""
        echo "</ul>" >> "${OUTPUT_HTML_FILENAME}"
    fi

    if [ "${#COMMON[@]}" -gt 0 ]; then
        echo "Common Persistent Volumes:"
        echo "<h2>Common Persistent Volumes:</h2><ul>" >> "${OUTPUT_HTML_FILENAME}"
        for pv in "${COMMON[@]}"; do
            echo "- $pv"
            echo "<li>$pv</li>" >> "${OUTPUT_HTML_FILENAME}"
        done
        echo ""
        echo "</ul>" >> "${OUTPUT_HTML_FILENAME}"
    fi

    if [ "${#K8S_ONLY[@]}" -gt 0 ]; then
        echo "Persistent Volumes only in K8S:"
        echo "<h2>Persistent Volumes only in K8S:</h2><ul>" >> "${OUTPUT_HTML_FILENAME}"
        for pv in "${K8S_ONLY[@]}"; do
            echo "- $pv"
            echo "<li>$pv</li>" >> "${OUTPUT_HTML_FILENAME}"
        done
        echo ""
        echo "</ul>" >> "${OUTPUT_HTML_FILENAME}"
    fi

    if [ "${#GCE_ONLY[@]}" -gt 0 ]; then
        echo "Persistent Volumes only in GCE Disks:"
        echo "<h2>Persistent Volumes only in GCE Disks:</h2><ul>" >> "${OUTPUT_HTML_FILENAME}"
        for disk in "${GCE_ONLY[@]}"; do
            echo "- https://console.cloud.google.com/compute/disksDetail/zones/${ZONE}/disks/$disk"
            echo "<li><a href=\"https://console.cloud.google.com/compute/disksDetail/zones/${ZONE}/disks/$disk\" target=\"_blank\">$disk</a></li>" >> "${OUTPUT_HTML_FILENAME}"
        done
        echo ""
        echo "</ul>" >> "${OUTPUT_HTML_FILENAME}"
    fi
    echo "${FOOTER}" >> "${OUTPUT_HTML_FILENAME}"
}

# Function to delete resources
delete_resources() {
    if [ "$1" == "DELETE_ALL" ]; then
        for pv in "${K8S_PV[@]}"; do
            echo "Deleting PV: $pv"
            kubectl delete pv "$pv" -n "${JENKINS_NAMESPACE}"
        done
        for disk in "${GCE_PV[@]}"; do
            echo "Deleting Disk: $disk"
            yes Y | gcloud compute disks delete "$disk" --zone="${ZONE}"
        done
    elif [ "$1" == "DELETE_GCE" ]; then
        for disk in "${GCE_ONLY[@]}"; do
            echo "Deleting Disk: $disk"
            yes Y | gcloud compute disks delete "$disk" --zone="${ZONE}"
        done
    elif [ "$1" == "DELETE_K8S" ]; then
        for pv in "${K8S_ONLY[@]}"; do
            echo "Deleting PV: $pv"
            kubectl delete pv "$pv" -n "${JENKINS_NAMESPACE}"
        done
    fi
}

# Main
print_results
delete_resources "${VOLUME_ACTION}"
