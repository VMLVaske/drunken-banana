# Ghost Blog on EC2 (with Terraform + GitHub Actions)

This project provisions and deploys a production-ready Ghost blogging platform on an AWS EC2 instance using Terraform and GitHub Actions. It automates infrastructure creation, bootstraps the Ghost container, adds scheduled backups, and supports redeployment via CI/CD.

## ✅ Features Completed

## 🌟 Future Improvements

## 🎓 Lessons Learned

Ghost uses MySQL by default; to switch to sqlite3 you need to specify `database_client`and `database_connection_filename`in the docker-compose.
Without any dedicated mention, Ghost will default back to MySQL continuously, even when deleting the content dir and the config.json, and crash the container hard.

Docker Compose must use "url=http://localhost" unless you're behind NGINX

Interactive apt installs like postfix must be pre-seeded using debconf-set-selections, because otherwise the gh actions will get stuck in waiting mode, as the postfix dialogue never closes.
This gets ugly if you encounter a deadlock situation, in which you'll either have to restart the entire EC2 or remove the dangling hooks manually.

Elastic IPs will change unless declared in Terraform and attached as a separate resource.

GitHub Actions need a stable SSH user and key—this required generating and base64-encoding a separate deploy key.
On mac, this needs to be done with openssl ;)

## 📃 MISC Notes

Important: By April 2025, AWS EC2 no longer has a general free tier. The t2.micro or t3.micro instances used in this project will incur costs unless your AWS account is still within the first 12 months of creation (Free Tier eligibility).

Be sure to:

Shut down the instance after testing

Use terraform destroy if you’re not using it long-term

Monitor your AWS billing dashboard if unsure

## ✨ How it Works

* terraform apply provisions the EC2 instance, security group, and elastic IP.
* a userdata.sh script is rendered from a template and injected, doing the following:
* Installs Docker & Docker Compose
* Clones this repo to /home/ubuntu/drunken-banana
* Creates a deployer user with SSH access using a Terraform variable
* On any push to main, GitHub Actions:
* * SSHes into the instance as deployer
* * Pulls the latest repo changes
* * Re-runs setup.sh to restart Ghost and cronjobs
* * Backups run every 15 minutes (can be changed to nightly), creating .tar.gz files and emailing metadata to the configured address.

## 🧵 SSH Key Management

The EC2 instance accepts a Terraform-provided SSH keypair for initial ubuntu access.

A separate deployer key is injected via terraform.tfvars and used only by GitHub Actions.

The deployer key is stored in GitHub Secrets as base64 (EC2_DEPLOY_KEY_B64).

To regenerate and base64 your key:

ssh-keygen -t ed25519 -f ghost-deployer-key -N ""
base64 ghost-deployer-key | pbcopy # or use `openssl base64` if on mac

Add the result as a GitHub Secret, and keep the .pub version in terraform.tfvars.

## 🚀 Deploy Your Own

cp terraform.tfvars.example terraform.tfvars
Fill in your public key + deployer key + your preferred backup email address
terraform init
terraform apply

Push to main and watch GitHub Actions take over!