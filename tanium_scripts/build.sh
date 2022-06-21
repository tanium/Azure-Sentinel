#!/bin/bash
LOG=/tmp/tanium_sentinel_create_package.log

_fail() {
  cat "$LOG"
  echo "##########"
  grep Failed "$LOG"
  grep -E 'Errors.*:.*[A-Z]' -A10 "/tmp/tanium_sentinel_create_package.log"
  echo "Detected build failure ^^^"
  exit 1
}

pwsh -Command 'Tools/Create-Azure-Sentinel-Solution/createSolution.ps1' > "$LOG"
grep -qm1 '^Failed' "$LOG" && _fail
echo "Build succeeded see:
- files: ./Solutions/Tanium/Package/*
- build log: $LOG"
exit 0
