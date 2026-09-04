#!/usr/bin/env bash
# Tanium never changes anything under .github/, and .claude/ must never be committed
# at all. Neither is ignored by git here, so nothing stops `git add -A` staging them.
#
# Any other folder starting with a dot warns rather than blocks. Tanium does own real
# files under .script/, so blocking every dot-folder would stop legitimate work. A
# warning names the path and lets a human decide in two seconds, and it catches the
# next tool that drops a folder nobody predicted.
#
# Usage: check-paths.sh <base-ref> <head-ref>
set -euo pipefail

base_ref=${1:?base ref required}
head_ref=${2:?head ref required}

blocked_prefixes=(".github/" ".claude/")
failed=0

changed=$(git diff --name-only "${base_ref}...${head_ref}")

while IFS= read -r path; do
	[[ -z "$path" ]] && continue

	hard_blocked=0
	for prefix in "${blocked_prefixes[@]}"; do
		if [[ "$path" == "$prefix"* ]]; then
			failed=1
			hard_blocked=1
			echo "::error file=${path}::Tanium does not change ${prefix} in this repository"
			echo "  BLOCKED: ${path}"
		fi
	done
	[[ $hard_blocked -eq 1 ]] && continue

	# Any remaining path with a folder segment that starts with a dot.
	if grep -qE '(^|/)\.[^/]+/' <<<"$path"; then
		echo "::warning file=${path}::Change inside a dot-folder. Confirm this belongs upstream."
		echo "  WARNING: ${path}"
	fi
done <<<"$changed"

if [[ $failed -ne 0 ]]; then
	echo
	echo "These paths reach Microsoft's repository. Move the change to tanium-base, or drop it."
	exit 1
fi

echo "Paths: nothing changed under .github/ or .claude/."
