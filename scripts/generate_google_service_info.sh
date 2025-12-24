#!/bin/sh

# This script generates the GoogleService-Info.plist file from an environment variable.
# The environment variable GOOGLE_SERVICE_INFO_BASE64 should contain the base64 encoded
# content of the GoogleService-Info.plist file.

if [ -z "$GOOGLE_SERVICE_INFO_BASE64" ]; then
  echo "Error: GOOGLE_SERVICE_INFO_BASE64 environment variable not set."
  exit 1
fi

echo $GOOGLE_SERVICE_INFO_BASE64 | base64 --decode > ios/Runner/GoogleService-Info.plist
