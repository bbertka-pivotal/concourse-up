#!/bin/bash

set -eu

deployment="system-test-$RANDOM"

mv "$BINARY_PATH" ./cup
chmod +x ./cup

echo "DEPLOY WITH AUTOGENERATED CERT, NO DOMAIN, CUSTOM REGION, DEFAULT WORKERS"

./cup deploy $deployment --region us-east-1

config=$(./cup info --json $deployment)
domain=$(echo "$config" | jq -r '.config.domain')
username=$(echo "$config" | jq -r '.config.concourse_username')
password=$(echo "$config" | jq -r '.config.concourse_password')
echo "$config" | jq -r '.config.concourse_ca_cert' > generated-ca-cert.pem

sleep 60

fly --target system-test login \
  --ca-cert generated-ca-cert.pem \
  --concourse-url "https://$domain" \
  --username "$username" \
  --password "$password"

set -x
fly --target system-test sync
fly --target system-test workers --details
set +x

echo "DESTROY CUSTOM-REGION DEPLOYMENT"

./cup --non-interactive destroy $deployment
