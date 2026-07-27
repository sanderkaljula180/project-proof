# THIS PROJECT DOCUMENTATION IS FOR FUTURE ME
In my last job we couldn't use the cloud—for security reasons, everything had to be on-prem. This project is my way of learning Kubernetes, Terraform, and gcloud, and I'll document every step here. The app I'm building the platform around is a simple Spring CRUD application.

## ARCHITECTURE DIAGRAM
I made this diagram using draw.io. It is nothing special, it's just for me to keep my ideas organized.
![Alt text](images/Screenshot%202026-07-18%20182317.png)

## STEP 1 - DOCKERIZE THE APP
This app wasn't dockerized, so for development team and for kubernetes in cloud I had to create Dockerfile.
At last job we mostly worked with Maven but this one was done using Gradle, so this was a new experience for me. When creating Dockerfile I used three pillars for it:
🔒 Security
⚡ Speed
👁️ Clarity

Also I wrote down a principle guide using those three pillars given by Youtuber named 'DevOps Directive'.

- 🔒 ⚡ 👁️ Pin specific versions
  - 🔒 ⚡ 👁️ Base images (either major+minor OR SHA256 hash)
    - 🔒 👁️ System Dependencies
    - 🔒 👁️ Application Dependencies
- 🔒 ⚡ Use small + secure base images
- ⚡ 👁️ Protect the layer cache
  - ⚡ Order commands by frequency of change
  - ⚡ COPY dependency requirements file → install deps → copy remaining source code
  - ⚡ Use cache mounts
  - ⚡ Use COPY --link
  - ⚡ 👁️ Combine steps that are always linked (use heredocs to improve tidiness)
- 🔒 👁️ Be explicit
  - 👁️ Set working directory with WORKDIR
  - 👁️ Indicate standard port with EXPOSE
  - 🔒 👁️ Set default environment variables with ENV
- 🔒 ⚡ 👁️ Avoid unnecessary files
  - 🔒 ⚡ 👁️ Use .dockerignore
  - 🔒 ⚡ 👁️ COPY specific files
  - 🔒 Use non-root USER
- 🔒 ⚡ 👁️ Install only production dependencies
  - 🔒 Avoid leaking sensitive information
  - 🔒 ⚡ Leverage multi-stage builds

I think this guide is great for creating secure and fast Dockerfile for my app. Also I added comments for every line I created in Dockerfile, so I won't describe here what I did, just check the Dockerfile in app\realworld-java21-springboot3

## STEP 2 - DOCKER-COMPOSE FOR LOCAL DEVELOPMENT
So for development I added docker-compose with PostgreSQL added on it. Originally this app used an H2 in-memory database but for persistence I added PostgreSQL.
So now when you use `docker compose up` it will boot up Postgres and Spring app containers.
Also added comments for every line in docker-compose.yml.

## STEP 3 TERRAFORM CLOUD SETUP
### 3.1 Install Terraform CLI and gcloud authenticate
NB! Since I'm doing this on my home PC running Windows 11, I set up a WSL session to work in.
So first we need to install Terraform CLI on linux. I just used this official Terraform guide for it
https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli

Also now we need to authenticate ourselves into gcloud through terminal. I used this command `gcloud auth login --no-launch-browser`. Why use --no-launch-browser?
Because we are in WSL, it might not open your browser for authentication, which happened to me. So when you use this flag, it will just give you the URL and you can go from there.

### 3.2 Create GCP project
Go to google cloud console in browser and just create a new project
![Alt text](images/Screenshot%202026-07-21%20172857.png)

Billing right now is free tier. I have couple of days left

### 3.3 Create Terraform Cloud workspace and connect the Terraform Cloud workspace to your git repo
Now for this I can use CLI-driven or VCS-driven. I am going to choose VCS because I'm going to use github as trigger. Basically I push to the repo, terraform cloud sees the change and will automatically run the plan, I will check it from UI and apply it.
Also you can choose between OAuth or Github App options. One is OAuth and other is were you install TC app into your github account, this way you can tell TC to only watch one repository.
I will choose Github App. Next I am going to give you steps how to create workspace and connect it to your git repo.
- Go to app.terraform.io
- Create new workspace
- Now it lets you choose between three options. Take 'Version Control Workflow'
- 'Connect to a version control provider'. Choose from there your version control provider. I will choose 'GitHub.com', after that you will get Authentication window pop-up. Press Authorize button.
- Now you can choose 'Only select repositories' option and select your repository which one you want it to be installed on.
- Then you need to choose on TC also which repository you want that workspace to be on
- So we have done our current task, created new workspace and connected the TC workspace with github repo. We will change some settings after we have created our terraform files. But right now we will run plans manually from UI.

