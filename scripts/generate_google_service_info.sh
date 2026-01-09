#!/bin/sh
set -e # Exit immediately on error

echo "INFO: Starting Firebase configuration script."

# 1. Validate environment variable
if [ -z "$GOOGLE_SERVICE_INFO_BASE64" ]; then
  echo "FATAL: GOOGLE_SERVICE_INFO_BASE64 environment variable is not set or is empty."
  exit 1
fi

echo "INFO: GOOGLE_SERVICE_INFO_BASE64 variable found."

# 2. Decode the variable
# Using `echo` with quotes is crucial to prevent the shell from interpreting the content
# of the variable. Piping this to `base64 -d` is the most standard and robust method.
echo "INFO: Decoding Base64 content and writing to file..."
echo "$GOOGLE_SERVICE_INFO_BASE64" | base64 -d > "ios/Runner/GoogleService-Info.plist"

# 3. Verify the result
echo "INFO: Verifying the generated file..."

# Check that the file was actually created and has content
if [ ! -s "ios/Runner/GoogleService-Info.plist" ]; then
    echo "FATAL: File was not created or is empty. Base64 decoding likely failed."
    exit 1
fi

# Check if the decoded content is a valid plist XML
if ! grep -q "<plist" "ios/Runner/GoogleService-Info.plist"; then
    echo "FATAL: Decoded file is not a valid plist XML."
    echo "This confirms the GOOGLE_SERVICE_INFO_BASE64 variable in your CI is incorrect or corrupted."
    echo "Please re-generate it from your original file and update the secret variable."
    echo "--- Start of corrupted file content (first 5 lines) ---"
    head -n 5 "ios/Runner/GoogleService-Info.plist"
    echo "--- End of corrupted file content ---"
    exit 1
fi

echo "INFO: Successfully generated and verified GoogleService-Info.plist."
