#!/bin/sh

echo $GOOGLE_SERVICE_INFO_BASE64 | base64 -d > ios/Runner/GoogleService-Info.plist