### 3.4 Give Terraform Cloud access to GCP with Dynamic Provider Credentials/Workload Identity Federation
Now if you want to create resources through Terraform Cloud you need to create secure connection between TC and GCP. Basically you have to create Workload Identity Federation pool with a provider which is TC. GCP Workload Identity pool is authentication for exterior systems. First time I learned Terraform, I put down some notes on paper, these are the notes:
- Steps for connecting TC and GCP
    1. Create Service Account and give it resource role. There are multiple and you need to check from google documentation
    2. Create Workload Identity Federation pool and add TC into OIDC providers
    3. In IAM, grant the roles/iam.workloadIdentityUser role to the principal on your service account
    4. Add 3 variable to TC, which are TFC_GCP_PROVIDER_AUTH, TFC_GCP_WORKLOAD_PROVIDER_NAME, TFC_GCP_RUN_SERVICE_ACCOUNT_EMAIL

So lets do that!
#### 1. Create Service Account and give it resource role. There are multiple and you need to check from google documentation
Create new Service Account under your project
![Alt text](images/Screenshot%202026-07-24%20230915.png)
![Alt text](images/Screenshot%202026-07-24%20230932.png)

SA name should be usually for what purpose that SA is used.
Then I added these roles for SA:
![Alt text](images/Screenshot%202026-07-24%20231416.png)

Now I'am going to explain why I used those roles for my SA
- roles/serviceusage.serviceUsageAdmin = enables GCP API's
- roles/compute.admin = Enables Compute Engine creation for my Grafana VM
- roles/container.admin = Enables GKE cluster creation
- roles/artifactregistry.admin = Enables image registry creation
- roles/cloudsql.admin = Enables Cloud SQL creation
- roles/secretmanager.admin = Enables secret manager creation
- roles/iam.serviceAccountAdmin = This grants terraform to create new SA's for authenticating between different components in my project. Like my App pod and Cloud SQL connection.
- roles/resourcemanager.projectIamAdmin = This one grants roles to those SA's
- roles/dns.admin = for dns
- roles/monitoring.admin = can create uptime checks and alerts

#### 2. Create Workload Identity Federation pool and add TC into OIDC providers
So this is where you can create that pool
![Alt text](images/Screenshot%202026-07-26%20213408.png)

Lets add provider, which is OIDC. 
Then provider details which is a name that you understand. 
For Issuer URL you add terraform cloud URL which is https://app.terraform.io or if you have on-prem/self-hosted, you will add that one.
For audience you use 'Default audience'. I haven't looked up when do use custom audience, I guess it is when you self-host or like for some specific requirement?
![Alt text](images/Screenshot%202026-07-26%20214058.png)

Now I need to configure provider attributes. Like I understand, it is basically a variable that google uses to decide whether to accept provider or not.
Oh it is basically just a HashMap, like in java. It suggest me do use assertion.sub so I will use that. I think I am getting too deep in this right now.

I got a error after pressing save, which is actually great it happened right now.
![Alt text](images/Screenshot%202026-07-26%20215923.png)

Well it suggest me 'attribute.sub' but I found out that it is not enough. Okay I guess the first box is for setting the mapping and other one is for checking the terraform cloud organization name. So add this '.startsWith' and your organization name in terraform cloud
![Alt text](images/Screenshot%202026-07-26%20220740.png)

#### 3. In IAM, grant the roles/iam.workloadIdentityUser role to the principal on your service account
Now we need to 'Add principal' for that same pool. Basically pool makes the authentication but this terraform identity in this pool has no power yet, so we gonna give it some power. This 'roles/iam.workloadIdentityUser' allowes that identity in that pool to impersonate as SA. You press 'Grant access'.
![Alt text](images/Screenshot%202026-07-26%20221746.png)

