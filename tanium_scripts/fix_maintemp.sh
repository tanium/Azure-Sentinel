#!/bin/bash
set -e

# /subscriptions/8cacf840-893d-4966-8f82-768f12f19076/resourceGroups/RG_1/providers/Microsoft.Resources/deployments/Microsoft.Template-20220609155607/operations/4548232D700A36FC

GEN_FILE="Solutions/Tanium/Package/mainTemplate.json"
ORIG_FILE="Solutions/Tanium/Package/mainTemplate.original.json"
NEW_FILE="Solutions/Tanium/Package/mainTempate.custom.json"
ZIP_FILE="Solutions/Tanium/Package/2.0.0.zip"

cat "$GEN_FILE" | jq > "$ORIG_FILE"
# cat "$GEN_FILE" |
#   jq '.resources += [
# '"`cat ./Solutions/Tanium/Data/AzureSentinelConnector.json`"',
# '"`cat ./Solutions/Tanium/Data/TaniumSentinelConnector.json`"'
#   ]' > "$NEW_FILE"

diff -u  "$ORIG_FILE" "$NEW_FILE" || true
cp "$NEW_FILE" "$GEN_FILE"
cp "$NEW_FILE" ./mainTemplate.json
cp "$ZIP_FILE" ./.tmp.zip
zip .tmp.zip mainTemplate.json
cp  .tmp.zip "$ZIP_FILE"
rm ./mainTemplate.json .tmp.zip
rm "$NEW_FILE" "$ORIG_FILE"
