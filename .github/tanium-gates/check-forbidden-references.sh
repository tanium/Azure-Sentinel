#!/usr/bin/env bash
# This repository is public. Two kinds of internal reference must never land in it:
# links or keys belonging to Tanium's issue tracker, and any note that an AI
# assistant was involved.
#
# Usage: check-forbidden-references.sh <base-ref> <head-ref>
#
# Severity is split deliberately. A tracker hostname has essentially no innocent
# reading, so it blocks. A bare uppercase key looks identical to CVE-2021-44228 or
# UTF-8, so it blocks in commit messages (where prose is short and a human wrote it
# on purpose) and only warns in file contents (where false positives are common and
# a red pull request for "UTF-8" would train people to ignore the gate).
set -euo pipefail

base_ref=${1:?base ref required}
head_ref=${2:?head ref required}

# Files this branch owns. They describe the rules, so they necessarily contain the
# words the rules are about.
skip_paths=(
	"CLAUDE.md"
	".github/tanium-gates/"
	".github/workflows/tanium-"
)

# Prefixes that look like a tracker key but are public standards.
innocent_prefixes="CVE|RFC|ISO|IEC|UTF|ASCII|SHA|AES|RSA|TLS|SSL|NIST|FIPS|PCI|SOC|GDPR|MITRE|OWASP|JSON|HTML|HTTP|API|URL|UUID|CSV|XML|YAML|SQL|KQL|ARM|UTC|GMT"

tracker_host_pattern='jira\.[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
tracker_key_pattern='\b[A-Z][A-Z0-9]{1,9}-[0-9]{1,6}\b'
assistant_pattern='claude|anthropic|co-authored-by:.*(assistant|bot)|generated with|ai-generated|ai assistant'

blocked=0

is_skipped() {
	local candidate=$1
	local skip
	for skip in "${skip_paths[@]}"; do
		[[ "$candidate" == "$skip"* ]] && return 0
	done
	return 1
}

changed_files=()
while IFS= read -r path; do
	[[ -z "$path" ]] && continue
	is_skipped "$path" && continue
	[[ -f "$path" ]] || continue
	changed_files+=("$path")
done < <(git diff --name-only "${base_ref}...${head_ref}")

commit_messages=$(git log --format=%B "${base_ref}..${head_ref}")

report_block() {
	blocked=1
	echo "::error::$1"
	echo "  BLOCKED: $1"
}

# ---------------------------------------------------------------- tracker links
if [[ ${#changed_files[@]} -gt 0 ]]; then
	if hits=$(grep -InE "$tracker_host_pattern" "${changed_files[@]}"); then
		report_block "Issue tracker link in changed files"
		echo "$hits"
	fi
fi

if grep -qIE "$tracker_host_pattern" <<<"$commit_messages"; then
	report_block "Issue tracker link in a commit message"
fi

# ----------------------------------------------------------------- tracker keys
if grep -qE "$tracker_key_pattern" <<<"$commit_messages"; then
	if grep -vE "\b(${innocent_prefixes})-" <<<"$commit_messages" | grep -qE "$tracker_key_pattern"; then
		report_block "Issue tracker key in a commit message"
		echo "  Tickets link out to GitHub. GitHub never links back."
	fi
fi

if [[ ${#changed_files[@]} -gt 0 ]]; then
	if hits=$(grep -InE "$tracker_key_pattern" "${changed_files[@]}" | grep -vE "\b(${innocent_prefixes})-"); then
		echo "::warning::Possible issue tracker key in changed files. Check these by eye."
		echo "$hits"
	fi
fi

# ------------------------------------------------------------- assistant traces
if [[ ${#changed_files[@]} -gt 0 ]]; then
	if hits=$(grep -InEi "$assistant_pattern" "${changed_files[@]}"); then
		report_block "Reference to an AI assistant in changed files"
		echo "$hits"
	fi
fi

if grep -qIEi "$assistant_pattern" <<<"$commit_messages"; then
	report_block "Reference to an AI assistant in a commit message"
	echo "  This includes Co-Authored-By trailers."
fi

if [[ $blocked -ne 0 ]]; then
	echo
	echo "This repository is public. Everything above is readable by anyone."
	exit 1
fi

echo "Forbidden references: none found across ${#changed_files[@]} changed file(s)."
