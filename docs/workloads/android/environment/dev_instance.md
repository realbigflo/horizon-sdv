# Development Build Instance

## Table of contents
- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Environment Variables/Parameters](#environment-variables)
- [System Variables](#system-variables)

## Introduction <a name="introduction"></a>

During developing the Android workload and workflow/pipelines, sometimes it may be necessary to gain access to a VM build instance in order to develop build jobs. The instance will have the build caches, persistent storage mounted.

Those that require access must be able to connect to the `bastion` host and then access the pod using `kubectl`, e.g.

```
kubectl exec -it -n jenkins <pod name> -- bash
```

- These instances only remain active for a limited time, defined by `INSTANCE_MAX_UPTIME`.
- User can find `<pod name>` from either the Jenkins UI console log or from the Jenkins Build Executor nodes.
- Users are responsible for managing their work and saving to their own storage, that's beyond the purpose of this job.

## Prerequisites<a name="prerequisites"></a>

One-time setup requirements.

- Before running this pipeline job, ensure that the following template has been created by running the corresponding job:
  - Docker image template: ``Android Workflows/Environment/Docker Image Template`

## Environment Variables/Parameters <a name="environment-variables"></a>

### `INSTANCE_MAX_UPTIME`

This is the maximum time that the instance may be running before it is automatically terminated and deleted. This is important to avoid leaving expensive instances in running state.

## SYSTEM VARIABLES <a name="system-variables"></a>

There are a number of system environment variables that are unique to each platform but required by Jenkins build, test and environment pipelines.

These are defined in Jenkins CasC `jenkins.yaml` and can be viewed in Jenkins UI under `Manage Jenkins` -> `System` -> `Global Properties` -> `Environment variables`.

These are as follows:

-   `ANDROID_BUILD_DOCKER_ARTIFACT_PATH_NAME`
    - Defines the registry path where the Docker image used by builds, tests and environments is stored.

-   `CLOUD_PROJECT`
    - The GCP project, unique to each project. Important for bucket, registry paths used in pipelines.

-   `CLOUD_REGION`
    - The GCP project region. Important for bucket, registry paths used in pipelines.

-   `CLOUD_ZONE`
    - The GCP project zone. Important for bucket, registry paths used in pipelines.

-   `JENKINS_SERVICE_ACCOUNT`
    - Service account to use for pipelines. Required to ensure correct roles and permissions for GCP resources.
