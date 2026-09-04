# Working in this repository

Read this before making any change here.

## What this repository is

This is Tanium's fork of Microsoft's `Azure-Sentinel` repository. **It is public.** Anything committed here is readable by anyone on the internet, permanently, including by Microsoft and by other vendors who contribute to the same repository.

Tanium ships one thing from here: the solution under `Solutions/Tanium/`.

## Never do these

**Never mention AI assistance.** Not in code, comments, commit messages, pull request titles, pull request descriptions, or review comments. Do not add `Co-Authored-By` trailers naming any assistant.

**Never reference Tanium Jira.** No ticket keys, no `jira.corp.tanium.com` links, anywhere — including pull request comments, which are just as public as the code. A link nobody outside Tanium can open still tells a reader the hostname, the project name, and roughly how much work is behind it. Tickets link out to GitHub. GitHub never links back.

**Never commit `.claude/`.** Git does not ignore it here, so `git add -A` will stage it. The gate blocks any pull request that touches it, but check your staged files before you commit rather than finding out from a red build.

**Never change anything under `.github/`.** Tanium does not own it, and a change there reaches Microsoft's repository silently.

**Never edit this file or the workflows in `.github/workflows/tanium-*.yml` from a release branch.** They live on `tanium-base`. Editing them anywhere else breaks the rebase that prepares a submission.

## Branches

- `master` mirrors Microsoft. Never commit to it. It gets reset from `upstream/master` on every sync.
- `tanium-base` is `master` plus this file and the gate workflows. Internal-only, never submitted.
- `versions/X.Y.Z` is a release branch, cut from `tanium-base`.
- Your working branch is cut from the release branch, and your pull request goes back into it.

## Submitting to Microsoft

Do not open a pull request to `Azure/Azure-Sentinel` by hand.

Push a tag on `tanium-base` and let the submit workflow run. It rebases the release branch onto clean `master`, runs the checks that keep internal files out of Microsoft's diff, and hands back a link for a human to open the pull request.

## What Tanium owns

Tanium owns everything under `Solutions/Tanium/`.

Outside that folder, Tanium owns files with `Tanium` in the name. That is the whole rule, and it covers logos, preview images, sample data, and test fixtures alike. Adding a new one of any of those needs no change here.

One shared file is different. `Workbooks/WorkbooksMetadata.json` belongs to every vendor, and Tanium owns only the entries whose `provider` is `Tanium`.

Anything else in this repository belongs to Microsoft or to another vendor. Changing it affects people who are not on this team.

## Versions

If you change a workbook, a playbook, or an analytics rule, bump that item's version in the same pull request.

This is not bookkeeping. Sentinel builds a content item's identity from its version. Changed content shipped under an unchanged version looks identical to what a customer already has, so they may never be offered the update, and nothing on our side reports that it happened.
