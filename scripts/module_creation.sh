#!/bin/bash

# Complete script for module creation API script.

# 1. Define Variables

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <path_to_content_directory> <organization>/<workspace>"
  exit 0
fi

CONTENT_DIRECTORY="$1"
ORG_NAME="$2"
TOKEN="$3"

# 2. Create registry module payload
echo '{
  "data": {
    "type": "registry-modules",
    "attributes": {
      "name": "my-sample-module-name",
      "provider": "http",
      "registry-name": "private"
    }
  }
}
' > ./create_module_payload.json

# 4. Module creation API call, will return the name of the created module. 
MY_MODULE=($(curl \
  --header "Authorization: Bearer $TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  --request POST \
  --data @create_module_payload.json \
  https://app.terraform.io/api/v2/organizations/$ORG_NAME/registry-modules \
  | jq -r '.data.attributes."name"'
))

# 5. Module version payload. Needed to tag created module. 
echo '{
  "data": {
    "type": "registry-module-versions",
    "attributes": {
      "version": "0.1.0"
    }
  }
}
' > ./create_module_version_payload.json

# 6. API call to create module version, will return the URL needed to upload module tarball. 
UPLOAD_URL=($(curl \
  --header "Authorization: Bearer $TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  --request POST \
  --data @create_module_version_payload.json \
  https://app.terraform.io/api/v2/organizations/$ORG_NAME/registry-modules/private/$ORG_NAME/$MY_MODULE/http/versions \
  | jq -r '.data.links."upload"'
))

# 7. Creates file for upload
UPLOAD_FILE_NAME="./content-$(date +%s).tar.gz"
tar -zcvf "$UPLOAD_FILE_NAME" -C "$CONTENT_DIRECTORY" .

# 8. Uploads module to registry. 
curl \
  --header "Content-Type: application/octet-stream" \
  --request PUT \
  --data-binary @"$UPLOAD_FILE_NAME" \
  $UPLOAD_URL

# 9. Delete Temporary Files

rm ./create_module_payload.json
rm ./create_module_version_payload.json
rm "$UPLOAD_FILE_NAME"
