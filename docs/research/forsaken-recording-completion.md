# Forsaken signature recording production

Production date: 2026-11-09. The user approved Forsaken male A and female C, saved as BuddyDex Forsaken Male (Hollow), `xNLT6f0TsMKlsUoMALsm`, and BuddyDex Forsaken Female (Hollow), `6lg3YonFTCHEchATaHoV`. The selected production model is Eleven v4. Voice Design's separate v3 preview model is not the recording model.

## Scope and identity evidence

Twenty-five previously written profiles, with fifteen personal lines and four directed scripts each. Names, current model displays and adult race/sex metadata were checked again against the public Forever NPC nodes and the installed Scout snapshot. [The identity snapshot](forsaken-recording-identities.json) records all 25 identities, source URLs, displays, voice groups and selected moments. It does not claim a new live encounter. Sparse public reaction fields are supplemented by Scout's friendly, nonattackable humanoid observations.

Seven female profiles use female C; eighteen male profiles use male A. None is voiced by the human or gnome groups. Existing race/sex metadata was compared before/after generation: all 6,478 old body mappings are preserved, with 722 Forsaken display mappings added from the cached branch tables. The refreshed source also adds fourteen sound-set display mappings and updates display 149113 from sound set 46 to 49; existing sound-kit sets are unchanged. The 25 profiled displays resolve to race 5 and their independently scouted sex. Current official ElevenLabs voice names/IDs were retrieved and verified before recording.

The earlier research remains the source of the lore and full quest-chain work:

- [Mordo, Sarvis, Elreth](deathknell-first-awakenings.md)
- [Aramis Hammerhand and his related chains](aramis-hammerhand-in-progress.md)
- [Arren and Saltain](arren-and-saltain.md)
- [Deathknell's ordinary company](deathknell-ordinary-company.md)
- [The four named deathguards](deathknell-named-deathguards.md)
- [Isabella, Maximillion and Kayla](deathknell-arcane-and-demons.md)
- [Venya, Clarence and Florence](deathknell-knowledge-and-first-lessons.md)
- [Rand and Raims](deathknell-smiths.md)
- [Stern, Trias and Duesten](deathknell-three-trainers.md)

This recording pass changes no canonical facts or private story hooks. Earlier pending-recording statements describe the authoring stage, and are superseded by the completion audit below.

## Runtime behavior and verification

Each profile receives a greeting, idle line, first-outing welcome, and one role-specific reaction. The exact chosen moments are in the identity snapshot. Existing individual tone tags are preserved in the generated spoken text and omitted from speech bubbles. Unrecorded personal or general lines remain text-only for these recorded voices; this is a signature pack, not a newly recorded full generic Forsaken dialogue library. Existing game sounds remain the fallback for races without a bundled recorded voice. No copied actor or in-game voice-clone recording is made.

The per-voice manifests preserve exact text, spoken tone direction, source NPC ID, voice ID, moment, line index and `eleven_v4` model. The runtime Lua manifest maps those same lines to bundled Ogg files. Verification must decode every new clip as finite non-silent mono 22050 Hz audio, check all 100 exact manifest mappings, and play each NPC's first-outing welcome once in the mock client. The complete gameplay smoke/API audit also covers ordinary and favorite emotes, generic guards and child exclusions, dialogue budgets and existing voice groups. Automated decoding and playback checks do not claim human listening or live UI inspection.

## Completion audit

All 100 requested signatures were generated and decoded successfully. All 25 identities passed exact text/tone/model/voice/source and runtime-manifest checks. Each retained all profile fields and fifteen supported personal lines, earned ordinary and favorite emote friendship separately, and played its own recorded first-outing welcome once in the mock client. Full BuddyDex (23 files) and Scout (6 files) smoke/API audits passed with zero load errors and failures. The selected official voices were independently verified before production.
