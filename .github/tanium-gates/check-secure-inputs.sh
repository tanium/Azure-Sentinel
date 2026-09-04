#!/usr/bin/env bash
# Every HTTP action in a Tanium playbook must have secure inputs turned on, so the
# Tanium API token never appears in the Logic App run history where anyone with
# read access to the resource group could read it.
#
# Run from the repository root.
set -euo pipefail

playbooks_dir="Solutions/Tanium/Playbooks"

if [[ ! -d "$playbooks_dir" ]]; then
	echo "Could not find ${playbooks_dir}. Run this from the repository root."
	exit 1
fi

failed=0
checked=0

while IFS= read -r template; do
	checked=$((checked + 1))

	offenders=$(jq -r '
		paths as $path
		| getpath($path) as $action
		| select(($action | type) == "object" and ($action.type? == "Http"))
		| select(((($action.runtimeConfiguration.secureData.properties?) // []) | index("inputs")) == null)
		| $path | map(tostring) | join(" > ")
	' "$template")

	if [[ -n "$offenders" ]]; then
		failed=1
		echo "::error file=${template}::HTTP action without secure inputs"
		echo "  ${template}"
		while IFS= read -r location; do
			[[ -n "$location" ]] && echo "    - ${location}"
		done <<<"$offenders"
	fi
done < <(find "$playbooks_dir" -name azuredeploy.json | sort)

if [[ $failed -ne 0 ]]; then
	echo
	echo "Each action listed above needs this alongside its inputs:"
	echo '    "runtimeConfiguration": { "secureData": { "properties": [ "inputs" ] } }'
	echo
	echo "Without it, the Tanium API token is readable in the Logic App run history."
	exit 1
fi

echo "Secure inputs: ${checked} playbook template(s) checked, every HTTP action covered."
