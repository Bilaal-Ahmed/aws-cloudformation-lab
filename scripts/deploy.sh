#!/usr/bin/env bash
# ==============================================================================
# deploy.sh — CloudFormation Stack Deployment Script
#
# Description: Deploys or updates a CloudFormation stack with validation,
#              change set preview, and rollback support.
#
# Usage:
#   bash scripts/deploy.sh [STACK_NAME] [TEMPLATE_FILE] [PARAMS_FILE] [REGION]
#
# Examples:
#   bash scripts/deploy.sh my-s3-stack templates/s3-bucket.yml parameters/s3-bucket-dev.json us-east-1
#   bash scripts/deploy.sh  # Uses defaults defined in the script
#
# Author: aws-cloudformation-lab
# ==============================================================================

set -euo pipefail  # Exit on error, undefined var, or pipe failure

# ──────────────────────────────────────────────────────────────────────────────
# ANSI Color Codes for pretty output
# ──────────────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'  # No Color (reset)

# ──────────────────────────────────────────────────────────────────────────────
# DEFAULT CONFIGURATION — Override via arguments or environment variables
# ──────────────────────────────────────────────────────────────────────────────
STACK_NAME="${1:-my-s3-lab-stack}"
TEMPLATE_FILE="${2:-templates/s3-bucket.yml}"
PARAMS_FILE="${3:-parameters/s3-bucket-dev.json}"
AWS_REGION="${4:-${AWS_DEFAULT_REGION:-us-east-1}}"
CAPABILITIES="CAPABILITY_NAMED_IAM"

# ──────────────────────────────────────────────────────────────────────────────
# HELPER FUNCTIONS
# ──────────────────────────────────────────────────────────────────────────────
log_info()    { echo -e "${BLUE}[INFO]${NC}    $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}    $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC}   $1" >&2; }
log_section() { echo -e "\n${CYAN}══════════════════════════════════════════${NC}"; echo -e "${CYAN}  $1${NC}"; echo -e "${CYAN}══════════════════════════════════════════${NC}"; }

# ──────────────────────────────────────────────────────────────────────────────
# PRE-FLIGHT CHECKS
# ──────────────────────────────────────────────────────────────────────────────
log_section "☁️  CloudFormation Deploy — Pre-flight Checks"

# Check AWS CLI is available
if ! command -v aws &>/dev/null; then
  log_error "AWS CLI not found. Install it: https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html"
  exit 1
fi
log_info "AWS CLI found: $(aws --version 2>&1 | head -1)"

# Check template file exists
if [[ ! -f "$TEMPLATE_FILE" ]]; then
  log_error "Template file not found: $TEMPLATE_FILE"
  exit 1
fi
log_info "Template: $TEMPLATE_FILE"

# Check parameters file exists
if [[ ! -f "$PARAMS_FILE" ]]; then
  log_error "Parameters file not found: $PARAMS_FILE"
  exit 1
fi
log_info "Parameters: $PARAMS_FILE"
log_info "Stack Name: $STACK_NAME"
log_info "Region: $AWS_REGION"

# Check AWS identity (confirms credentials are configured)
log_section "🔐 Verifying AWS Identity"
CALLER_IDENTITY=$(aws sts get-caller-identity --output json 2>&1) || {
  log_error "Failed to get AWS identity. Check your credentials with: aws configure"
  exit 1
}
ACCOUNT_ID=$(echo "$CALLER_IDENTITY" | python3 -c "import sys, json; print(json.load(sys.stdin)['Account'])")
ARN=$(echo "$CALLER_IDENTITY" | python3 -c "import sys, json; print(json.load(sys.stdin)['Arn'])")
log_info "Account ID: $ACCOUNT_ID"
log_info "Caller ARN: $ARN"

# ──────────────────────────────────────────────────────────────────────────────
# TEMPLATE VALIDATION
# ──────────────────────────────────────────────────────────────────────────────
log_section "🔍 Validating CloudFormation Template"

aws cloudformation validate-template \
  --template-body "file://$TEMPLATE_FILE" \
  --region "$AWS_REGION" \
  --output table

log_success "Template validation passed!"

# Run cfn-lint if available (optional but recommended)
if command -v cfn-lint &>/dev/null; then
  log_info "Running cfn-lint..."
  cfn-lint "$TEMPLATE_FILE" && log_success "cfn-lint passed!" || log_warn "cfn-lint reported warnings — review before prod deployment."
else
  log_warn "cfn-lint not installed. Install it: pip install cfn-lint"
fi

# ──────────────────────────────────────────────────────────────────────────────
# CHECK IF STACK EXISTS — DECIDE CREATE vs UPDATE
# ──────────────────────────────────────────────────────────────────────────────
log_section "📋 Checking Stack Status"

