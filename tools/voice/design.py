#!/usr/bin/env python3
"""Create audition previews; never saves an official voice without selection.

Uses ElevenLabs' /v1/text-to-voice/design with eleven_ttv_v3:
https://elevenlabs.io/docs/api-reference/text-to-voice/design
Keep the output outside the release tree. API key comes from the environment.
"""
import argparse
import base64
import json
import os
from pathlib import Path
import urllib.error
import urllib.request

DESCRIPTIONS = {
    "forsaken-male": "An original Forsaken undead man, formerly human, mature adult. Immediately corpse-like vocal texture: dry brittle rasp, hollow thin resonance, a cracked creaking throat and faint strained breath escaping between words. Mid-low masculine register, worn and gaunt rather than a powerful booming chest. Every ordinary sentence retains the rough dead-throat grain, even when friendly. Quietly sardonic, world-weary and watchful, able to become cold and unsettling without shouting. Subtle traces of warmth beneath the fatigue. Clear intelligible neutral English, measured conversational pacing, small uneven pauses. A haunted person with a dry sense of humor. Clean close studio speech; the undead quality must come from the voice itself, without reverb, electronic filtering, doubled voices, music or ambience. Original fantasy character, not an imitation of any actor or existing performer.",
    "forsaken-female": "An original Forsaken undead woman, formerly human, mature adult. Immediately corpse-like vocal texture: dry papery rasp, hollow narrow resonance, a cracked creaking throat and faint strained breath escaping between words. Low-mid feminine register, gaunt, brittle and worn. Clearly female, with sharp intelligible consonants and a rough dead-throat grain that persists during friendly conversation. Quietly sardonic, world-weary and watchful, able to turn cold and unsettling without shouting. A little genuine warmth survives beneath the fatigue. Neutral English, measured conversational pacing, small uneven pauses. A haunted person with dark humor, never a silky seductive or polished narrator voice. Clean close studio speech; undead quality comes from the voice itself, without reverb, electronic filtering, doubled voices, music or ambience. Original fantasy character, not an imitation of any actor or existing performer.",
    "tauren-male": "An original adult male tauren, a very large bovine humanoid in a fantasy world. A deeply resonant bass-baritone with broad rounded vowels, substantial warm chest resonance, a soft low rumbling grain and a subtle bovine nasal resonance. Calm physical weight in ordinary conversation. Unhurried but responsive, thoughtful, grounded and capable of a warm chuckle, firm warning or genuinely pleased greeting. Clear intelligible neutral English; a natural speaking voice with personality, rather than constant solemn narration. Strength expressed through steady breath and rich resonance, without shouting or an aggressive orc growl. Original fantasy character, not an imitation of an actor, existing performer or a real-world ethnic accent. Clean close studio recording without artificial bass effects, reverb, music or background sound.",
    "tauren-female": "An original adult female tauren, a very large bovine humanoid in a fantasy world. A rich low feminine contralto with broad rounded vowels, full warm chest resonance, earthy vocal grain and a subtle bovine nasal resonance. Clearly feminine with a substantial grounded sound, conversational rather than breathy or delicate. Calm confidence, practical warmth and a gently amused sense of humor, able to give a firm warning or express real delight. Unhurried but responsive pacing, clear intelligible neutral English and natural breaths. Quiet strength and generous resonance rather than an aggressive orc rasp or a polished ethereal narrator. Original fantasy character, not an imitation of an actor, existing performer or a real-world ethnic accent. Clean close studio recording without artificial pitch effects, reverb, music or background sound.",
    "orc-male": "An original fantasy orc man, middle aged. Very deep resonant chest voice, broad baritone with a gravelly edge and weight behind each word. Neutral American English, strong clear consonants, a slightly tusked resonance, natural breath and texture. A seasoned warrior who can be warmly welcoming, dryly amused or firmly commanding. Controlled power, never constant shouting. Conversational pacing, good emotional range, intelligible speech, clean studio recording without effects, music or background noise. Not an imitation of any actor or existing character.",
    "orc-female": "An original fantasy orc woman, mature adult veteran. A very low female contralto with a pronounced coarse gravelly rasp, throaty growl and heavy chest resonance. Her vocal folds sound rough and weathered even in a friendly greeting: substantial audible gravel throughout ordinary speech. Strong, blunt, battle hardened and formidable, with crisp intelligible words. Neutral American English with a heavy tusked resonance. Dry humor and restrained warmth come through the rough texture. Full voiced conversational speech with weight and authority, never breathy, silky or soft spoken. Natural expressive range without constant shouting. Clean studio recording, no distortion effects or background sound. Not an imitation of any actor or existing character.",
    "troll-male": "An original fantasy troll man, adult. A distinctly Jamaican English accent, clearly audible from the first sentence and maintained throughout: authentic Jamaican vowel sounds, melodic pitch movement, rhythmic stress and relaxed cadence. Speak the supplied English naturally in this strong Jamaican accent with clear intelligible words. A medium-low male voice with lean chest resonance, a lightly nasal edge and natural smoky rasp. Warm, playful confidence, experienced traveler, able to become watchful and serious. Conversational and expressive, with an easy smile and grounded authority. Clean studio recording with no effects or background sound. Original character, not an imitation of any actor or existing performer.",
    "troll-female": "An original fantasy troll woman, adult. A distinctly Jamaican English accent, clearly audible from the first sentence and maintained throughout: authentic Jamaican vowel sounds, melodic pitch movement, rhythmic stress and relaxed cadence. Speak the supplied English naturally in this strong Jamaican accent with clear intelligible words. A rich medium-low female contralto with a husky grain and lightly nasal resonance. Warm, perceptive and mischievous, expressive and confident, able to turn calm advice into a firm warning. Full voiced conversational speech with personality and an easy smile. Clean studio recording without effects or background noise. Original character, not an imitation of any actor or existing performer.",
}
ORC_TEXT = "[warmly] Come in, traveler. There is room by the fire, and you look as though you could use a rest. [amused] You brought all that gear, but forgot your lunch? A warrior should plan ahead. [firmly] Stay close. Watch the road, and we will see each other safely home. [softly] It is good to have a friend along."
TROLL_TEXT = "[warmly] Welcome, traveler. Take a breath. The road will still be there when you are ready. [amused] So many bags, and still you say there is nothing to eat. [serious] Keep your eyes open now. We walk together, and we watch out for each other. [cheerfully] Another adventure, another story to tell when we get home."


