#!/usr/bin/env bash

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

# Description:
# Store AAOS targets to artifact area.
#
# This script will store the specified AAOS target to the artifact area.
# The target is determined by the AAOS_LUNCH_TARGET environment variable.
#
# The following variables must be set before running this script:
#
#  - AAOS_LUNCH_TARGET: the target device.
#
# Optional variables:
#  - AAOS_ARTIFACT_STORAGE_SOLUTION: the persistent storage location for
#        artifacts (GCS_BUCKET default).
#  - AAOS_ARTIFACT_ROOT_NAME: the name of the bucket to store artifacts.
#
# Example usage:
# AAOS_LUNCH_TARGET=sdk_car_x86_64-ap1a-userdebug \
# ./workloads/android/pipelines/builds/aaos_builder/aaos_storage.sh

# Include common functions and variables.
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")"/aaos_environment.sh "$0"

# If the bucket does not exist, it is created.
# shellcheck disable=SC2317
function gcs_bucket() {
    local -r bucket_name="gs://${AAOS_ARTIFACT_ROOT_NAME}"
    # Replace spaces in Jenkins Job Name
    BUCKET_FOLDER="${JOB_NAME// /_}"
    local -r destination="${bucket_name}/${BUCKET_FOLDER}/${AAOS_BUILD_NUMBER}"
    local -r cloud_url="https://console.cloud.google.com/storage/browser/${AAOS_ARTIFACT_ROOT_NAME}/${BUCKET_FOLDER}/${AAOS_BUILD_NUMBER}"
    local -r artifacts_summary="${ORIG_WORKSPACE}/${AAOS_LUNCH_TARGET}-artifacts.txt"

    # Remove the old artifacts
    /usr/bin/gsutil -m rm "${destination}"/* || true
    rm -f "${artifacts_summary}"

    # Print download URL links in console log and file..
    echo ""
    echo "Artifacts for ${AAOS_LUNCH_TARGET} stored in ${destination}" | tee -a "${artifacts_summary}"
    echo "Bucket URL: ${cloud_url}" | tee -a "${artifacts_summary}"
    echo "" | tee -a "${artifacts_summary}"

    # Copy artifacts to Google Cloud Storage bucket
    echo "Storing ${AAOS_LUNCH_TARGET} artifacts to bucket ${bucket_name}"
    for artifact in "${AAOS_ARTIFACT_LIST[@]}"; do
        for file in ${artifact}; do
            # Look for wildcard files.
            if [ -e "${file}" ]; then
                # Copy the artifact to the bucket
                /usr/bin/gsutil cp "${file}" "${destination}"/ || true
                echo "Copied ${file} to ${destination}"
                # shellcheck disable=SC2086
                filename=$(echo ${file} | awk -F / '{print $NF}')
                echo "    gsutil cp ${destination}/${filename} ." | tee -a "${artifacts_summary}"
            fi
        done
    done
    echo "Artifacts summary:"
    cat "${artifacts_summary}"
}

#
# A noop function that does nothing.
#
# This function is used when the AAOS_ARTIFACT_STORAGE_SOLUTION is not
# supported. It prints a message to indicate that the artifacts are not
# being stored to any storage solution.
# shellcheck disable=SC2317
function noop() {
    echo "Noop: skipping artifact stored to ${AAOS_ARTIFACT_STORAGE_SOLUTION}" >&2
    for artifact in "${AAOS_ARTIFACT_LIST[@]}"; do
        echo "Skipping copy of ${artifact}" >&2
    done
}

#
# Storage selection.
#
# This case statement sets the AAOS_ARTIFACT_STORAGE_SOLUTION_FUNCTION
# variable to the appropriate function to call to store artifacts to
# the given storage solution.
case "${AAOS_ARTIFACT_STORAGE_SOLUTION}" in
    GCS_BUCKET)
        AAOS_ARTIFACT_STORAGE_SOLUTION_FUNCTION=gcs_bucket
        ;;
    *)
        AAOS_ARTIFACT_STORAGE_SOLUTION_FUNCTION=noop
        ;;
esac

# Store artifacts to artifact storage.
if [ -n "${AAOS_ARTIFACT_STORAGE_SOLUTION}" ] && [ -n "${AAOS_BUILD_NUMBER}" ]; then
    if [ ${#AAOS_ARTIFACT_LIST[@]} -gt 0 ]; then
        "${AAOS_ARTIFACT_STORAGE_SOLUTION_FUNCTION}"
    else
        echo "No artifacts to store to ${AAOS_ARTIFACT_STORAGE_SOLUTION}, ignored."
    fi
else
    # If not running from Jenkins, just NOOP!
    noop
fi

# Post storage commands.
echo "Post storage commands:"
for command in "${POST_STORAGE_COMMANDS[@]}"; do
    echo "${command}"
    eval "${command}"
done

# Return result
exit $?