Now we need to add New principals, you can add that in different formats but we are going to use 'principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/*'. I got that from [hashi corp documentation](https://developer.hashicorp.com/terraform/cloud-docs/registry/test/dynamic-credentials/gcp), under the 'Grant Workload Identity Pool access to the service account' section.

PROJECT_NUMBER you can get from here
![Alt text](images/Screenshot%202026-07-26%20224451.png)

POOL_ID from here
![Alt text](images/Screenshot%202026-07-26%20224520.png)

So we add that principal and a role, click Save and there we have it.
![Alt text](images/Screenshot%202026-07-26%20224737.png)

#### 4. Add 3 variable to TC, which are TFC_GCP_PROVIDER_AUTH, TFC_GCP_WORKLOAD_PROVIDER_NAME, TFC_GCP_RUN_SERVICE_ACCOUNT_EMAIL
Now we need to create variables in Terraform Cloud. You can do it by going to your Workspace > Variables and adding them into Environment variables. Press '+ Add variable' button under 'Workspace variables'.
![Alt text](images/Screenshot%202026-07-26%20230242.png)

- TFC_GCP_PROVIDER_AUTH = set this one true, it's boolean
- TFC_GCP_WORKLOAD_PROVIDER_NAME = full name of Workload Identity provider. 'projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/providers/PROVIDER_ID'
    - PROJECT_NUMBER, POOL_ID = same from the principalSet
    - PROVIDER_ID = provider name from the pool you created
- TFC_GCP_RUN_SERVICE_ACCOUNT_EMAIL = Terraform service account email. Find your terraform cloud SA from GCP IAM and paste it there

No need to tick the sensitive box because there is nothing to protect. That is the beauty of Workload Identity Federation pool. 
!!!!!FYI On the images I am going to upload, there is one variable with sensitive box ticked, it was accidental.
![Alt text](images/Screenshot%202026-07-26%20231621.png)

So there is no way do test if it works, fast, atleast I haven't found one. We need to move onto the next step.

## STEP 4 IaC through Terraform Cloud

First I am going to create my terraform file hierarchy. It's going to be simple, in the root there will be:
- main.tf = This one adds the provider, calls modules and passes the variables
- variables.tf = This one declares variables
- terraform.tfvars = This one gives variables values
- api.tf = This is for enabling GCP API's

I won't separate them by environments because I don't have different stagings because I don't need one, this won't go live.
Inside modules folder there will be folders for each resource and inside each module folder there are three files:
- main.tf
- variables.tf = Module variable file is for module own variables
- outputs.tf = This is for when I need module outputs for the root

Simple. We'll see how can I use them now. I will go step by step

Also I'am going to use terraform own GCP [documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
Also I will comment everything in terraform files, like what is the purpose of that block and functions.

### 4.1 Lets enable required GCP API's
If I remember correctly I need to add google as provider in root main.tf, then I can start enabling API's in api.tf.

First we add required_providers and provider configuration inside root main.tf. Also I am using variables already for provider configuration, so I'm going to explain how variables work here. It is simple, you declare variables in variables.tf, then you give those variables a value in terraform.tfvars and then you can use them inside main.tf.
Again, I commented what those blocks do in files, so check the files.
Setting up terraform provider, I just used terraform GCP documentation in [here](https://registry.terraform.io/providers/hashicorp/google/latest)
![Alt text](images/Screenshot%202026-07-27%20220711.png)

Now, lets create the first resource block which is for enabling API's. First I will talk about the syntax. 

```hcl
resource "THIS_IS_RESOURCE_TYPE_FROM_PROVIDER" "this_is_your_label" {
  # for_each tells terraform to create one copy of this resource per item in this set.
  # for_each requires a set or map, so toset() converts the list into a set.
  # you also need to declare it inside service argument down below
  for_each = toset([
    "item1",
    "item2",
    "item3",
  ])
  
  # declared for_each set
  service = each.value

  # other arguments
}
```

Now this is out of the way. Let's enable some API's inside api.tf.