# Android CTS Build

## Table of contents
- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Environment Variables/Parameters](#environment-variables)
  * [Targets](#targets)
- [System Variables](#system-variables)
- [Known Issues](#known-issues)

## Introduction <a name="introduction"></a>

This pipeline builds the Android Automotive Compatibility Test Suite ([CTS](https://source.android.com/docs/compatibility/cts)) test harness from the specified code base.

The following are examples of the environment variables and Jenkins build parameters that can be used.

## Prerequisites<a name="prerequisites"></a>

One-time setup requirements.

- Before running this pipeline job, ensure that the following template has been created by running the corresponding job:
  - Docker image template: `Android Workflows/Environment/Docker Image Template`

## Environment Variables/Parameters <a name="environment-variables"></a>

### `AAOS_GERRIT_MANIFEST_URL`

This provides the URL for the Android repo manifest. Such as:

- https://dev.horizon-sdv.com/gerrit/android/platform/manifest (default)
- https://android.googlesource.com/platform/manifest

### `AAOS_REVISION`

The Android revision, i.e. branch or tag to build. Tested versions are below:

- `horizon/android-14.0.0_r30` (ap1a - default)
- `horizon/android-14.0.0_r74` (ap2a - refer to Known Issues)
- `horizon/android-15.0.0_r4` (ap3a)
- `android14-qpr1-automotiveos-release`
- `android-14.0.0_r22`
- `android-14.0.0_r30` (ap1a)
- `android-14.0.0_r74` (ap2a, refer to Known Issues)
- `android-15.0.0_r4` (ap3a)
- `android-15.0.0_r10` (ap4a)

### `AAOS_LUNCH_TARGET` <a name="targets"></a>

The Android cuttlefish target to build CTS from. Must be one of the `aosp_cf` targets.

Reference: [Codenames, tags, and build numbers](https://source.android.com/docs/setup/reference/build-numbers)

Examples:

- Virtual Devices:
    -   `aosp_cf_x86_64_auto-userdebug`
    -   `aosp_cf_x86_64_auto-ap1a-userdebug`
    -   `aosp_cf_x86_64_auto-ap2a-userdebug`
    -   `aosp_cf_x86_64_auto-ap3a-userdebug`
    -   `aosp_cf_x86_64_auto-ap4a-userdebug`
    -   `aosp_cf_arm64_auto-userdebug`
    -   `aosp_cf_arm64_auto-ap1a-userdebug`
    -   `aosp_cf_arm64_auto-ap2a-userdebug`
    -   `aosp_cf_arm64_auto-ap3a-userdebug`
    -   `aosp_cf_arm64_auto-ap4a-userdebug`

### `AAOS_CLEAN`

Option to clean the build workspace, either fully or simply for the `AAOS_LUNCH_TARGET` target defined.

### `GERRIT_REPO_SYNC_JOBS`

This is the value used for parallel jobs for `repo sync`, i.e. `-j <GERRIT_REPO_SYNC_JOBS>`.
The default is defined in system environment variable: `REPO_SYNC_JOBS`.
The minimum is 1 and the maximum is 24.

### `INSTANCE_RETENTION_TIME`

Keep the build VM instance and container running to allow user to connect to it. Useful for debugging build issues, determining target output archives etc.

Access using `kubectl` e.g. `kubectl exec -it -n jenkins <pod name> -- bash` from `bastion` host.

### `AAOS_ARTIFACT_STORAGE_SOLUTION`

Define storage solution used to push artifacts.

Currently `GCS_BUCKET` default pushes to GCS bucket, if empty then nothing will be stored.

### `GERRIT_PROJECT` / `GERRIT_CHANGE_NUMBER` / `GERRIT_PATCHSET_NUMBER`

These are optional but allow the user to fetch a specific Gerrit patchset if required.

## SYSTEM VARIABLES <a name="system-variables"></a>

There are a number of system environment variables that are unique to each platform but required by Jenkins build, test and environment pipelines.

These are defined in Jenkins CasC `jenkins.yaml` and can be viewed in Jenkins UI under `Manage Jenkins` -> `System` -> `Global Properties` -> `Environment variables`.

These are as follows:

-   `ANDROID_BUILD_BUCKET_ROOT_NAME`
     - Defines the name of the Google Storage bucket that will be used to store build and test artifacts

-   `ANDROID_BUILD_DOCKER_ARTIFACT_PATH_NAME`
    - Defines the registry path where the Docker image used by builds, tests and environments is stored.

-   `CLOUD_PROJECT`
    - The GCP project, unique to each project. Important for bucket, registry paths used in pipelines.

-   `CLOUD_REGION`
    - The GCP project region. Important for bucket, registry paths used in pipelines.

-   `CLOUD_ZONE`
    - The GCP project zone. Important for bucket, registry paths used in pipelines.

-   `GERRIT_CREDENTIALS_ID`
    - The credential for access to Gerrit, required for build pipelines.

-   `HORIZON_DOMAIN`
    - The URL domain which is required by pipeline jobs to derive URL for tools and GCP.

-   `JENKINS_CACHE_STORAGE_CLASS_NAME`
    - This identifies the Persistent Volume Claim (PVC) that provisions persistent storage for build cache, ensuring efficient reuse of cached resources across builds. The default is [`pd-balanced`](https://cloud.google.com/compute/docs/disks/performance), which strikes a balance between optimal performance and cost-effectiveness.

-   `JENKINS_SERVICE_ACCOUNT`
    - Service account to use for pipelines. Required to ensure correct roles and permissions for GCP resources.

-   `REPO_SYNC_JOBS`
    - Defines the number of parallel sync jobs when running `repo sync`. By default this is used by Gerrit build
      pipeline but also forms the default for `GERRIT_REPO_SYNC_JOBS` parameter in build jobs.

## KNOWN ISSUES <a name="known-issues"></a>

Refer to workloads/android/pipelines/builds/aaos_builder/README.md.
