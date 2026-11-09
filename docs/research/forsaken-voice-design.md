# Official Forsaken voices

On November 9, 2026, the user approved **male A** and **female C** from the six Forsaken auditions. Their reply "Make A / Female C" was interpreted as male A and female C in response to the male/female selection question.

Both selected previews were saved through ElevenLabs' [create-voice endpoint](https://elevenlabs.io/docs/api-reference/text-to-voice/create), then independently retrieved by ID to verify the saved names and identities.

| Recording group | Selected option | Saved name | Voice ID |
| --- | --- | --- | --- |
| `forsaken-male` | A | BuddyDex Forsaken Male (Hollow) | `xNLT6f0TsMKlsUoMALsm` |
| `forsaken-female` | C | BuddyDex Forsaken Female (Hollow) | `6lg3YonFTCHEchATaHoV` |

These IDs are registered in `tools/voice/generate.py`. The recording model remains the user-selected `eleven_v4`. The NPC-profile goal was paused during voice selection and has since resumed. Runtime Forsaken routing and signature recordings are covered by [the production audit](forsaken-recording-completion.md), using verified display metadata and the actual selected voices.

## Audition artifacts and provenance

Artifacts remain outside the release source at `C:/Users/brett/BuddyDex-voice-auditions/2026-11-09-forsaken/`. Each sex has three MP3 previews plus `auditions.json`; the selected manifests now retain `selected_option`, `voice_id`, `voice_name`, `selected_on` and `selected_and_saved` status. Both combined `*-ABC.wav` files and `comparison-index.json` preserve A/B/C order, two-second gaps and exact start times. Unselected auditions are preserved.

The prompts and common script are reproducible in `tools/voice/design.py`. They target dry, hollow, brittle, weathered voices with a persistent rasp, strained breath, restrained emotion and sardonic humor. The common script tests humor, weariness, a warning and sincere warmth. No actor or existing performer is imitated.

Voice creation previews used `eleven_ttv_v3`, the separate [voice-design model](https://elevenlabs.io/docs/api-reference/text-to-voice/design). This does not change the selected v4 model for future NPC speech. Each of the six previews decoded at 44.1 kHz with finite, non-silent audio and a sensible duration; combined PCM WAVs were re-decoded and checked for exact sample counts. The user judged the sound and selected the official voices.

The existing locally stored API key was used privately and was not printed or committed. No replacement or deletion of the human, orc, troll or other established voices was performed.
