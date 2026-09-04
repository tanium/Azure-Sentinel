#!/usr/bin/env bash
# Works out which kind of version bump a release branch represents, so nobody has to
# tell the gate. The branch name already carries the target version, and the currently
# published version is a fact we can fetch, so the two together give the answer.
#
#   versions/3.4.0 against published 3.3.0  ->  minor
#   versions/3.3.1 against published 3.3.0  ->  patch
#
# A branch version that is not higher than what is published is a mis-named branch, and
# it fails here rather than producing a build that downgrades customers.
#
# Prints the bump type on stdout. Run from the repository root.
set -euo pipefail

target=${1:?release branch name required, e.g. versions/3.4.0}
branch_version=${target#versions/}

if [[ ! "$branch_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
	echo "Branch '${target}' does not name a version like versions/3.4.0." >&2
	exit 1
fi

published=$(pwsh -NoProfile -File ./Solutions/Tanium/ci/get-published-version.ps1 ./Solutions/Tanium/Data)
published=${published//[[:space:]]/}

if [[ ! "$published" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
	echo "Could not read the published version. Got: '${published}'" >&2
	echo "This needs Microsoft's catalog to be reachable." >&2
	exit 1
fi

IFS=. read -r branch_major branch_minor branch_patch <<<"$branch_version"
IFS=. read -r live_major live_minor live_patch <<<"$published"

if ((branch_major > live_major)); then
	echo "major"
elif ((branch_major == live_major && branch_minor > live_minor)); then
	echo "minor"
elif ((branch_major == live_major && branch_minor == live_minor && branch_patch > live_patch)); then
	echo "patch"
else
	echo "Branch version ${branch_version} is not higher than the published ${published}." >&2
	echo "Rename the branch, or check whether the release already shipped." >&2
	exit 1
fi
