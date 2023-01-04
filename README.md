# Wordpress installation using Terraform


Hi! I'm here to discuss Wordpress installation using Terraform. I am planning to execute this setup using VPC and subnets and going to try this setup using Terraform. 

## Following are the resources we need to create for this setup:

- VPC 
- Subnets [3 Public subnets and 3 private subnets]
- Internet Gateway
- NAT Gateway
- Route tables [Public and private]
- Frontend-server 
- Backend-server
- Bastion-server
- Keypair
- Security groups

## Prerequisites

- IAM user with Programmatic access to AWS with AmazonEc2FullAccess and AmazonRoute53FullAccess
- Initializing Terraform 


### IAM user with Programmatic access to AWS with AmazonEc2FullAccess and AmazonRoute53FullAccess

To do the same we need to create an IAM user with programmatic access. While creating user it will generate Access key and Secret key. Save the keys at your end safely as it required further.

### Initializing Terraform and creating project directory

As an intital setup, we need to install and configure Terraform. Here I am going to install Terraform in one of the EC2 instance configured in the region ap-south-1. Download the file to install Terraform based on the OS. Here I am using linux platform so I have choosen a link based on that.
````
$ wget https://releases.hashicorp.com/terraform/1.3.6/terraform_1.3.6_linux_amd64.zip
unzip terraform_1.3.6_linux_amd64.zip
````
#### Create project directory 

Let it be "terraform-vpc-infra".
```
mkdir terraform-vpc-infra
cd terraform-vpc-infra
```
After making project directory, for easiness I am creating some terraform files like 

```
provider.tf  \\provider config entries
main.tf  \\resource entries
variables.tf \\variable entries
datasource.tf \\datasource entries
outputs.tf \\output entries
```

Here we are using AWS as provider. To start the work we need to initialize the terraform by entring the provider configuration files. Refer the below link:

```
https://registry.terraform.io/providers/hashicorp/aws/4.48.0
```
### Initialize the Terraform project directory

After configuring provider we can use below command to initialize project directory. 

```
$ terraform init
```
## Project Description

Here we are going to create VPC in the region ap-south-1 with name "terraformvpc" using the block 172.16.0.0/16. In this setup I am planning to do the wordpress installation with 6 subnets. 3 of them are public and 3 of them are private. For using these subnets, I need to configure some other resources like internet-gateway, NAT-gateway, Route-tables. Once we finished the creation of VPC . Then, we are going to download and install wordpress in instance called "frontend" and database in "backend". We can SSH to both the instances via "bastion". Since updating the value of DB_HOST in wp-config.php file is demanding, we need to create a private hosted zone define an A record whose IP address will be the private IP address of the Backend-server. This A record is used as the value of DB_HOST. Once it has been done, we can check whether the site is loading fine by accessing the site with the domain name assigned to the public IP of the "frontend". If the site running without issues, our setup has been completed.


Hope this will definitely help you to setup a simple wordpress setup with VPC and subnets and how to execute the same using Terraform...Try same and have fun!!!!

