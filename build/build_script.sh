# If MI_DEV_HOST isn't set in travis, a default value is used
export HOST=${VSM_DEV_HOST:-demo-us.leanix.net}

# Check if token env variable is set in travis
if [[ -z "${VSM_DEV_TOKEN}" ]]; then
    echo "Please add your workspace token as an env variable 'MI_DEV_TOKEN' in travis."
    exit 1
fi

# Fetch bearer token
export SYNC_URL="https://${HOST}/services/integration-api/v1/synchronizationRuns"
TOKEN=$(curl -X POST --url https://${HOST}/services/mtm/v1/oauth2/token -u apitoken:${VSM_DEV_TOKEN} --data grant_type=client_credentials | jq -r '.access_token') 

# Run license-checker
license-checker --json > $TRAVIS_BUILD_DIR/build/dependencies.json

# API call to send the manifest file, dependencies and metadata to workspace
# Required input data in the API call:
# Bearer token (provided as a part of header)
# Absolute path for dependencies.json
# Absolute path for lx-manifest.yaml
# version, stage & dependencyManager (hardcoded for this sample code)
curl -X POST \
  -H 'Cache-Control: no-cache' \
  -H "Authorization: Bearer ${TOKEN}" \
  -H 'Content-Type: multipart/form-data' \
  -F dependencies=@"$TRAVIS_BUILD_DIR/build/dependencies.json" \
  -F manifest=@"$TRAVIS_BUILD_DIR/lx-manifest.yaml" \
  -F 'data={
  "version": "1.1.0",
  "stage": "dev",
  "dependencyManager": "NPM"
}' \
  https://$HOST/services/cicd-connector/v2/deployment