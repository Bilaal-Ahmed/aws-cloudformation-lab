#!/usr/bin/env bash
# ==============================================================================
# validate.sh — CloudFormation Template Validation Script
#
# Description: Validates all CloudFormation templates in the templates/
#              directory using AWS CLI and cfn-lint (if installed).
#              Exits with code 0 on success, 1 on any failure.
#
# Usage:
#   bash scripts/validate.sh               # Validate all templates
#   bash scripts/validate.sh templates/s3-bucket.yml  # Validate single file
#
# Author: aws-cloudformation-lab
# ==============================================================================

set -euo pipefail

# ANSI Color Codes
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC}    $1"; }
log_success() { echo -e "${GREEN}[PASS]${NC}    $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}    $1"; }
log_error()   { echo -e "${RED}[FAIL]${NC}    $1"; }

AWS_REGION="${AWS_DEFAULT_REGION:-us-east-1}"
PASS_COUNT=0
FAIL_COUNT=0
TEMPLATES=()

echo -e "\n${CYAN}══════════════════════════════════════════${NC}"
echo -e "${CYAN}  🔍 CloudFormation Template Validator${NC}"
echo -e "${CYAN}══════════════════════════════════════════${NC}\n"

# Build list of templates to validate
if [[ $# -gt 0 ]]; then
  TEMPLATES=("$@")
else
  while IFS= read -r -d '' file; do
    TEMPLATES+=("$file")
  done < <(find templates/ -name "*.yml" -o -name "*.yaml" -o -name "*.json" -print0 2>/dev/null)
fi

if [[ ${#TEMPLATES[@]} -eq 0 ]]; then
  log_warn "No CloudFormation templates found in templates/ directory."
  exit 0
fi

log_info "Found ${#TEMPLATES[@]} template(s) to validate.\n"

for TEMPLATE in "${TEMPLATES[@]}"; do
  echo -e "─── Validating: ${CYAN}$TEMPLATE${NC}"

  # AWS CLI validation (checks template syntax and resource types)
  if aws cloudformation validate-template \
    --template-body "file://$TEMPLATE" \
    --region "$AWS_REGION" \
    --output text &>/dev/null; then
    log_success "AWS CLI validation passed"
    ((PASS_COUNT++))
  else
    log_error "AWS CLI validation FAILED for: $TEMPLATE"
    aws cloudformation validate-template \
      --template-body "file://$TEMPLATE" \
      --region "$AWS_REGION" 2>&1 || true
    ((FAIL_COUNT++))
  fi

  # cfn-lint validation (deeper linting, catches anti-patterns)
  if command -v cfn-lint &>/dev/null; then
    if cfn-lint "$TEMPLATE" 2>&1; then
      log_success "cfn-lint passed"
    else
      log_warn "cfn-lint reported issues — review output above"
    fi
  else
    log_warn "cfn-lint not installed (optional): pip install cfn-lint"
  fi

  echo ""
done

# ── Summary ──────────────────────────────────────────────────────────────────
echo -e "${CYAN}══════════════════════════════════════════${NC}"
echo -e "  Results: ${GREEN}${PASS_COUNT} passed${NC} | ${RED}${FAIL_COUNT} failed${NC}"
echo -e "${CYAN}══════════════════════════════════════════${NC}\n"

if [[ $FAIL_COUNT -gt 0 ]]; then
  log_error "Validation completed with $FAIL_COUNT failure(s)."
  exit 1
fi

log_success "All templates validated successfully! ✅"
exit 0
