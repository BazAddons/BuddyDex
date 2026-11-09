# Publishing BuddyDex

The user wants tag-based CurseForge publication, like BazUI. Publishing is deferred until the user is home tonight (2026-11-09); continue profile development meanwhile. Do not claim a CurseForge upload has occurred or create a new public version because a package-only run succeeded.

## Repository setup

BuddyDex's `.github/workflows/release.yml` uses BigWigsMods/packager@v2 with Forever flavor. A pushed annotated version tag triggers publishing. Configure these in **BazAddons/BuddyDex**, not BazUI:

- Actions secret `CF_API_KEY`: the CurseForge publishing token. Never put it in chat, source, logs or release artifacts. BazUI's encrypted repository secret cannot be read back or copied from GitHub.
- Actions variable `CF_PROJECT_ID`: BuddyDex's independently verified numeric CurseForge project ID. Do not use BazUI's ID 1698481.

The preflight step requires both values before an uploading run, so missing credentials cannot silently produce a successful GitHub-only release. The verified BuddyDex project URL/ID and this secret were still missing on 2026-11-09; the user will supply/configure them at home. No `v002` tag has been pushed.

## Package-only verification

Run `gh workflow run release.yml --repo BazAddons/BuddyDex --ref main -f upload=false`. It uses packager `-d` (skip uploads) and retains ZIPs in the `BuddyDex-package` run artifact. Do not interpret the old-tag-based filename on an untagged dry run as the next release number.

[Run 42640592970](https://github.com/BazAddons/BuddyDex/actions/runs/42640592970), source f62fc4d, succeeded. Its downloaded `BuddyDex-v001-131-gf62fc4d-forever.zip` was checked for ZIP CRC, one addon directory, version 002 metadata, bundled signature audio and LICENSE, with tools/docs/per-voice manifests excluded. The 5662 ZIP entries include directory records. No CurseForge upload or GitHub release was made by this dry run.

The compact public-facing notes are `docs/releases/v002-changelog.md`, selected by `.pkgmeta`. Research and development history remain in CHANGELOG.md and docs. Keep the release notes current with any further profiles selected for v002.

## Before publishing tonight

Resolve whether a manual v002 upload occurred and verify the actual CurseForge project. If v002 is still unpublished, include the agreed latest development work, run the standard validations and packaging, then create and push annotated tag `v002`. Inspect the resulting Action's actual CurseForge upload response and verify the file/project; a green job or GitHub asset alone does not prove CurseForge publication. If v002 already exists on CurseForge, do not overwrite or reuse the version without resolving that state.

The older manually handed-off v002 ZIP is preserved separately by the SHA256 in v002-upload-candidate.json. Do not silently overwrite it while that handoff's publication status is unresolved. Development ZIPs currently go under the builds/development directory.
