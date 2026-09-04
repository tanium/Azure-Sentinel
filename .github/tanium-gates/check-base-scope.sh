#!/usr/bin/env bash
# tanium-base is master plus a small set of internal files. Nothing else belongs on it.
#
# The submission rebase drops every commit reachable from tanium-base, so a solution
# change committed here would be silently excluded from the pull request to Microsoft
# and would never reach a customer. Blocking it is the only way that mistake is visible.
#
# Usage: check-base-scope.sh <base-ref> <head-ref>
set -euo pipefail

base_ref=${1:?base ref required}
head_ref=${2:?head ref required}

allowed_prefixes=(
	"CLAUDE.md"
	".github/tanium-gates/"
	".github/workflows/tanium-"
)

failed=0

while IFS= read -r path; do
	[[ -z "$path" ]] && continue

	allowed=0
	for prefix in "${allowed_prefixes[@]}"; do
		[[ "$path" == "$prefix"* ]] && allowed=1
	done

	if [[ $allowed -eq 0 ]]; then
		failed=1
		echo "::error file=${path}::Not an internal file, so it does not belong on tanium-base"
		echo "  BLOCKED: ${path}"
	fi
done < <(git diff --name-only "${base_ref}...${head_ref}")

if [[ $failed -ne 0 ]]; then
	echo
	echo "tanium-base may only carry:"
	for prefix in "${allowed_prefixes[@]}"; do
		echo "  - ${prefix}"
	done
	echo
	echo "Anything meant for customers goes on a release branch, not here."
	exit 1
fi

echo "tanium-base scope: only internal files changed."
