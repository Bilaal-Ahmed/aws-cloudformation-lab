# Multi-Tier Application — Example Reference

This directory demonstrates the **nested stack pattern** for organizing
a multi-tier AWS application using CloudFormation.

## Stack Layers

```
root-stack.yml          ← Parent / Orchestrator
├── networking.yml      ← VPC, Subnets, IGW, Route Tables   [TODO]
├── security.yml        ← Security Groups, IAM Roles, KMS    [TODO]
├── data.yml            ← S3, RDS, ElastiCache               [TODO]
└── compute.yml         ← EC2, ASG, ALB                      [TODO]
```

## How to Use This Pattern

1. Upload all nested templates to S3
2. Deploy the root stack, passing the S3 bucket name as a parameter
3. CloudFormation manages the order of stack creation (respecting `DependsOn`)
4. Cross-stack values flow via `Outputs` and `!GetAtt <NestedStack>.Outputs.<Key>`

## Key CloudFormation Concepts Demonstrated

- `AWS::CloudFormation::Stack` — Nested stack resource type
- `!FindInMap` — Environment-specific configuration via Mappings
- `!GetAtt <Stack>.Outputs.<Key>` — Passing values between nested stacks
- `DependsOn` — Explicit dependency ordering
- `DeletionPolicy` and `UpdateReplacePolicy` — Lifecycle management

## Next Steps

Complete the individual nested stack templates (networking.yml, etc.)
following the same commenting and parameterisation style used in `s3-bucket.yml`.
