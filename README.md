# TechCorp AWS Infrastructure - Third Semester Month 1 Assessment

This project deploys a highly available web application infrastructure on AWS using Terraform.

## Table of Contents
- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Infrastructure Components](#infrastructure-components)
- [Deployment Steps](#deployment-steps)
- [Post-Deployment Verification](#post-deployment-verification)
- [Accessing the Infrastructure](#accessing-the-infrastructure)
- [Cleanup Instructions](#cleanup-instructions)

---

## Project Overview

This infrastructure demonstrates a production-ready AWS setup with:
- High availability across multiple availability zones
- Secure network isolation using public and private subnets
- Load balancing for web traffic distribution
- Bastion host for secure administrative access
- PostgreSQL database in a private subnet

**Created by:** Abioye Oluwapelumi Abdul-lateef  
**Date:** November 2024  
**Institution:** AltSchool Africa - Cloud Engineering

---

## Architecture

### Network Architecture
- **VPC**: 10.0.0.0/16
- **Public Subnets**: 10.0.1.0/24, 10.0.2.0/24 (across 2 AZs)
- **Private Subnets**: 10.0.3.0/24, 10.0.4.0/24 (across 2 AZs)
- **Internet Gateway**: For public subnet internet access
- **NAT Gateways**: One in each public subnet for private subnet outbound traffic

### Compute Resources
- **Bastion Host**: 1x t3.micro in public subnet
- **Web Servers**: 2x t3.micro in private subnets
- **Database Server**: 1x t3.small in private subnet
- **Application Load Balancer**: Distributing traffic across web servers

### Security Groups
- **Bastion SG**: SSH (22) from admin IP only
- **Web SG**: HTTP (80), HTTPS (443) from anywhere; SSH (22) from Bastion
- **Database SG**: MySQL (3306) from Web SG; SSH (22) from Bastion

---

## Prerequisites

Before deploying this infrastructure, ensure you have:

### 1. AWS Account
- Active AWS account with appropriate permissions
- AWS CLI installed and configured

### 2. Terraform
- Terraform version >= 1.0 installed
- Verify with: `terraform --version`

### 3. SSH Key Pair
- Create an EC2 key pair in your AWS region
- Download and save the `.pem` file securely

### 4. Required Tools
```bash
# Install AWS CLI (if not installed)
sudo apt install awscli -y

# Configure AWS credentials
aws configure
```

### 5. Your Public IP Address
```bash
# Get your public IP
curl ifconfig.me
```

---

## Infrastructure Components

### Resources Created
This Terraform configuration creates approximately 30+ AWS resources:

1. **Networking**: 
   - 1 VPC
   - 4 Subnets (2 public, 2 private)
   - 1 Internet Gateway
   - 2 NAT Gateways
   - 3 Route Tables
   - 4 Route Table Associations

2. **Security**: 
   - 3 Security Groups
   - 3 Elastic IPs

3. **Compute**: 
   - 4 EC2 Instances
   - 1 Application Load Balancer
   - 1 Target Group
   - 2 Target Group Attachments
   - 1 Load Balancer Listener

---

## Deployment Steps

### Step 1: Clone or Download the Repository
```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/month-one-assessment.git
cd month-one-assessment
```

### Step 2: Configure Variables
```bash
# Copy the example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your actual values
nano terraform.tfvars
```

Update these required values:
```hcl
key_pair_name = "your-actual-key-pair-name"    # Your EC2 key name
admin_ip      = "YOUR_PUBLIC_IP/32"            # Your IP with /32
ssh_password  = "YourSecurePassword123!"       # Strong password
```

**IMPORTANT:** Never commit `terraform.tfvars` to Git!

### Step 3: Initialize Terraform
```bash
terraform init
```

Expected output: `Terraform has been successfully initialized!`

### Step 4: Validate Configuration
```bash
terraform validate
```

Expected output: `Success! The configuration is valid.`

### Step 5: Preview the Deployment
```bash
terraform plan
```

Review the resources that will be created. You should see:
```
Plan: 30 to add, 0 to change, 0 to destroy.
```

### Step 6: Deploy the Infrastructure
```bash
terraform apply
```

- Type `yes` when prompted
- Wait 5-8 minutes for deployment to complete

### Step 7: Save the Outputs

After deployment, save the important outputs:
```bash
terraform output > deployment-info.txt
```

Example outputs:
```
bastion_public_ip       = "54.123.45.67"
load_balancer_dns_name  = "techcorp-web-alb-xxxxx.us-east-1.elb.amazonaws.com"
vpc_id                  = "vpc-xxxxx"
web_server_1_private_ip = "10.0.3.x"
web_server_2_private_ip = "10.0.4.x"
database_server_private_ip = "10.0.3.x"
```

---

## ✔️ Post-Deployment Verification

### 1. Check Target Group Health

**AWS Console:**
- Navigate to: EC2 → Target Groups
- Select: `techcorp-web-tg`
- Verify: Both targets show "healthy" status

**Wait 2-3 minutes if targets show "initial" status**

### 2. Access the Web Application
```bash
# Get the Load Balancer URL
terraform output load_balancer_dns_name
```

Open the URL in your browser:
```
http://techcorp-web-alb-xxxxx.us-east-1.elb.amazonaws.com
```

You should see the TechCorp web application with server details.

### 3. Test Load Balancing

Refresh the page multiple times. The Instance ID should alternate between two values, confirming load balancing is working.

### 4. Verify in AWS Console

Check the following in AWS Console:
- **VPC Dashboard**: Verify `techcorp-vpc` exists
- **EC2 Instances**: All 4 instances should be "running"
- **Load Balancer**: `techcorp-web-alb` should be "active"
- **NAT Gateways**: Both should be "available"

---

## Accessing the Infrastructure

### Access Bastion Host

**Method 1: Using SSH Key**
```bash
ssh -i your-key.pem ec2-user@<bastion_public_ip>
```

**Method 2: Using Password**
```bash
ssh techcorpuser@<bastion_public_ip>
# Password: TechCorp2024! (or your configured password)
```

### Access Web Servers from Bastion

Once connected to bastion:
```bash
# SSH to web server 1
ssh techcorpuser@<web_server_1_private_ip>

# Check Apache status
sudo systemctl status httpd

# View web page locally
curl localhost

# Exit web server
exit
```

### Access Database Server from Bastion
```bash
# SSH to database server
ssh techcorpuser@<database_server_private_ip>

# Check PostgreSQL status
sudo systemctl status postgresql

# Connect to PostgreSQL
sudo -u postgres psql

# Inside PostgreSQL:
\l                          # List databases
\c techcorp_db             # Connect to database
\dt                        # List tables
SELECT * FROM application_info;
\q                         # Quit

# Exit database server
exit
```

### Test Database Connection from Web Server
```bash
# From bastion, connect to web server
ssh techcorpuser@<web_server_private_ip>

# Install PostgreSQL client
sudo yum install -y postgresql

# Connect to database
psql -h <database_private_ip> -U techcorp_user -d techcorp_db
# Password: TechCorp2024!

# Test query
SELECT * FROM application_info;

# Exit
\q
exit
```

---

## Cleanup Instructions

**IMPORTANT:** To avoid ongoing AWS charges, destroy all resources when finished.

### Step 1: Preview What Will Be Destroyed
```bash
terraform plan -destroy
```

Review the list of resources that will be deleted.

### Step 2: Destroy All Resources
```bash
terraform destroy
```

- Type `yes` when prompted
- Wait 3-5 minutes for complete destruction

### Step 3: Verify Cleanup

Check AWS Console to confirm all resources are deleted:
- EC2 Instances (terminated)
- Load Balancers (deleted)
- NAT Gateways (deleted)
- VPC (deleted)
- Elastic IPs (released)

### Step 4: Clean Local State Files
```bash
# Remove state files (optional)
rm terraform.tfstate
rm terraform.tfstate.backup
```

**Note:** Your code files remain intact for future deployments.

---

**Cost Saving Tips:**
- Destroy resources when not in use
- Use t2.micro for learning (AWS Free Tier eligible)
- Consider single NAT Gateway for non-production

---

## Project Structure
```
month-one-assessment/
├── main.tf                      # All Terraform resources
├── variables.tf                 # Variable declarations
├── outputs.tf                   # Output definitions
├── terraform.tfvars.example     # Example configuration
├── README.md                    # This file
├── .gitignore                   # Git ignore rules
├── user_data/
│   ├── web_server_setup.sh     # Apache installation script
│   └── db_server_setup.sh      # PostgreSQL installation script
└── evidence/
    ├── terraform-outputs.txt    # Deployment outputs
    ├── resources-list.txt       # List of created resources
    └── screenshots/             # Deployment evidence
```

---

## Security Best Practices

✅ **Implemented:**
- Bastion host for secure access
- Private subnets for application and database tiers
- Security groups with least privilege
- NAT Gateways for outbound traffic only
- No direct internet access to private instances

 **Additional Recommendations:**
- Use AWS Secrets Manager for passwords in production
- Enable VPC Flow Logs for network monitoring
- Implement AWS CloudTrail for API logging
- Use IAM roles instead of access keys
- Enable MFA on AWS account
- Regular security group audits

---

## Contact

**Author:** Abioye Oluwapelumi Abdul-lateef  
**Institution:** AltSchool Africa  
**Program:** Cloud Engineering Track | Baraka Cohort | Third Semester
**Assessment:** Month 1 - Infrastructure as Code

---

## License

This project is submitted as part of AltSchool Africa Cloud Engineering assessment.

---

**Last Updated:** November 2025
