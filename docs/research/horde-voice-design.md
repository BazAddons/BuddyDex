# Horde voice auditions

Requested by the user November 8, 2026. The user selects official male/female voices for each race.

## User review and second round

The user approved **orc male B**, saved as **BuddyDex Orc Male (Gravel)**, voice ID `SsUXUYPOaoD5XMe36mlU`. It is registered in the recording tool. Runtime orc race routing is enabled with the Gryshka and Doras recordings.

The user rejected the first orc female options as too soft and requested more gravel. Round two asks for a very low contralto with a pronounced coarse rasp, throaty growl and rough texture even during friendly speech. The user also requested Jamaican accents for trolls; round two explicitly specifies distinct Jamaican English pronunciation and rhythm for both sexes, replacing the broader Caribbean-inspired prompt. The user selected **orc female C**, **troll male A**, and **troll female C**. All three are saved as official voices: `QooG6jOovlSJWv2vSqN8`, `X3ETuf4PfUMURFMpRT73`, and `0xQXygLnre17fk87G6Kt`, respectively.

Second-round previews live at `C:/Users/brett/BuddyDex-voice-auditions/2026-11-08-round2/`. First-round previews are preserved.

## Current options

Three previews each were generated with **eleven_ttv_v3** for:

- Orc male: A, B, C.
- Orc female: A, B, C (Gryshka's voice; second-round C selected).
- Troll male: A, B, C. Doras was subsequently verified as an orc, not a troll.
- Troll female: A, B, C.

Prompts aim for original fantasy character voices with clear, expressive speech. Orcs have weight and natural roughness; trolls have a relaxed Caribbean-inspired rhythm. No actor or existing game's performer is cloned or impersonated. Prompts and audition text are reproducible in `tools/voice/design.py`.

## Review artifacts

Saved outside the release source at `C:/Users/brett/BuddyDex-voice-auditions/2026-11-08/`. Each role has three MP3 previews plus `auditions.json` containing the generated IDs needed to save the chosen voice. The top-level `*-ABC.wav` files combine the options in order with two-second gaps; `comparison-index.json` records exact start times. No API key is written to these files.

The user approved all four voices across two rounds. Recording-tool IDs are saved; runtime orc routing and display metadata are added with Gryshka and Doras's clips. Troll routing awaits a troll profile with bundled recordings.

## API references

- [Design previews](https://elevenlabs.io/docs/api-reference/text-to-voice/design): `POST /v1/text-to-voice/design`, `model_id=eleven_ttv_v3`, three preview results with `generated_voice_id` and audio.
- [Save the chosen preview](https://elevenlabs.io/docs/api-reference/text-to-voice/create): `POST /v1/text-to-voice` with the generated ID, voice name and description. This creates the persistent voice used for future speech recordings.

Audio files were decoded and checked for nonempty, finite, nonsilent speech. The user is the audition judge; no listening-based quality claim was made by the agent.

## Recording model update

After a same-voice, same-text v3/v4 comparison on November 8, the user chose **Eleven v4** for future recordings, with deliberate emotional direction. Voice creation previews used `eleven_ttv_v3`; this is separate from the `eleven_v4` speech model. Comparison artifacts are outside the repository at `C:/Users/brett/BuddyDex-voice-auditions/v3-v4-comparison/`. V4 requests use the [Text to Dialogue endpoint](https://elevenlabs.io/docs/api-reference/text-to-dialogue/convert), with one speaker per clip. Existing audio stays intact.
