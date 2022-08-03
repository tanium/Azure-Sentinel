#!/bin/bash
set -e

GEN_FILE="Solutions/Tanium/Package/createUiDefinition.json"
ORIG_FILE="Solutions/Tanium/Package/createUiDefinition.original.json"
NEW_FILE="Solutions/Tanium/Package/createUiDefinition.custom.json"
ZIP_FILE="Solutions/Tanium/Package/1.0.8.zip"

cat "$GEN_FILE" | jq > "$ORIG_FILE"
cat "$GEN_FILE" |
  jq '.parameters .basics += [{
        "name": "taniumforwarderhostname",
        "type": "Microsoft.Common.TextBox",
        "label": "Tanium Forwarder Hostname",
        "placeholder": "host.example.com",
        "toolTip": "URL of the Tanium Forwarder. Please omit any \"https://\".",
        "constraints": {
          "regex": "[a-z0-9A-Z]{1,256}$",
          "validationMessage": "Please enter a Tanium Forwarder URL",
          "required": true
        },
        "visible": true
      },
      {
        "name": "taniumforwarderapikey",
        "type": "Microsoft.Common.TextBox",
        "label": "Tanium Forwarder API Key",
        "placeholder": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
        "toolTip": "API Key of the Tanium Forwarder. Can be any combination of any letters and numbers. No special characters and between 1-256 characters.",
        "constraints": {
          "regex": "[a-z0-9A-Z]{1,256}$",
          "validationMessage": "Please enter a Tanium Forwarder API Token",
          "required": true
        },
        "visible": true
      }] ' |
  sed -r \
    -e 's/A P I/API/g' \
    -e 's/__Change_Me_Host__/[basics('\'"taniumforwarderhostname"\'').value]/' \
    -e 's/__Change_Me_APIToken__/[basics('\'"taniumforwarderapikey"\'').value]/' > "$NEW_FILE"

diff -u  "$ORIG_FILE" "$NEW_FILE" || true
cp "$NEW_FILE" "$GEN_FILE"
cp "$NEW_FILE" ./createUiDefinition.json
cp "$ZIP_FILE" ./.tmp.zip
zip .tmp.zip createUiDefinition.json
cp  .tmp.zip "$ZIP_FILE"
rm ./createUiDefinition.json .tmp.zip
rm "$NEW_FILE" "$ORIG_FILE"
