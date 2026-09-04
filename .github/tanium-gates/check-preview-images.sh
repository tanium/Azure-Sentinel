#!/usr/bin/env bash
# Every preview image a Tanium workbook declares has to exist on disk.
#
# A typo here is invisible until the workbook is live in the Content Hub, where it
# shows a broken preview to every customer browsing the solution.
#
# Run from the repository root.
set -euo pipefail

workbook_metadata="Workbooks/WorkbooksMetadata.json"
preview_folder="Workbooks/Images/Preview"
failed=0
checked=0

if [[ ! -f "$workbook_metadata" ]]; then
	echo "Could not find ${workbook_metadata}. Run this from the repository root."
	exit 1
fi

declared=$(jq -r '
	.[]
	| select(.provider == "Tanium")
	| .workbookKey as $key
	| (.previewImagesFileNames // []) + (.previewImages // []) + (.previewImagesDark // [])
	| unique[]
	| "\($key)\t\(.)"
' "$workbook_metadata")

while IFS=$'\t' read -r workbook_key image; do
	[[ -z "$image" ]] && continue
	checked=$((checked + 1))

	if [[ ! -f "${preview_folder}/${image}" ]]; then
		failed=1
		echo "::error file=${workbook_metadata}::Declared preview image not found: ${image}"
		echo "  BLOCKED: ${workbook_key} declares ${image}, which is not in ${preview_folder}/"
	fi
done <<<"$declared"

if [[ $failed -ne 0 ]]; then
	echo
	echo "Either add the image to ${preview_folder}/ or correct the name in ${workbook_metadata}."
	exit 1
fi

echo "Preview images: ${checked} declared image(s) all present in ${preview_folder}/."
