# ✅ AWS CloudFormation Best Practices Guide

A concise reference of best practices to follow when writing and deploying
CloudFormation templates in a professional environment.

---

## 1. Template Authoring

| Practice | Why |
|----------|-----|
| Use YAML over JSON | More readable, supports comments |
| Add `Description` to template | Self-documents the template's purpose |
| Use `Metadata::AWS::CloudFormation::Interface` | Organises parameters in the Console |
| Always specify `AWSTemplateFormatVersion` | Avoids future breaking changes |
| Keep templates under 200 resources | Easier to manage; use nested stacks if needed |

## 2. Parameters

| Practice | Why |
|----------|-----|
| Use `AllowedValues` constraints | Prevents invalid inputs at deployment time |
| Use `AllowedPattern` with regex | Enforce naming conventions |
| Set sensible `Default` values | Enables quick deployments in dev |
| Group parameters with `ParameterGroups` in Metadata | Improves Console UX |
| Separate parameters by environment | Use `s3-bucket-dev.json`, `s3-bucket-prod.json` |

## 3. Security

| Practice | Why |
|----------|-----|
| Block all public S3 access | Prevents data exposure |
| Enforce HTTPS via bucket policy | Encrypts data in transit |
| Enable SSE at rest | Protects data at rest |
| Use `CAPABILITY_NAMED_IAM` deliberately | Forces you to review IAM changes |
| Scan with cfn-nag | Catches security anti-patterns |
| Never hardcode credentials | Use SSM Parameter Store or Secrets Manager |
| Enable CloudTrail | Audits all CloudFormation API calls |

## 4. Tagging Strategy

Always tag every resource with at minimum:

```yaml
Tags:
  - Key: Environment    # dev | staging | prod
  - Key: Project        # project name
  - Key: Owner          # team or individual email
  - Key: ManagedBy      # CloudFormation
  - Key: CostCenter     # for billing allocation
```

## 5. Deployment

| Practice | Why |
|----------|-----|
| Always validate before deploying | `aws cloudformation validate-template` |
| Use Change Sets | Preview changes before applying |
| Use `DeletionPolicy: Retain` on critical resources | Prevents accidental data loss |
| Set `UpdateReplacePolicy: Retain` | Protects against replacement |
| Use stack outputs + `Fn::ImportValue` | Avoids hardcoding values between stacks |
| Enable termination protection in prod | `aws cloudformation update-termination-protection` |

## 6. Naming Conventions

```
Stacks:     <project>-<environment>-<component>
            e.g., myapp-prod-networking
Templates:  <component>-<resource>.yml
            e.g., vpc-baseline.yml
Parameters: <component>-<environment>.json
            e.g., s3-bucket-dev.json
```

## 7. Modularisation (Nested Stacks)

Break large templates into modules:
- `networking.yml` — VPC, subnets, gateways
- `security.yml` — IAM roles, KMS keys, Security Groups
- `compute.yml` — EC2, ASG, ALB
- `data.yml` — S3, RDS, ElastiCache
- `root.yml` — Parent stack that calls nested stacks via `AWS::CloudFormation::Stack`

---

> 📚 References:
> - [AWS CloudFormation Best Practices](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/best-practices.html)
> - [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
> - [cfn-lint](https://github.com/aws-cloudformation/cfn-lint)
> - [cfn-nag](https://github.com/stelligent/cfn_nag)
