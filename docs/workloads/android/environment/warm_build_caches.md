# Android Builds

## Table of contents
- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Environment Variables/Parameters](#environment-variables)
  * [Targets](#targets)
- [System Variables](#system-variables)

## Introduction <a name="introduction"></a>

This job is used to create pre-warmed persistent volumes with build caches used to improve performance for Android builds.

Run the jobs in parallel to ensure each build job has clean persistent volume.

## Prerequisites<a name="prerequisites"></a>

One-time setup requirements.

- Before running this pipeline job, ensure that the following template has been created by running the corresponding job:
  - Docker image template: `Android Workflows/Environment/Docker Image Template`
- Ensure Persistent Volume Claims (PVCs) have been deleted.

## Environment Variables/Parameters <a name="environment-variables"></a>

**Jenkins Parameters:** Defined in the respective pipeline jobs within `gitops/env/stage2/templates/jenkins.yaml` (CasC).

### `AAOS_GERRIT_MANIFEST_URL`

This provides the URL for the Android repo manifest. Such as:

- https://dev.horizon-sdv.com/gerrit/android/platform/manifest (default Horizon manifest)
- https://android.googlesource.com/platform/manifest (Google OSS manifest)

### `AAOS_REVISION`

The Android revision, i.e. branch or tag to build. Tested versions are below:

- `horizon/android-14.0.0_r30` (ap1a - default)
- `horizon/android-14.0.0_r74` (ap2a - refer to Known Issues)
- `horizon/android-15.0.0_r4` (ap3a)
- `horizon/android-15.0.0_r20` (bp1a)
- `android-14.0.0_r30` (ap1a)
- `android-14.0.0_r74` (ap2a, refer to Known Issues)
- `android-15.0.0_r4` (ap3a)
- `android-15.0.0_r20` (bp1a)

### `ARCHIVE_ARTIFACTS`

Option to archive the build artifacts to bucket.


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
    - This identifies the Persistent Volume Claim (PVC) that provisions persistent storage for build cache, ensuring efficient reuse of cached resources across builds.  The default is [`pd-balanced`](https://cloud.google.com/compute/docs/disks/performance), which strikes a balance between optimal performance and cost-effectiveness.

-   `JENKINS_SERVICE_ACCOUNT`
    - Service account to use for pipelines. Required to ensure correct roles and permissions for GCP resources.

-   `REPO_SYNC_JOBS`
    - Defines the number of parallel sync jobs when running `repo sync`. By default this is used by Gerrit build
      pipeline but also forms the default for `GERRIT_REPO_SYNC_JOBS` parameter in build jobs.
