# Where's Waldo App Terraform Setup

This repository contains Terraform configuration files to set up the complete infrastructure for the **Where's Waldo** application on AWS. It provisions all necessary AWS services, including S3, SNS, CloudWatch, API Gateway, Lambda functions, and an AWS Amplify app.

## Prerequisites

Before running the Terraform scripts, ensure you have the following:

1. **AWS Account**: You need an active AWS account with the required permissions to provision resources.
2. **Terraform**: Make sure you have [Terraform](https://www.terraform.io/downloads.html) installed.
3. **AWS CLI**: You need to have the [AWS CLI](https://aws.amazon.com/cli/) installed and configured. Run `aws configure` to configure your AWS access key, secret key, region, and output format.
4. **GitHub Access Token**: You'll need a GitHub access token with read/write and webhook access to the repository, specifically the repository [Where's Waldo App GitHub Repository](https://github.com/514-2245-2-team-6/514-2245-2-team-6).
5. **Email Address**: Provide an email address to receive notifications from the app.

## Setup Instructions

### 1. Clone the Repository

Clone the Terraform repository to your local machine:

```bash
git clone https://github.com/514-2245-2-team-6/terraform-infastructure
cd terraform-infastructure
```

### 2. Configure AWS CLI

If you haven't already, configure AWS CLI with your credentials:

```bash
aws configure
```

This will prompt you to enter your AWS access key, secret key, region, and default output format.

### 3. Configure variables

In the `variable-values/prod.tfvars` file, you'll need to fill in the following variables:

- **github_access_token**: Enter your GitHub personal access token with `read/write` and `webhook` access to your repository.
- **email_addresses**: Enter the email addresses that will receive notifications for the app.

Here’s an example of how to set these variables:

```hcl
github_access_token = "ghp_exampleAccessTokenHere"
email_addresses = ["email@example.com"]
```

### 4. Initialize Terraform

Before running Terraform, initialize your workspace to download the required providers and modules:

```bash
terraform init
```

### 5. Apply the Terraform Configuration

Now, you can apply the Terraform configuration to create all the necessary resources on AWS:

```bash
terraform apply -var-file="variable-values/prod.tfvars"
```

Terraform will prompt you to confirm the plan before it starts provisioning resources. Type `yes` to proceed.

### 6. Wait for the Deployment to Finish

Terraform will take a few minutes to deploy the necessary AWS resources. Once completed, you should be shown a link to the web app and have the following services set up:

- **S3 Bucket** for static storage
- **SNS Topic** for notifications
- **CloudWatch Rule** to monitor and log events
- **API Gateway** to handle HTTP requests
- **Lambda Functions** to execute serverless code
- **AWS Amplify App** to host the front-end app

## Teardown Instructions

If you no longer need the infrastructure and want to tear down the resources, you can destroy everything by running the following command:

```bash
terraform destroy -var-file="variable-values/prod.tfvars"
```

Terraform will prompt you to confirm the destruction. Type `yes` to proceed, and Terraform will remove all the resources created on AWS.