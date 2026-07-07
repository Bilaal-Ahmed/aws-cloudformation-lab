# 🔧 Troubleshooting Guide

Common CloudFormation errors and how to fix them.

---

## ❌ `ROLLBACK_COMPLETE` — Stack creation failed

**What happened:** One or more resources failed to create and the stack rolled back.

**Fix:**
```bash
# View the failure reason
aws cloudformation describe-stack-events \
  --stack-name <your-stack-name> \
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`].[LogicalResourceId,ResourceStatusReason]' \
  --output table

# Delete the ROLLBACK_COMPLETE stack before retrying
aws cloudformation delete-stack --stack-name <your-stack-name>
aws cloudformation wait stack-delete-complete --stack-name <your-stack-name>

# Fix the issue, then re-deploy
bash scripts/deploy.sh
```

---

## ❌ `BucketAlreadyExists` or `BucketAlreadyOwnedByYou`

**What happened:** S3 bucket names must be globally unique. The name you chose is taken.

**Fix:** Change `BucketName` in your parameters file to a more unique name:
```json
{ "ParameterKey": "BucketName", "ParameterValue": "my-unique-cfn-lab-<your-name>-001" }
```

---

## ❌ `InsufficientCapabilitiesException`

**What happened:** Your template creates IAM resources but you didn't pass `--capabilities`.

**Fix:**
```bash
aws cloudformation create-stack ... --capabilities CAPABILITY_NAMED_IAM
```

---

## ❌ `Template format error` on validate

**What happened:** YAML syntax error in your template.

**Fix:** Use `cfn-lint` for detailed error location:
```bash
pip install cfn-lint
cfn-lint templates/s3-bucket.yml
```
Common causes: incorrect indentation, missing quotes, invalid characters.

---

## ❌ Cannot delete stack — bucket not empty

**What happened:** CloudFormation can't delete an S3 bucket that contains objects.

**Fix:** Use the cleanup script which empties buckets first:
```bash
bash scripts/cleanup.sh <stack-name>
```
Or manually:
```bash
# Empty all versions
aws s3 rm s3://<bucket-name> --recursive

# Delete all versions (if versioning is enabled)
aws s3api delete-objects \
  --bucket <bucket-name> \
  --delete "$(aws s3api list-object-versions --bucket <bucket-name> \
    --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' --output json)"
```

---

## ❌ `AccessDenied` on deploy

**What happened:** Your IAM user/role lacks permission to create/manage CloudFormation or specific resources.

**Fix:** Ensure your IAM identity has these permissions:
- `cloudformation:*`
- `s3:*` (or specific S3 actions)
- `iam:PassRole` (if creating IAM resources)

---

## 💡 General Debugging Tips

```bash
# See all events for a stack (most recent first)
aws cloudformation describe-stack-events \
  --stack-name <stack-name> \
  --output table

# Check stack resource statuses
aws cloudformation list-stack-resources \
  --stack-name <stack-name> \
  --output table

# Enable CloudTrail to see all API calls
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventSource,AttributeValue=cloudformation.amazonaws.com \
  --max-results 10
```