STACK_STATUS=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION" \
  --query 'Stacks[0].StackStatus' \
  --output text 2>/dev/null || echo "DOES_NOT_EXIST")

log_info "Stack '$STACK_NAME' status: $STACK_STATUS"

# ──────────────────────────────────────────────────────────────────────────────
# DEPLOY USING CHANGE SET (works for both CREATE and UPDATE)
# Using change sets is a best practice — always preview before applying.
# ──────────────────────────────────────────────────────────────────────────────
log_section "📝 Creating Change Set"

CHANGE_SET_NAME="deploy-$(date +%Y%m%d%H%M%S)"
CHANGE_SET_TYPE="CREATE"

if [[ "$STACK_STATUS" != "DOES_NOT_EXIST" ]]; then
  CHANGE_SET_TYPE="UPDATE"
fi

log_info "Change set type: $CHANGE_SET_TYPE"
log_info "Change set name: $CHANGE_SET_NAME"

aws cloudformation create-change-set \
  --stack-name "$STACK_NAME" \
  --change-set-name "$CHANGE_SET_NAME" \
  --change-set-type "$CHANGE_SET_TYPE" \
  --template-body "file://$TEMPLATE_FILE" \
  --parameters "file://$PARAMS_FILE" \
  --capabilities "$CAPABILITIES" \
  --region "$AWS_REGION" \
  --tags Key=ManagedBy,Value=CloudFormation Key=DeployedAt,Value="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

log_info "Waiting for change set to be created..."
aws cloudformation wait change-set-create-complete \
  --stack-name "$STACK_NAME" \
  --change-set-name "$CHANGE_SET_NAME" \
  --region "$AWS_REGION" \
  2>/dev/null || {
    # Check if there are no changes (which causes wait to fail)
    STATUS=$(aws cloudformation describe-change-set \
      --stack-name "$STACK_NAME" \
      --change-set-name "$CHANGE_SET_NAME" \
      --region "$AWS_REGION" \
      --query 'Status' --output text)
    REASON=$(aws cloudformation describe-change-set \
      --stack-name "$STACK_NAME" \
      --change-set-name "$CHANGE_SET_NAME" \
      --region "$AWS_REGION" \
      --query 'StatusReason' --output text)
    if [[ "$REASON" == *"The submitted information didn't contain changes"* ]]; then
      log_warn "No changes detected. Stack is already up to date."
      aws cloudformation delete-change-set \
        --stack-name "$STACK_NAME" \
        --change-set-name "$CHANGE_SET_NAME" \
        --region "$AWS_REGION"
      exit 0
    fi
    log_error "Change set failed: $REASON"
    exit 1
  }

# Display the changes that will be applied
log_section "📊 Planned Changes"
aws cloudformation describe-change-set \
  --stack-name "$STACK_NAME" \
  --change-set-name "$CHANGE_SET_NAME" \
  --region "$AWS_REGION" \
  --query 'Changes[*].[Type,ResourceChange.Action,ResourceChange.LogicalResourceId,ResourceChange.ResourceType]' \
  --output table

# ──────────────────────────────────────────────────────────────────────────────
# CONFIRMATION PROMPT (skipped in CI environments)
# ──────────────────────────────────────────────────────────────────────────────
if [[ -z "${CI:-}" ]]; then
  echo ""
  read -r -p "$(echo -e "${YELLOW}Apply changes? (yes/no): ${NC}")" CONFIRM
  if [[ "$CONFIRM" != "yes" ]]; then
    log_warn "Deployment cancelled. Cleaning up change set..."
    aws cloudformation delete-change-set \
      --stack-name "$STACK_NAME" \
      --change-set-name "$CHANGE_SET_NAME" \
      --region "$AWS_REGION"
    exit 0
  fi
fi

# ──────────────────────────────────────────────────────────────────────────────
# EXECUTE CHANGE SET
# ──────────────────────────────────────────────────────────────────────────────
log_section "🚀 Executing Change Set"

aws cloudformation execute-change-set \
  --stack-name "$STACK_NAME" \
  --change-set-name "$CHANGE_SET_NAME" \
  --region "$AWS_REGION"

log_info "Waiting for stack $CHANGE_SET_TYPE to complete..."

if [[ "$CHANGE_SET_TYPE" == "CREATE" ]]; then
  aws cloudformation wait stack-create-complete \
    --stack-name "$STACK_NAME" \
    --region "$AWS_REGION"
else
  aws cloudformation wait stack-update-complete \
    --stack-name "$STACK_NAME" \
    --region "$AWS_REGION"
fi

# ──────────────────────────────────────────────────────────────────────────────
# OUTPUTS
# ──────────────────────────────────────────────────────────────────────────────
log_section "📤 Stack Outputs"
aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION" \
  --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue,Description]' \
  --output table

log_success "✅ Deployment of '$STACK_NAME' completed successfully!"