FORSAKEN_TEXT = "[dryly] Still breathing, are you? Try not to make a habit of it. [weary] The road is long, and these bones remember every mile. Give me a moment. [coldly] Stay close. There are things in the dark that have not learned to fear us yet. [quietly, sincere] You came back. I had almost forgotten what it feels like to be remembered."
TAUREN_TEXT = "[warmly] Welcome, friend. Sit a moment and tell me how the road has treated you. [amused] You have carried that bag a long way. I hope you remembered something to eat. [firmly] Keep your eyes open. We will look after one another. [sincerely] It is good to walk beside someone whose company brings peace."

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--all", action="store_true")
    group.add_argument("--role", choices=DESCRIPTIONS)
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()
    key = os.environ.get("ELEVENLABS_API_KEY", "").strip()
    if not key:
        parser.error("Set ELEVENLABS_API_KEY privately before generating previews")
    args.output_dir.mkdir(parents=True, exist_ok=True)
    for role in DESCRIPTIONS if args.all else [args.role]:
        description = DESCRIPTIONS[role]
        text = TAUREN_TEXT if role.startswith("tauren") else FORSAKEN_TEXT if role.startswith("forsaken") else ORC_TEXT if role.startswith("orc") else TROLL_TEXT
        out = args.output_dir / role
        out.mkdir(exist_ok=True)
        manifest = out / "auditions.json"
        if manifest.exists():
            cached = json.loads(manifest.read_text(encoding="utf-8"))
            if cached.get("description") == description and cached.get("text") == text and len(cached.get("previews", [])) == 3 and all((out / p["file"]).is_file() for p in cached["previews"]):
                print(f"have {role}: three previews", flush=True)
                continue
            raise SystemExit(f"Existing {role} auditions differ; choose a new output directory")
        body = {"model_id": "eleven_ttv_v3", "voice_description": description, "text": text}
        req = urllib.request.Request("https://api.elevenlabs.io/v1/text-to-voice/design?output_format=mp3_44100_128", data=json.dumps(body).encode(), method="POST", headers={"xi-api-key": key, "Content-Type": "application/json"})
        print(f"Designing {role}: three audition options", flush=True)
        try:
            with urllib.request.urlopen(req, timeout=90) as response:
                result = json.load(response)
        except urllib.error.HTTPError as err:
            raise SystemExit(f"Voice design returned HTTP {err.code}: {err.read().decode('utf-8', 'replace')[:400]}") from None
        previews = result.get("previews", [])
        if len(previews) != 3:
            raise SystemExit(f"Expected three previews for {role}; received {len(previews)}")
        saved = []
        for letter, preview in zip("ABC", previews):
            audio = base64.b64decode(preview["audio_base_64"], validate=True)
            if not audio:
                raise SystemExit("Empty audition audio")
            filename = f"{role}-{letter}.mp3"
            (out / filename).write_bytes(audio)
            saved.append({"option": letter, "file": filename, "generated_voice_id": preview["generated_voice_id"], "duration_secs": preview.get("duration_secs"), "media_type": preview.get("media_type")})
        manifest.write_text(json.dumps({"role": role, "model_id": "eleven_ttv_v3", "description": description, "text": result.get("text", text), "status": "awaiting_user_selection", "previews": saved}, indent=2) + "\n", encoding="utf-8")
        print(f"saved {role}: A, B, C", flush=True)


if __name__ == "__main__":
    main()
