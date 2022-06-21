#!/bin/bash
_fail() {
  echo "Powershell Core not found (pwsh)"
  echo "brew install --cask powershell"
  exit 1
}

MODE="$1"

command -v pwsh >/dev/null || _fail

# Optionally use the dev build input
# "BasePath": "https://raw.githubusercontent.com/tanium/AzureSentinelGTO/tanium-wip/Solutions/Tanium",
# "BasePath": "http://localhost:8000",

PROD_URL="https://raw.githubusercontent.com/tanium/AzureSentinelGTO/tanium-wip/Solutions/Tanium"
DEV_URL="http://localhost:8000"
INPUT_FILE="./Tools/Create-Azure-Sentinel-Solution/input/Solution_Tanium.json"

URL="$DEV_URL"
[[ "$MODE" == "prod" ]] && URL="$PROD_URL"
cat ./tanium_scripts/input.json | jq '.BasePath = "'"$URL"'"' > "$INPUT_FILE"
