# Horde voice auditions

Requested by the user November 8, 2026. The user selects official male/female voices for each race.

## User review and second round

The user approved **orc male B**, saved as **BuddyDex Orc Male (Gravel)**, voice ID `SsUXUYPOaoD5XMe36mlU`. It is registered in the recording tool. Runtime race routing will be enabled with bundled recordings so existing NPC audio is not silenced prematurely.

The user rejected the first orc female options as too soft and requested more gravel. Round two asks for a very low contralto with a pronounced coarse rasp, throaty growl and rough texture even during friendly speech. The user also requested Jamaican accents for trolls; round two explicitly specifies distinct Jamaican English pronunciation and rhythm for both sexes, replacing the broader Caribbean-inspired prompt. These three roles still await selection.

Second-round previews live at `C:/Users/brett/BuddyDex-voice-auditions/2026-11-08-round2/`. First-round previews are preserved.

## Current options

Three previews each were generated with **eleven_ttv_v3** for:

- Orc male: A, B, C.
- Orc female: A, B, C (Gryshka's upcoming voice).
- Troll male: A, B, C (Doras's upcoming voice).
- Troll female: A, B, C.

Prompts aim for original fantasy character voices with clear, expressive speech. Orcs have weight and natural roughness; trolls have a relaxed Caribbean-inspired rhythm. No actor or existing game's performer is cloned or impersonated. Prompts and audition text are reproducible in `tools/voice/design.py`.

## Review artifacts

Saved outside the release source at `C:/Users/brett/BuddyDex-voice-auditions/2026-11-08/`. Each role has three MP3 previews plus `auditions.json` containing the generated IDs needed to save the chosen voice. The top-level `*-ABC.wav` files combine the options in order with two-second gaps; `comparison-index.json` records exact start times. No API key is written to these files.

The user was given the four audio players and a pending selection question. Continue writing/researching other profiles while waiting. Save only the user's chosen previews as official voices, then update `VOICES`, `Voice.RACE_VOICES`, recordings and the bundled manifest. Do not choose A by default or treat silence as selection.

## API references

- [Design previews](https://elevenlabs.io/docs/api-reference/text-to-voice/design): `POST /v1/text-to-voice/design`, `model_id=eleven_ttv_v3`, three preview results with `generated_voice_id` and audio.
- [Save the chosen preview](https://elevenlabs.io/docs/api-reference/text-to-voice/create): `POST /v1/text-to-voice` with the generated ID, voice name and description. This creates the persistent voice used for future Eleven v3 speech recordings.

Audio files were decoded and checked for nonempty, finite, nonsilent speech. The user is the audition judge; no listening-based quality claim was made by the agent.
