# Github Workflows

## Table of contents
- [Introduction](#Introduction)
- [Description](#Description)
- [Workflow triggering](#WorkflowTriggering)
- [Modifying Workflows](#ModifyingWorkflows)  
- [Workflow implementation details](#WorkflowImplementationDetails)


## Introduction <a name="Introduction"></a>
GitHub Workflows are part of GitHub Actions, that enables to automate software development cycle. Can be used to automate builds, tests, and deploy operations. Workflows are defined using YAML files and are stored in the .github/workflows directory. Each workflow consists of one or more jobs, and each job runs on a runner machine and executes a series of steps. Steps can run scripts that you define or use actions, which are reusable extensions that simplify your workflow.


## Description <a name="Description"></a>
In the `Horizon SDV` project workflows implementation consists of 2 main files:
`terraform_workflow.yaml` - entry point for workflow execution with definition of inputs, secrets and additional jobs etc. Contains also rules of how a workflow is triggered.
`terraform.yaml` - main implementation of terraform workflow. Contains all jobs needed for terraform flow eg. preparing environment, setup tools, plan and apply terraform scripts and do post actions eg. post "terraform plan" to GitHub Pull Request.


## Workflow triggering <a name="WorkflowTriggering"></a>
This workflow ensures that Terraform configurations are planned and applied in a controlled and automated manner. It handles the setup of environment variables, authentication,  and posting of results to GitHub pull requests, providing a comprehensive solution for managing Terraform operations within a CI/CD pipeline.
Workflow can be trigger manually from the Actions tab on GitHub by selecting the workflow, branch and clicking the "Run workflow" button. This option is only available if the workflow file uses the workflow_dispatch event trigger.

Workflow rules allow trigger only for branches name: `env/*` and `feature/*` .
- If you need run terraform plan and apply changes proper branch name format is:
`env/<ENV_NAME>` eg. : env/dev ; env/sbx.

Environment name must be consistent with GitHub Environment name. So, it branch name is called: `env/sbx`, Github environment name must be called `sbx`.

- If you need run terraform plan ( only checking without appling changes) allowed branch name format is :
` feature/<ENV_NAME>/....` eg: feature/sbx/my_branch_name

Terraform applies changes only for modifications pushed to `env/*` branches. For `feature/*` branches terraform plan is executed only.


## Modifying Workflows <a name="ModifyingWorkflows"></a>
If there is a need of implementing new feature, fixing problem or updating existing terraform script, sample steps are provided below:

- Create a feature branch from env/sbx or env/dev or main
- Create the feature or fix implementation to the modules
- Check the terraform plan if it does what it is expected and no errors is observed.
- Push the feature branch
- Check the github workflow plan result, when fail fix the issues found
- Create a PR for the feature branch to dedicated branch
- Wait the github workflow to check the PR
- Check the created plan in the PR comments
- If a problem was found, fix the issue and retigger workflow.
- If PR check is successful, merge the feature to the env/sbx or env/dev or main branch
- When not, fix the issue found, sometimes just rerun the github workflow to fix it.


## Workflow implementation details <a name="WorkflowImplementationDetails"></a>

### terraform_workflow.yaml
Workflows starts execution from terraform_workflow.yaml. At the beginning workflow define configuration and specify event that trigger the workflow :
- push: The workflow runs when there is a push to branches matching env/** or feature/**, and the changes affect files in the terraform/ directory.
- pull_request: The workflow runs when a pull request targets branches matching env/** or feature/**, and the changes affect files in the terraform/ directory.
- workflow_dispatch: Allows the workflow to be manually triggered.

In workflow is defined 2 jobs:
- parsing-branch - responsible to checkout code and parse branch name to set proper output values: prefix (eg. `env` or `feature`) and <ENV_NAME> (eg. sbx, dev etc.)
- terraform - need parsing-branch job. uses implementation of `workflows/terraform.yaml` . Set proper properties, secrets and input values.

### terraform.yaml
This file contains main workflow implementation. List of inputs and secrets are defined on the top. 2 jobs are defined: get-env and terraform.

Each job conains of more granular tasks. Following steps are defined:
- Print environment name to output - print branch environment and prefix.
- get environment = based on variables 'prefix' and 'branch_env' sets proper action to make.
- Convert key to PKCS#8 format - change format of GH_APP_KEY into PKCS8 format 
- Generate encoded argocd bcrypt hash - generate bcrypt hast from argocd initial password and encodes it with base64.
- set environment variables - set environment varibles based on proper variables required for Terraform operations. Using GitHub Actions, this will be pass to Terraform scripts.
- Get Terraform fetcher GitHub App token - gets github app token using the provided credentials.
- Setup node - Sets up the Node.js environment.
- export TFVARS in Github Secrets - Exports Terraform variables from GitHub secrets.
- export TFVARS in Github Variables - Exports Terraform variables from GitHub variables.
- convert TFVARS to lowercase - converts Terraform variable names to lowercase.
- Checkout source code - check out code from repository.
- Setup gcloud SDK- install and setup gcloud SDK with beta.
- Setup terraform - JavaScript action that sets up Terraform CLI in GitHub Actions workflow. Download and setup terraform.
- terraform plan - check and compare potencial changes or will show syntax errors. Shows you a preview of the changes that will be made to your infrastructure eg. resources that will be created, modified, or destroyed.
- Reformat Plan - reformat output from terraform plan and save to output file.
- Put Plan in Env Var.
- Post Plan to GitHub PR - adds to Github PR comment contains terraform plan output 
- Check if Plan failed - set statuf failed when output outcome is set to failure
- terraform apply - makes apply in infrastructure for proposed changes in terraform plan
- Post Apply Success - adds to Github PR comment regarding apply succeeded with result.
- Post Apply Failure - adds to Github PR comment regarding apply failure with result.
- Fail if apply failed - set apply failed in case of failure.
