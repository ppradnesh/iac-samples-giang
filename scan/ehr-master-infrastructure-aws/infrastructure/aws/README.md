# EHR Infrastructure
This directory contains instructions and definitions on how to deploy a two-tier architecture,
inline with Amazon's reference, [two-tier Scenario 2.](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Scenario2.html)

## Two-Tier Architecture References 
- https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Scenario2.html
- https://www.terraform.io/intro/examples/aws.html
- https://nickcharlton.net/posts/terraform-aws-vpc.html

## Terraform Docs for AWS
- https://www.terraform.io/docs/providers/aws/index.html

## Install Terraform
1. Download terraform, Windows 64-bit: 
  https://www.terraform.io/downloads.html
1. Unzip and add terraform.exe to path: 
  https://stackoverflow.com/questions/1618280/where-can-i-set-path-to-make-exe-on-windows
1. Verify installation - Open a new Powershell (etc.) window: `terraform`

## AWS Key Info
https://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html#access-keys-and-secret-access-keys

## Configure Terraform
1. Copy the AWS private key file into this directory and name it `ehr-shared.pem` 
1. (Optional) Copy `aws.tfvars.example` to `aws.tfvars` and fill in access and secret keys.

## Using Terraform in existing Terraform environments
From this directory (examples for `test` environment need to be updated):
1. `terraform init`
1. `terraform plan -var-file .\environments\test\test.tfvars -state .\environments\test\terraform.tfstate [-var-file aws.tfvars]`
1. `terraform apply -var-file .\environments\test\test.tfvars -state .\environments\test\terraform.tfstate [-var-file aws.tfvars]`
1. `terraform show .\environments\test\terraform.tfstate`
1. `terraform destroy -var-file .\environments\test\test.tfvars -state .\environments\test\terraform.tfstate [-var-file aws.tfvars]`

## Create a new environment
1. Create a new folder in `./environments`
1. Copy `./environment/environment_name.tfvars.bckp` to {new_folder}/{env_name}.tfvars
1. Ensure ../orchestrator/secrets/ contains a folder matching the new environment name
1. Use same commands for existing environment, above.

## TODO
- lock down Network ACLs?
- narrow all cidr blocks in security groups?
- convert terraform to modules

### Components

#### main.tf
- Root terraform file.  Required to be present and contains the basic AWS provider.

#### clusters.tf
- File to contain the deployment of the EHR docker stacks.  Software and docker deployments after instance creation.

#### instances.tf
- This handles the creation of the 3 EC2 instances for the 2 stacks for the EHR applicaiton.

#### network.tf
- This establishes the whole network layer, namely VPC/Subnets/Security Groups/Route Tables.

#### aws.tfvars
- Definition of the AWS provider variables, namely access and secret keys

#### variables.tf
- Project variables that are consistent across environments