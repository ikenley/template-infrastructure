#!/usr/bin/env bash
#
# Enable a Bedrock foundation model on this account by accepting its
# usage agreement, then poll until the model becomes AVAILABLE.
#
# Usage:
#   ./enable-bedrock-model.sh <model-id> [-r region] [-p profile]
#
# Examples:
#   ./enable-bedrock-model.sh anthropic.claude-fable-5
#   ./enable-bedrock-model.sh anthropic.claude-fable-5 -r us-west-2 -p terraform-dev

set -euo pipefail

REGION="us-east-1"
PROFILE="terraform-dev"

usage() {
  echo "Usage: $0 <model-id> [-r region] [-p profile]" >&2
  exit 2
}

[ $# -ge 1 ] || usage
MODEL_ID="$1"
shift

while getopts ":r:p:" opt; do
  case "$opt" in
    r) REGION="$OPTARG" ;;
    p) PROFILE="$OPTARG" ;;
    *) usage ;;
  esac
done

AWS=(aws bedrock --region "$REGION" --profile "$PROFILE")

status() {
  "${AWS[@]}" get-foundation-model-availability \
    --model-id "$MODEL_ID" \
    --query 'agreementAvailability.status' --output text
}

echo "==> Model:   $MODEL_ID"
echo "==> Region:  $REGION"
echo "==> Profile: $PROFILE"
echo

# Step 1: check current availability
current="$(status)"
echo "==> Current agreement status: $current"

if [ "$current" = "AVAILABLE" ]; then
  echo "==> Already AVAILABLE. Nothing to do."
  exit 0
fi

# Step 2: fetch the offer token
echo "==> Fetching offer token..."
OFFER_TOKEN="$("${AWS[@]}" list-foundation-model-agreement-offers \
  --model-id "$MODEL_ID" \
  --query 'offers[0].offerToken' --output text)"

if [ -z "$OFFER_TOKEN" ] || [ "$OFFER_TOKEN" = "None" ]; then
  echo "!! No offer token returned for $MODEL_ID. Check the model id / region." >&2
  exit 1
fi

# Step 3: accept the agreement
echo "==> Accepting agreement..."
"${AWS[@]}" create-foundation-model-agreement \
  --model-id "$MODEL_ID" \
  --offer-token "$OFFER_TOKEN" >/dev/null
echo "==> Agreement submitted."

# Step 4: poll until AVAILABLE (usually a few minutes)
echo "==> Waiting for status to become AVAILABLE..."
for i in $(seq 1 30); do
  current="$(status)"
  echo "    [$i] status=$current"
  if [ "$current" = "AVAILABLE" ]; then
    echo "==> Done. $MODEL_ID is now AVAILABLE in $REGION."
    exit 0
  fi
  sleep 20
done

echo "!! Still not AVAILABLE after polling. Current status: $current" >&2
echo "   It may just need more time; re-run the availability check later." >&2
exit 1
