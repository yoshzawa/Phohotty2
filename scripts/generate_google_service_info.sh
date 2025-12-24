#!/bin/sh
set -e # Exit immediately if a command exits with a non-zero status.

# Check if the environment variable is set and not empty
if [ -z "$GOOGLE_SERVICE_INFO_BASE64" ]; then
  echo "Error: GOOGLE_SERVICE_INFO_BASE64 environment variable is not set or is empty."
  echo "Please check your Codemagic workflow configuration."
  exit 1
fi

echo "INFO: Decoding base64 string using a here string to avoid pipes..."
# Use a 'here string' (<<<) to redirect the variable into the command's stdin.
# This avoids using a pipe (|), which seems to be blocked for secret variables in the Codemagic environment.
base64 -d > ios/Runner/GoogleService-Info.plist <<< "$GOOGLE_SERVICE_INFO_BASE64"

# Verify that the file was created and is not empty
if [ ! -s "ios/Runner/GoogleService-Info.plist" ]; then
    echo "Error: Failed to create or write to GoogleService-Info.plist. The decoded content might be invalid."
    exit 1
fi

echo "INFO: Successfully generated GoogleService-Info.plist"
