# Tauren, goblin and child voice auditions

Requested November 9, 2026 while the NPC-profile goal is paused. The user requested the remaining groups and explicitly asked for separate A/B/C audio files rather than combined players.

## Ready for selection

Three previews each for Tauren male, Tauren female, goblin male and goblin female: twelve independent MP3 files. Each group has a common test script covering a greeting, humor, a warning and friendship. Original prompts and scripts are preserved in each external audition manifest; the latest defaults are in `tools/voice/design.py`.

Artifacts: `C:/Users/brett/BuddyDex-voice-auditions/2026-11-09-remaining-voices/`. Each group has its own subdirectory containing `<group>-A.mp3`, B, C and `auditions.json` with generated voice IDs and `awaiting_user_selection` status. `separate-files-index.json` records file paths, durations and SHA-256 hashes. No combined player was created for this round.

Tauren prompts target broad warm resonance, grounded conversational delivery and subtle bovine texture, with a bass-baritone man and rich contralto woman. Goblin prompts target brisk, nasal, gritty, streetwise adult voices with a broadly New York English accent. These are original fictional voices, not imitations of performers.

All twelve MP3s decoded at 44.1 kHz with finite non-silent audio and sensible durations. Distinct audio hashes and generated IDs were verified across all options. These checks establish valid independent files, not a listening judgment; the user selects the voices. The Tauren choices were subsequently saved as official; see the selection update below. No runtime routing was enabled by this audition task. Future speech recordings retain Eleven v4; preview creation uses the separate `eleven_ttv_v3` design model.

## Children remain pending

The boy-voice design request returned HTTP 403 with the provider message: "Sorry, this prompt potentially doesn't follow our safety guidelines and therefore has been blocked." No child audio was generated. A rephrased retry and the analogous girl request were not made after this rejection. `pending-child-voices.json` in the external audition folder preserves the bounded failure and status. No existing child profile was assigned an adult voice.

The API key was read privately from its existing external location and was never printed or committed. The profile goal stays paused; no NPC authoring, bulk NPC recording, installation or upload ZIP refresh was resumed by this audition task.

## Selection and Brooklyn revision

The user selected **Tauren male C** and **Tauren female B** on November 9, 2026. Both were saved through ElevenLabs and retrieved independently to verify their names/IDs:

| Group | Option | Saved name | Official voice ID |
| --- | --- | --- | --- |
| Tauren male | C | BuddyDex Tauren Male (Earthy) | `UHjFz97GTxtpwstZu19x` |
| Tauren female | B | BuddyDex Tauren Female (Earthy) | `HriwExkmKzil2cQ4bGmf` |

Both IDs are registered in `tools/voice/generate.py`; future recordings remain Eleven v4. The external selected manifests retain the choices and saved identity. Existing voices and unselected samples remain preserved. Runtime Tauren routing awaits verified NPC profiles and bundled recordings when the profile goal resumes.

The user requested **thick Brooklyn accents** for both goblin sexes instead of selecting from the initial options. Initial goblin manifests are marked `superseded_accent_revision`, with no official voice saved. Revised prompts emphasize the accent from the first sentence through sincere speech, including characteristic vowel placement and punchy cadence. A new shared test script includes coffee, talk, cart, water and corner. These are original adult fictional voices with nasal/gritty male and brassy/husky female timbres.

Revised independent A/B/C MP3s and per-group manifests live outside the release tree at `C:/Users/brett/BuddyDex-voice-auditions/2026-11-09-goblin-round2/`. They await user review; no combined player or automatic official selection is used. The profile goal remains paused.

The six second-round goblin MP3s decoded at 44.1 kHz with finite, non-silent speech and sensible durations. Unique audio hashes and generated IDs were checked across A/B/C for both sexes, and `separate-files-index.json` preserves their paths and durations. Accent suitability remains the user's listening judgment.

## Third goblin round: Brooklyn first

The user heard the second-round goblins as British rather than thick New York. Both second-round manifests are marked superseded; no option was saved as an official goblin voice.

Third-round descriptions begin with native American English, USA, and a very thick Brooklyn, New York City dialect. The fantasy/goblin identity was removed from the description, leaving a Brooklyn-born shopkeeper persona with nasal, raspy/brassy character texture. The script uses ordinary spelling, including coffee, water, forty and corner, to expose pronunciation rather than simulate it with phonetic respelling.

