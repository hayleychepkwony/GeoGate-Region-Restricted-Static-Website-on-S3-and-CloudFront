#!/usr/bin/env bash
# Deploy the website to the bucket created by the CloudFormation stack, then clear the CDN cache.
# Usage: ./scripts/deploy.sh [stack-name]      (default stack name: capstone3-static-site)
set -euo pipefail

STACK="${1:-capstone3-static-site}"
cd "$(dirname "$0")/.."

out() { aws cloudformation describe-stacks --stack-name "$STACK" \
          --query "Stacks[0].Outputs[?OutputKey=='$1'].OutputValue" --output text; }

BUCKET=$(out BucketName)
DIST=$(out DistributionId)

echo "Uploading website/ to s3://$BUCKET ..."
aws s3 sync website/ "s3://$BUCKET" --delete

echo "Invalidating CloudFront cache ..."
aws cloudfront create-invalidation --distribution-id "$DIST" --paths "/*" --query "Invalidation.Status" --output text

echo "Done: $(out SiteUrl)"
