# THIS PROJECT IS FOR MYSELF AND FOR PROOF THAT I CAN DO STUFF
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
    4. Add 3 variable to TC, which are TFC_GCP_PROVIDER AUTH, TFC_GCP_WORKLOAD_PROVIDER_NAME, TFC_GCP_RUN_SERVICE_ACCOUNT_EMAIL

So lets do that!
#### 1. Create Service Account and give it resource role. There are multiple and you need to check from google documentation
Create new Service Account under your project
![Alt text](images/Screenshot%202026-07-24%20230915.png)
![Alt text](images/Screenshot%202026-07-24%20230932.png)

SA name should be usually for what purpose that SA is used.
Then I added these roles for SA:
![Alt text](images/Screenshot%202026-07-24%20231416.png)

Now I'am going to explain why I used those roles for my SA
roles/serviceusage.serviceUsageAdmin = enables GCP API's
roles/compute.admin = Enables Compute Engine creation for my Grafana VM
roles/container.admin = Enables GKE cluster creation
roles/artifactregistry.admin = Enables image registry creation
roles/cloudsql.admin = Enables Cloud SQL creation
roles/secretmanager.admin = 
roles/iam.serviceAccountAdmin = This grants terraform to create new SA's for authenticating between different components in my project. Like my App pod and Cloud SQL connection.
roles/resourcemanager.projectIamAdmin
roles/dns.admin
roles/monitoring.admin