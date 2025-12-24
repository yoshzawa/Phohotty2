#!/bin/sh
set -e # Exit immediately if a command exits with a non-zero status.

# Check if the environment variable is set and not empty
if [ -z "$GOOGLE_SERVICE_INFO_BASE64" ]; then
  echo "Error: GOOGLE_SERVICE_INFO_BASE64 environment variable is not set or is empty."
  echo "Please check your Codemagic workflow configuration."
  exit 1
fi

echo "INFO: Decoding base64 string and writing to file..."
echo "$GOOGLE_SERVICE_INFO_BASE64" | base64 -d > ios/Runner/GoogleService-Info.plist

# Verify that the file was created and is not empty
if [ ! -s "ios/Runner/GoogleService-OInfo.plist" ]; then
    echo "Error: Failed to create or write to GoogleService-Info.plist. The decoded content might be invalid."
    exit 1
fi

echo "INFO: Successfully generated GoogleService-Info.plist"
