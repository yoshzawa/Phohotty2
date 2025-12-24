#!/bin/sh
set -e # Exit immediately if a command exits with a non-zero status.

# Check if the environment variable is set and not empty
if [ -z "$GOOGLE_SERVICE_INFO_BASE64" ]; then
  echo "Error: GOOGLE_SERVICE_INFO_BASE64 environment variable is not set or is empty."
  echo "Please check your Codemagic workflow configuration."
  exit 1
fi

echo "INFO: Decoding base64 variable using a 'here document' for maximum compatibility..."
# Use a "here document" to pass the variable to the command's standard input.
# This is the most POSIX-compliant and robust method, avoiding both pipes (|)
# and here-strings (<<<) which may not be supported in the CI shell.
base64 -d > ios/Runner/GoogleService-Info.plist <<EOF
$GOOGLE_SERVICE_INFO_BASE64
EOF

# Verify that the file was created and is not empty
if [ ! -s "ios/Runner/GoogleService-Info.plist" ]; then
    echo "Error: Failed to create or write to GoogleService-Info.plist. The decoded content might be invalid."
    exit 1
fi

# Final verification that the content is XML
if ! grep -q "<plist" "ios/Runner/GoogleService-Info.plist"; then
    echo "FATAL ERROR: Decoded file does not appear to be a valid plist XML. The Base64 variable may be corrupted."
    exit 1
fi

echo "INFO: Successfully generated GoogleService-Info.plist"
