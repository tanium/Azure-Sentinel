#!/bin/bash
set -e

_fail() {
  echo "Passing in the rule-id and a name is required!"
  echo "ex: ./script dd9aa0ff-7ac1-4448-879c-e1a18d5890b4 \"Tanium Threat Response Alerts\""
  exit 1
}

_fail_yaml() {
  echo "Must have python yaml module installed"
  echo "pip3 install pyyaml # careful on macs... you may need to use pip3.N where N matches your python version"
  exit 1
}

python3 -c 'import yaml' || _fail_yaml

[[ "$1" == "" ]] && _fail
RULE_ID="$1"

[[ "$2" == "" ]] && _fail
NAME="$2"

az sentinel \
  alert-rule \
  show \
  --resource-group "RG_1" \
  --workspace-name "Log-Sentinel-Test" \
  --rule-id "$RULE_ID" \
  -o json |
  jq '.name = "'"$NAME"'" | .id = "'"$RULE_ID"'"' | # fix the ID and Name
  python3 -c 'import sys, yaml, json; j=json.loads(sys.stdin.read()); print(yaml.safe_dump(j))' # emit as yaml instead of json
