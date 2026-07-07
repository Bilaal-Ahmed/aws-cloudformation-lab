#!/usr/bin/env bash
# ==============================================================================
# cleanup.sh — CloudFormation Stack Teardown Script
#
# Description: Safely deletes a CloudFormation stack. Handles non-empty S3
#              buckets (which must be emptied before stack deletion) and
#              provides confirmation prompts to prevent accidents.
#
# Usage:
#   bash scripts/cleanup.sh [STACK_NAME] [REGION]
#   bash scripts/cleanup.sh my-s3-lab-stack us-east-1
#
# ⚠️  WARNING: This PERMANENTLY deletes all stack resources. Use with caution.
#
# Author: aws-cloudformation-lab
# ==============================================================================

set -euo pipefail

# ANSI Color Codes
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC}    $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}    $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC}   $1" >&2; }

STACK_NAME="${1:-my-s3-lab-stack}"
AWS_REGION="${2:-${AWS_DEFAULT_REGION:-us-east-1}}"

echo -e "\n${RED}══════════════════════════════════════════${NC}"
echo -e "${RED}  ⚠️  CloudFormation Stack Teardown${NC}"
echo -e "${RED}══════════════════════════════════════════${NC}\n"

log_warn "You are about to DELETE stack: ${RED}$STACK_NAME${NC}"
log_warn "Region: $AWS_REGION"
log_warn "This action is IRREVERSIBLE. All associated resources will be deleted."

# Safety confirmation — requires typing the stack name
echo ""
read -r -p "$(echo -e "${RED}Type the stack name to confirm deletion: ${NC}")" CONFIRM
if [[ "$CONFIRM" != "$STACK_NAME" ]]; then
  log_info "Confirmation did not match. Teardown cancelled. Stack is safe."
  exit 0
fi

# ── Check stack exists ────────────────────────────────────────────────────────
log_info "Checking if stack '$STACK_NAME' exists..."
STACK_STATUS=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION" \
  --query 'Stacks[0].StackStatus' \
  --output text 2>/dev/null || echo "DOES_NOT_EXIST")

if [[ "$STACK_STATUS" == "DOES_NOT_EXIST" ]]; then
  log_warn "Stack '$STACK_NAME' does not exist or has already been deleted."
  exit 0
fi
log_info "Stack found. Current status: $STACK_STATUS"

# ── Empty S3 Buckets (required before stack deletion if versioning is enabled) ─
# CloudFormation CANNOT delete a non-empty S3 bucket. We must empty it first.
log_info "Checking for S3 buckets in stack that need to be emptied..."

BUCKETS=$(aws cloudformation list-stack-resources \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION" \
  --query "StackResourceSummaries[?ResourceType=='AWS::S3::Bucket'].PhysicalResourceId" \
  --output text 2>/dev/null || true)

for BUCKET in $BUCKETS; do
  if [[ -n "$BUCKET" ]]; then
    log_warn "Emptying S3 bucket: $BUCKET (required for deletion)"

    # Delete all object versions (needed when versioning is enabled)
    aws s3api list-object-versions \
      --bucket "$BUCKET" \
      --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' \
      --output json 2>/dev/null | \
    python3 -c "
import sys, json, subprocess
data = json.load(sys.stdin)
objects = data.get('Objects') or []
if objects:
    payload = json.dumps({'Objects': objects, 'Quiet': True})
    subprocess.run(['aws','s3api','delete-objects','--bucket','$BUCKET','--delete',payload], check=True)
    print(f'  Deleted {len(objects)} object version(s).')
else:
    print('  No object versions to delete.')
" || true

    # Delete all delete markers
    aws s3api list-object-versions \
      --bucket "$BUCKET" \
      --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' \
      --output json 2>/dev/null | \
    python3 -c "
import sys, json, subprocess
data = json.load(sys.stdin)
markers = data.get('Objects') or []
if markers:
    payload = json.dumps({'Objects': markers, 'Quiet': True})
    subprocess.run(['aws','s3api','delete-objects','--bucket','$BUCKET','--delete',payload], check=True)
    print(f'  Deleted {len(markers)} delete marker(s).')
" || true

    log_success "Bucket $BUCKET emptied."
  fi
done

# ── Delete the Stack ──────────────────────────────────────────────────────────
log_info "Initiating stack deletion: $STACK_NAME..."
aws cloudformation delete-stack \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION"

log_info "Waiting for stack deletion to complete (this may take a few minutes)..."
aws cloudformation wait stack-delete-complete \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION"

log_success "✅ Stack '$STACK_NAME' deleted successfully."
