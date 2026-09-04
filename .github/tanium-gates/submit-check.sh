#!/usr/bin/env bash
# The last thing that runs before anything reaches Microsoft.
#
# Two rules:
#   1. The candidate must not change any file that tanium-base adds on top of master.
#      That list is computed, never maintained by hand, so it stays correct as the
#      internal file set grows.
#   2. The candidate must not change anything under .github/ or .claude/. Rule 1 cannot
#      catch a NEW file under those folders, because a new file is not on tanium-base,
#      and a new file added there survives the submission rebase silently.
#
# Every diff here uses three dots, which compares against the point where the branches
# diverged. That is what GitHub shows under "Files changed". Two dots would compare
# against the tip of upstream/master and would list every file Microsoft changed while
# our pull request sat in review, which on the second submission round is thousands.
#
# Usage: submit-check.sh <upstream-ref> <internal-ref> <candidate-ref>
#   e.g. submit-check.sh upstream/master tanium-base submit/3.4.0
set -euo pipefail

upstream_ref=${1:?upstream ref required}
internal_ref=${2:?internal ref required}
candidate_ref=${3:?candidate ref required}

blocked_prefixes=(".github/" ".claude/")
failed=0

# What Microsoft would see under "Files changed".
candidate_files=$(git diff --name-only "${upstream_ref}...${candidate_ref}")

# What tanium-base adds on top of Microsoft's master. Computed, not a maintained list.
internal_files=$(git diff --name-only "${upstream_ref}...${internal_ref}")

echo "Submission would show $(grep -c . <<<"$candidate_files" || true) changed file(s) to Microsoft."
echo

# ------------------------------------------------------------------------ rule 1
while IFS= read -r path; do
	[[ -z "$path" ]] && continue
	if grep -Fxq "$path" <<<"$candidate_files"; then
		failed=1
		echo "::error file=${path}::Internal file present in the submission"
		echo "  BLOCKED: ${path} is an internal file and must not reach Microsoft"
	fi
done <<<"$internal_files"

# ------------------------------------------------------------------------ rule 2
while IFS= read -r path; do
	[[ -z "$path" ]] && continue
	for prefix in "${blocked_prefixes[@]}"; do
		if [[ "$path" == "$prefix"* ]]; then
			failed=1
			echo "::error file=${path}::Change under ${prefix} in the submission"
			echo "  BLOCKED: ${path}"
		fi
	done
done <<<"$candidate_files"

# ------------------------------------------------------------------------- warning
while IFS= read -r path; do
	[[ -z "$path" ]] && continue
	case "$path" in
	.github/* | .claude/*) continue ;;
	esac
	if grep -qE '(^|/)\.[^/]+/' <<<"$path"; then
		echo "::warning file=${path}::Dot-folder in the submission. Confirm it belongs upstream."
		echo "  WARNING: ${path}"
	fi
done <<<"$candidate_files"

if [[ $failed -ne 0 ]]; then
	echo
	echo "Nothing has been pushed. Fix the branch and run the submit workflow again."
	exit 1
fi

echo
echo "Submit check passed. Nothing internal is in the diff Microsoft would review."
