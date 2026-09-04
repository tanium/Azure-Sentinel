#!/usr/bin/env bash
# If you change a content item, its version has to change in the same pull request.
#
# This is not bookkeeping. Sentinel builds a content item's identity from its version,
# so changed content shipped under an unchanged version looks identical to what a
# customer already has and may never be offered to them.
#
# Only a change to the item itself counts. Editing a playbook's README does not
# require a version bump, so this looks at the templates and the rule files only.
#
# Usage: check-version-bumps.sh <base-ref> <head-ref>
set -euo pipefail

base_ref=${1:?base ref required}
head_ref=${2:?head ref required}

workbook_metadata="Workbooks/WorkbooksMetadata.json"
failed=0

changed=$(git diff --name-only "${base_ref}...${head_ref}")

# Reads a file as it exists at a ref. Empty when the file is not there yet.
blob_at() {
	git show "${1}:${2}" 2>/dev/null || true
}

fail() {
	failed=1
	echo "::error::$1"
	echo "  BLOCKED: $1"
}

# --------------------------------------------------------------------- workbooks
if grep -qE '^Solutions/Tanium/Workbooks/.*\.json$' <<<"$changed"; then
	tanium_versions='[.[] | select(.provider == "Tanium") | {key: .workbookKey, version: .version}]'
	before=$(blob_at "$base_ref" "$workbook_metadata" | jq -S "$tanium_versions")
	after=$(blob_at "$head_ref" "$workbook_metadata" | jq -S "$tanium_versions")

	if [[ "$before" == "$after" ]]; then
		fail "A workbook changed but no Tanium version in ${workbook_metadata} did"
		echo "  Bump the matching entry's \"version\"."
	fi
fi

# --------------------------------------------------------------------- playbooks
playbook_version='[.resources[] | select(.type == "Microsoft.Logic/workflows") | .tags["hidden-SentinelTemplateVersion"]]'

while IFS= read -r template; do
	[[ -z "$template" ]] && continue

	before_version=$(blob_at "$base_ref" "$template" | jq -c "$playbook_version" 2>/dev/null || true)
	after_version=$(blob_at "$head_ref" "$template" | jq -c "$playbook_version" 2>/dev/null || true)
	before_date=$(blob_at "$base_ref" "$template" | jq -r '.metadata.lastUpdateTime // ""' 2>/dev/null || true)
	after_date=$(blob_at "$head_ref" "$template" | jq -r '.metadata.lastUpdateTime // ""' 2>/dev/null || true)

	if [[ -z "$before_version" ]]; then
		# New playbook. Nothing to compare against, but both fields must be present.
		[[ "$after_version" == "[]" || "$after_version" == '[null]' ]] &&
			fail "${template} has no hidden-SentinelTemplateVersion tag"
		[[ -z "$after_date" ]] && fail "${template} has no metadata.lastUpdateTime"
		continue
	fi

	if [[ "$before_version" == "$after_version" ]]; then
		fail "${template} changed but hidden-SentinelTemplateVersion did not"
	fi

	if [[ "$before_date" == "$after_date" ]]; then
		fail "${template} changed but metadata.lastUpdateTime did not"
	fi
done < <(grep -E '^Solutions/Tanium/Playbooks/.*/azuredeploy\.json$' <<<"$changed" || true)

# ---------------------------------------------------------------- analytic rules
while IFS= read -r rule; do
	[[ -z "$rule" ]] && continue

	before_version=$(blob_at "$base_ref" "$rule" | grep -E '^version:' || true)
	after_version=$(blob_at "$head_ref" "$rule" | grep -E '^version:' || true)

	if [[ -z "$after_version" ]]; then
		fail "${rule} has no top-level version field"
		continue
	fi

	if [[ -n "$before_version" && "$before_version" == "$after_version" ]]; then
		fail "${rule} changed but its version did not"
	fi
done < <(grep -E '^Solutions/Tanium/Analytic Rules/.*\.yaml$' <<<"$changed" || true)

if [[ $failed -ne 0 ]]; then
	echo
	echo "A changed item under an unchanged version can never reach customers who already have it."
	exit 1
fi

echo "Version bumps: every changed content item carries a new version."
