# CurseForge publishing

Verified BuddyDex project: **1793016**, https://www.curseforge.com/wow/addons/buddydex (owner Baz4k). User supplied author URL and saved a local token on2026-11-09. Configured repository Actions secret `CF_API_KEY` and variable `CF_PROJECT_ID=1793016`; secret value is outside the repository and never logged. GitHub connector has no Actions-secret capability; used authenticated GitHub CLI stdin to set encrypted secret.

`.github/workflows/release.yml` follows BazUI's BigWigs packager workflow, with Forever flavor and verified project ID. Push a version tag to publish; hand-dispatch with `upload=false` only packages and retains an artifact. Verify that artifact before the release tag. Check workflow result and CurseForge receipt after tagging; a green packaging check alone is not publication proof. Existing public listing on2026-11-09 shows v001, not v002. Older274-profile v002 handoff remains preserved locally; latest development package452profiles verified before publication. Do not infer a prior manual v002 upload.

## v002 upload receipt (2026-11-09 local)

User's saved token authenticated against the author API; Forever1.60.1 versionID17053. Packaging-only run42748085292 passed, artifact downloaded and independently checked. Published annotatedtag `v002` atf5a3777; tag workflow https://github.com/BazAddons/BuddyDex/actions/runs/42748352716 completed successfully. Log explicitly records `BuddyDex-v002-forever.zip (1.60.1 release)` uploaded to CurseForgeproject1793016 followed by Success. This proves acceptedupload, not publicmoderationapproval; no separateCFfileID in visiblelogs. Do not resubmit merely because the publicpage is slow to update.

GitHubrelease https://github.com/BazAddons/BuddyDex/releases/tag/v002 hasZIP144253508bytes/SHA25689baa5d2b8ea1a43fe3a727adfdb75ad489f940826890ca355df11a2a47bf451. DownloadedpublishedZIPpassedCRC, expectedfile-set, allsourcecontentcomparison (onlyCRLFnormalizationforLICENSE/UI/Pages.lua/UI/NpcMenu.lua),452Luaprofiles/6,342files/6,314runtimeaudio mappings. Original274-profilehandoffarchivepreserved. FullNPCcompletiongoalcontinues; publishedtagimmutable.