Following ElevenLabs' [voice-design guidance](https://elevenlabs.io/docs/eleven-creative/voices/voice-design), the regional variant is specified first and request guidance is increased to 20. `tools/voice/design.py` accepts `--guidance-scale` and includes it in persisted metadata and cache matching. Existing default requests preserve their original behavior.

New independent MP3s/manifests live at `C:/Users/brett/BuddyDex-voice-auditions/2026-11-09-goblin-round3/`, with A/B/C files per sex. All six decoded at 44.1 kHz with finite, non-silent audio and sensible durations; unique hashes and generated IDs were verified. The actual CLI cache was exercised with network disabled, confirming repeated identical requests reuse the saved previews. A separate-files index records paths and durations. These technical checks do not establish that the accent meets the user's preference; that requires their listening review. Tauren selections remain saved, goblin selection remains pending, and the profile goal remains paused.

## Fourth goblin pass: accent reference plus character texture

The user accepted the third-round accent but said the voices did not sound like goblins. Third-round manifests now preserve that feedback with `accent_accepted_timbre_revision` status. No official goblin choice was made. Option A from each sex was used only as a working audio reference, not as an official user selection. These are original synthetic previews created for this project.

The [design endpoint](https://elevenlabs.io/docs/api-reference/text-to-voice/design) supports reference audio and prompt/reference balance for `eleven_ttv_v3`. The fourth pass uses each reference with prompt strength 0.55 and guidance scale 15. Descriptions retain the Brooklyn American dialect first, then request pronounced upper/high-mid, pinched, wiry nasal resonance, scratchy throat grit, toothy animated delivery and goblin character. The ordinary-spelling script remains unchanged for comparison. No audio pitch filter or impersonation was used.

`tools/voice/design.py` now supports `--reference-audio` and `--prompt-strength`, records reference SHA-256 and balance in the manifest, and includes them in cache matching. The male CLI was checked offline: identical settings reuse the previews without network access, while a changed balance refuses to overwrite the existing audition folder.

Three male MP3s generated successfully at `C:/Users/brett/BuddyDex-voice-auditions/2026-11-09-goblin-round4/goblin-male/`, each separate as requested. All three decoded at 44.1 kHz with finite non-silent audio, sensible duration and distinct IDs/hashes. The reference hash and synthesis settings were verified; a separate-files index records the results. Timbre and accent suitability remain for the user's listening review.

The adult female goblin request returned HTTP 403 with the provider's generic potential-safety-guidelines rejection, without a more specific reason. No rephrased retry was made. `female-pending.json` records the bounded failure. No new female preview or official voice was saved. Tauren choices remain official, goblin selection remains pending, and the profile goal remains paused.

## Fifth male goblin pass: lighter character

The user described the fourth-round male options as entirely too gravity, interpreted in context as too gravelly/heavy. The user was told that interpretation before generation. The male prompt now targets a clean, bright upper-mid adult register, narrow nasal/reedy twang, cheeky pitch movement and quick comic timing instead of a gravel-heavy throat.

The reference remains third-round male A, whose accent the user had accepted; the rejected gravel-heavy fourth round is not used as a reference. Prompt strength is reduced to 0.4, with guidance 15, to retain more of the cleaner reference. The ordinary-spelling comparison script is unchanged. Fourth-round male files are preserved and marked superseded. Fifth-round independent male A/B/C files are saved outside the release tree at `C:/Users/brett/BuddyDex-voice-auditions/2026-11-09-goblin-round5/`.

This is an adult goblin revision, not a child-voice request. The blocked female request was not retried. No official goblin voice is selected, and the profile goal remains paused.

All three fifth-round male MP3s decoded at 44.1 kHz with finite, non-silent speech and sensible durations. Distinct IDs/hashes and the original accent-reference hash were verified; the separate-files index records paths and durations. The user judges the balance of accent and character.

## Sixth male pass: smaller adjustment, retain Brooklyn

The user said the fifth-round voices sounded rushin, interpreted in the accent-review context as Russian. This interpretation was stated to the user. Fifth-round samples remain preserved with an accent-revision note.

The sixth prompt removes all fantasy/goblin identity labels and requests only a slightly higher, lighter, bright nasal/reedy twang with playful, snappy adult delivery. It retains the accepted third-round male A Brooklyn reference, now at prompt strength 0.2 and default guidance 5 to make a smaller change. The comparison script is unchanged and uses ordinary spelling.

Three independent A/B/C MP3s are at `C:/Users/brett/BuddyDex-voice-auditions/2026-11-09-goblin-round6/goblin-male/`. All decoded at 44.1 kHz with finite, non-silent audio, sensible durations and distinct IDs/hashes. The reference hash and actual request settings were verified; a separate-files index records the results. These checks do not prove an accent or character judgment; the user evaluates the sound. No official goblin voice has been saved. The blocked female revision was not retried, and the profile goal remains paused.

## Return to the first-round character baseline

The user said the very first goblin auditions remain the best, despite sounding British, and wondered about using in-game clips in ElevenLabs. The initial goblin audition manifests now preserve that character preference without marking an A/B/C option officially selected. No additional generation or official save was performed for this discussion.

ElevenLabs requires permission/valid authorization for cloning a person's voice; no Blizzard/game actor recording was uploaded or extracted for cloning. The [dedicated Voice Remix feature](https://elevenlabs.io/docs/overview/capabilities/voice-remixing) supports accent changes on owned designed voices while aiming to retain voice identity. That is a possible next approach using our own first auditions after the user chooses the preferred base voices. It is distinct from the previous audio-reference Voice Design passes; accent success is not guaranteed.

## Original B bases and dedicated Voice Remix

The user selected **original male B and original female B as the remix bases**, in response to the explicit accent-only remix question. Both original generated voices were saved intact in ElevenLabs and retrieved to verify identity:

| Base | Original option | Saved name | Base voice ID |
| --- | --- | --- | --- |
| Male | B | BuddyDex Goblin Male - Original B Base | `q4hkgjwgAzNLGZbjuFX9` |
| Female | B | BuddyDex Goblin Female - Original B Base | `GK7FvLcUviYyxNu6jR0D` |

The source audition manifests preserve `selected_as_remix_base`, `base_selected_option`, `base_voice_id` and `base_voice_name`. The originals have not been altered or registered as a final production goblin voice.

`tools/voice/remix.py` implements the dedicated [Voice Remix endpoint](https://elevenlabs.io/docs/api-reference/text-to-voice/remix). It saves/reuses the chosen owned base, verifies its identity, requests changes from that base ID and stores separate A/B/C previews without overwriting old ones. This differs from the preceding text/audio-reference Voice Design experiments. The request changes only accent to thick Brooklyn American English, preserving pitch, nasal character, texture, pace and playfulness. Original test text is retained for comparison. Guidance is 5 and prompt strength 0.35.

New separate files and manifests are outside the release tree at `C:/Users/brett/BuddyDex-voice-auditions/2026-11-09-goblin-originalB-remix/`. They await user review; selecting a base is not automatic approval of a generated remix. No NPC recording, runtime routing, profile authoring, installation or packaging was resumed. The profile goal remains paused.

Both original-B remix requests succeeded, returning six independent MP3s. All decoded at 44.1 kHz with finite, non-silent speech, sensible durations and distinct IDs/hashes. Base IDs, B-source provenance and request settings were verified. The actual CLI cache was exercised with offline identity responses and POST requests forbidden, confirming unchanged requests reuse saved previews without creating another voice or generation. Accent and character quality remain for the user to judge.

## Final goblin decision: original B voices

The user chose to stop accent iteration and keep the selected original voices. The final official choices are **original male B and original female B**, not any accent-only remix. Both existing saved bases were renamed and independently retrieved to verify identity:

| Group | Official name | Voice ID |
| --- | --- | --- |
| Goblin male | BuddyDex Goblin Male (Original B) | `q4hkgjwgAzNLGZbjuFX9` |
| Goblin female | BuddyDex Goblin Female (Original B) | `GK7FvLcUviYyxNu6jR0D` |

These IDs are registered in `tools/voice/generate.py`, retaining Eleven v4 for future NPC recordings. Original audition manifests now retain `selected_and_saved`, option B and the official names/IDs. All later audition/remix files remain preserved for history but are not selected production voices. Further goblin accent auditions have ended at the user's request. The NPC-profile goal remains paused, and runtime routing awaits verified profiles and bundled recordings when that goal resumes.


## Adult-only scope ? 2026-11-09

The user excluded children from BuddyDex and authorized deletion of the ten written child profiles. Child voice auditions and recordings are cancelled; child prompts have been removed from the design tool. Adult voice selections remain unchanged.
