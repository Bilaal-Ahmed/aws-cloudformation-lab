# ☁️ aws-cloudformation-lab

> **A hands-on learning laboratory for AWS CloudFormation and Infrastructure as Code (IaC)**
> Built for Junior DevOps Engineers looking to build a production-ready portfolio.

[![AWS](https://img.shields.io/badge/AWS-CloudFormation-FF9900?style=flat&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/cloudformation/)
[![IaC](https://img.shields.io/badge/IaC-Infrastructure%20as%20Code-blue?style=flat)](https://aws.amazon.com/cloudformation/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![YAML](https://img.shields.io/badge/YAML-Templates-cb171e?style=flat&logo=yaml&logoColor=white)](./templates/)
[![Status](https://img.shields.io/badge/Status-Active-brightgreen?style=flat)]()

---

## 📖 Overview

This repository is a structured learning lab for **AWS CloudFormation** — Amazon Web Services' native Infrastructure as Code (IaC) tool. It demonstrates real-world patterns, best practices, and reusable templates that reflect what a DevOps or Cloud Engineer would build in a professional environment.

### 🎯 What You'll Learn

- Writing, validating, and deploying CloudFormation templates (YAML/JSON)
- Managing parameters, outputs, and cross-stack references
- Using CloudFormation StackSets for multi-account/region deployments
- Applying AWS security and tagging best practices
- Automating deployments with AWS CLI and shell scripts
- Building reusable, modular infrastructure components

---

## 🧰 Prerequisites

Before getting started, ensure you have the following tools installed and configured:

| Tool | Version | Purpose |
|------|---------|---------|
| [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) | v2.x | Interact with AWS APIs |
| [AWS Account](https://aws.amazon.com/free/) | Free Tier | Deploy resources |
| [Git](https://git-scm.com/) | 2.x+ | Version control |
| [cfn-lint](https://github.com/aws-cloudformation/cfn-lint) | Latest | CloudFormation linting |
| [Python](https://www.python.org/downloads/) | 3.8+ | Run helper scripts |

### 🔐 AWS CLI Configuration

```bash
# Configure your AWS credentials
aws configure

# You will be prompted for:
# AWS Access Key ID: <your-access-key>
# AWS Secret Access Key: <your-secret-key>
# Default region name: us-east-1
# Default output format: json
```

> ⚠️ **Security Note:** Never commit AWS credentials or secrets to this repository. Use IAM roles, environment variables, or AWS Secrets Manager for credential management.

---

## 📁 Repository Structure

```
aws-cloudformation-lab/
│
├── 📂 templates/               # CloudFormation YAML templates (main IaC code)
│   ├── s3-bucket.yml           # S3 Bucket with versioning, encryption & lifecycle
│   ├── vpc-baseline.yml        # (Coming soon) VPC with subnets, IGW, route tables
│   ├── ec2-instance.yml        # (Coming soon) EC2 with SG, IAM role, EBS
│   └── rds-postgres.yml        # (Coming soon) RDS PostgreSQL with Multi-AZ
│
├── 📂 parameters/              # Environment-specific parameter files
│   ├── s3-bucket-dev.json      # Dev environment parameters
│   └── s3-bucket-prod.json     # Prod environment parameters (example)
│
├── 📂 scripts/                 # Automation scripts for deploy/validate/teardown
│   ├── deploy.sh               # Stack deployment script
│   ├── validate.sh             # Template validation script
│   └── cleanup.sh              # Stack deletion / teardown script
│
├── 📂 docs/                    # Documentation and reference guides
│   ├── ARCHITECTURE.md         # Architecture diagrams and design decisions
│   ├── BEST_PRACTICES.md       # AWS CloudFormation best practices guide
│   └── TROUBLESHOOTING.md      # Common errors and fixes
│
├── 📂 examples/                # Working example deployments for reference
│   └── multi-tier-app/         # Example: multi-tier app stack
│
├── 📂 images/                  # Architecture diagrams and screenshots
│   └── architecture-overview.png
│
├── .gitignore                  # Git ignore rules for AWS/CloudFormation projects
├── LICENSE                     # MIT License
└── README.md                   # This file
```

---

## 🚀 Deployment Instructions

### Step 1 — Clone the Repository

```bash
git clone https://github.com/<your-username>/aws-cloudformation-lab.git
cd aws-cloudformation-lab
```

### Step 2 — Validate a Template

Always validate your template before deploying:

```bash
# Using AWS CLI
aws cloudformation validate-template \
  --template-body file://templates/s3-bucket.yml

# Using cfn-lint (recommended — more detailed output)
cfn-lint templates/s3-bucket.yml
```

### Step 3 — Deploy a Stack

```bash
# Deploy using AWS CLI with a parameters file
aws cloudformation create-stack \
  --stack-name my-s3-lab-stack \
  --template-body file://templates/s3-bucket.yml \
  --parameters file://parameters/s3-bucket-dev.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --tags Key=Environment,Value=dev Key=Project,Value=cfn-lab

# Or use the provided deployment script
bash scripts/deploy.sh
```

### Step 4 — Monitor the Stack

```bash
# Watch stack events in real time
aws cloudformation describe-stack-events \
  --stack-name my-s3-lab-stack \
  --query 'StackEvents[*].[Timestamp,LogicalResourceId,ResourceStatus,ResourceStatusReason]' \
  --output table

# Check stack status
aws cloudformation describe-stacks \
  --stack-name my-s3-lab-stack \
  --query 'Stacks[0].StackStatus'
```

### Step 5 — View Outputs

```bash
aws cloudformation describe-stacks \
  --stack-name my-s3-lab-stack \
  --query 'Stacks[0].Outputs'
```

### Step 6 — Teardown / Delete Stack

```bash
# Delete the stack and all resources
aws cloudformation delete-stack \
  --stack-name my-s3-lab-stack

# Confirm deletion
aws cloudformation wait stack-delete-complete \
  --stack-name my-s3-lab-stack

echo "Stack deleted successfully."
```

---

## 🛠️ Useful AWS CLI Commands

```bash
# ─── Stack Management ────────────────────────────────────────────────────────

# List all stacks (active)
aws cloudformation list-stacks \
  --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE

# Update an existing stack
aws cloudformation update-stack \
  --stack-name my-s3-lab-stack \
  --template-body file://templates/s3-bucket.yml \
  --parameters file://parameters/s3-bucket-dev.json

# Create a Change Set (preview changes before applying)
aws cloudformation create-change-set \
  --stack-name my-s3-lab-stack \
  --change-set-name my-change-set \
  --template-body file://templates/s3-bucket.yml

# Execute the Change Set
aws cloudformation execute-change-set \
  --stack-name my-s3-lab-stack \
  --change-set-name my-change-set

# ─── Template Packaging ───────────────────────────────────────────────────────

# Package template (useful for nested stacks or Lambda code)
aws cloudformation package \
  --template-file templates/s3-bucket.yml \
  --s3-bucket your-deployment-bucket \
  --output-template-file packaged-template.yml

# ─── Drift Detection ─────────────────────────────────────────────────────────

# Detect configuration drift
aws cloudformation detect-stack-drift \
  --stack-name my-s3-lab-stack

# Get drift results
aws cloudformation describe-stack-resource-drifts \
  --stack-name my-s3-lab-stack \
  --stack-resource-drift-status-filters MODIFIED DELETED
```

---

## 🗺️ Learning Roadmap

Use this roadmap to progressively build your CloudFormation skills:

```
Phase 1 — Foundations
├── ✅ Understand CloudFormation concepts (Stacks, Templates, Resources)
├── ✅ Write your first template (S3 Bucket)
├── ✅ Deploy via AWS CLI
└── ✅ Understand Parameters, Outputs, and Mappings

Phase 2 — Networking & Compute
├── 🔲 VPC, Subnets, Internet Gateway, Route Tables
├── 🔲 Security Groups and NACLs
├── 🔲 EC2 Instances with UserData and IAM Roles
└── 🔲 Auto Scaling Groups and Launch Templates

Phase 3 — Managed Services
├── 🔲 RDS (PostgreSQL / MySQL) with Multi-AZ
├── 🔲 ElastiCache (Redis)
├── 🔲 SQS Queues and SNS Topics
└── 🔲 Lambda Functions with IAM Roles

Phase 4 — Advanced Patterns
├── 🔲 Nested Stacks for modularity
├── 🔲 StackSets for multi-account deployments
├── 🔲 CloudFormation Macros and Transforms (SAM)
└── 🔲 Custom Resources with Lambda

Phase 5 — CI/CD Integration
├── 🔲 GitHub Actions pipeline for CloudFormation
├── 🔲 AWS CodePipeline + CloudFormation deployments
├── 🔲 cfn-lint in CI pipelines
└── 🔲 cfn-nag for security scanning
```

---

## 📚 Key Concepts Reference

| Concept | Description |
|---------|-------------|
| **Stack** | A collection of AWS resources managed as a single unit |
| **Template** | YAML/JSON file that defines your infrastructure |
| **Parameters** | Input values passed at stack creation/update |
| **Outputs** | Values exported from a stack (e.g., ARN, endpoint URL) |
| **Mappings** | Static lookup tables in your template |
| **Conditions** | Logic to conditionally create resources |
| **Change Set** | Preview of changes before applying an update |
| **Drift** | Deviation between actual resources and template |
| **StackSet** | Deploy stacks across multiple accounts/regions |
| **Nested Stack** | A stack called from within another template |

---

## 🔒 Security Best Practices

- ✅ Use **least-privilege IAM roles** for all CloudFormation deployments
- ✅ Enable **CloudTrail** to audit all CloudFormation API calls
- ✅ Never hardcode credentials — use **AWS Secrets Manager** or SSM Parameter Store
- ✅ Enable **S3 bucket versioning and server-side encryption** (as shown in templates)
- ✅ Use **cfn-nag** to scan templates for security anti-patterns
- ✅ Apply consistent **resource tagging** for cost allocation and governance

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/add-vpc-template`)
3. Commit your changes (`git commit -m 'feat: add VPC baseline template'`)
4. Push to the branch (`git push origin feature/add-vpc-template`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](./LICENSE) file for details.

---

## 👤 Author

**Junior DevOps Engineer**
- Building cloud skills one stack at a time ☁️
- Learning AWS, IaC, and DevOps best practices

---

> 💡 **Pro Tip:** Star ⭐ this repository to bookmark it and track your progress through the roadmap!
