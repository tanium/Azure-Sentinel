#!/bin/bash
first=1

_add_api_connection() {
  cat /tmp/tmp.new | jq '.resources += [{
      "type": "Microsoft.Web/connections",
      "apiVersion": "2016-06-01",
      "name": "taniumapiconnection",
      "location": "[parameters('"'"'workspace-location'"'"')]",
      "properties": {
        "displayName": "[parameters('"'"'UserName'"'"')]",
        "customParameterValues": {},
        "api": {
          "id": "[concat('"'"'/subscriptions/'"'"', subscription().subscriptionId, '"'"'/providers/Microsoft.Web/locations/'"'"', parameters('"'"'workspace-location'"'"'), '"'"'/managedApis/microsoftgraphsecurity'"'"')]"
        }
      }
    }]' > "$var"
}

for var in `find ./Solutions/Tanium/Playbooks -type f -name azuredeploy.json`
do
  NAME=`echo "$var" | sed 's|./Solutions/Tanium/Playbooks/Tanium-||' | cut -d/ -f1`
  NAME=`echo "${NAME}Tanium"`
  # cat $var | jq >/tmp/tmp.orig

  cat "$var" |
    jq '.parameters = {}' |
    jq '.parameters .PlaybookName = { "defaultValue": "'"$NAME"'", "type": "string" }' |
    jq '.parameters .TaniumServerHost = { "defaultValue": "__Change_Me_Host__", "type": "string" }' |
    jq '.parameters .ForwarderAPIToken = { "defaultValue": "__Change_Me_APIToken__", "type": "string" }' |
    jq '.parameters .ConnectionName = { "defaultValue": "taniumsentinel", "type": "string" }' |
    jq 'del(.resources[0] .tags)' |
    jq 'del(.variables .AzureSentinelConnectionName)' |
    jq 'del(.variables .ConnectionName)' |
    jq '.resources[0] .dependsOn = [ "[resourceId('"'"'Microsoft.Web/connections'"'"', parameters('"'"'ConnectionName'"'"'))]" ]' |
    jq '.resources[0] .properties .definition .actions? .HTTP .inputs .headers .Authorization = "[parameters('"'"'ForwarderAPIToken'"'"')]"' |
    jq '.resources[0] .name = "[parameters('"'"'PlaybookName'"'"')]"' |
    jq '.resources[0] .location = "[parameters('"'"'workspace-location'"'"')]"' |
    sed 's/parameters('"'"'workspace-location'"'"')/resourceGroup\(\).location/' >/tmp/tmp.new
    # sed 's/resourceGroup\(\).location/parameters\('"'"'workspace-location'"'"'\)/' >/tmp/tmp.new

  cp /tmp/tmp.new "$var"

  # if [[ "$first" == "1" ]]; then
  #   _add_api_connection "$var"
  #   first=0
  # else
  #   cp /tmp/tmp.new "$var"
  # fi
done
