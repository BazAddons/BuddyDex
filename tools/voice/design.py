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
    "orc-male": "An original fantasy orc man, middle aged. Very deep resonant chest voice, broad baritone with a gravelly edge and weight behind each word. Neutral American English, strong clear consonants, a slightly tusked resonance, natural breath and texture. A seasoned warrior who can be warmly welcoming, dryly amused or firmly commanding. Controlled power, never constant shouting. Conversational pacing, good emotional range, intelligible speech, clean studio recording without effects, music or background noise. Not an imitation of any actor or existing character.",
    "orc-female": "An original fantasy orc woman, mature adult. A low, full alto with a husky smoky grain, strong chest resonance and crisp intelligible consonants. Neutral American English with a slight tusked resonance. She sounds capable, grounded and warm, with a dry sense of humor and authority when needed. A believable person who can welcome a traveler, tease a friend or issue a warning; neither a screeching monster nor a breathy young heroine. Natural conversational pacing and expressive range. Clean studio speech without processing or background sound. Not an imitation of any actor or existing character.",
    "troll-male": "An original fantasy troll man, adult. A medium-low, lean resonant voice with a lightly nasal edge and a natural smoky rasp. A relaxed Caribbean-inspired English accent and musical rhythm, clear diction and gently stretched vowels, not exaggerated or cartoonish. Easygoing warmth and playful confidence that can become watchful and serious. He should sound like an experienced traveler and helpful companion, with varied natural intonation and subtle humor, not a sinister villain or a whispered narrator. Clean studio recording with no effects or background sound. Not an imitation of any actor or existing character.",
    "troll-female": "An original fantasy troll woman, adult. A rich medium-low contralto, lightly husky and nasal, with lively musical inflection. A relaxed Caribbean-inspired English accent with clear words and a lilting rhythm, never exaggerated or cartoonish. Warm, perceptive and lightly mischievous, able to turn calm advice into a firm warning. Strong personality and emotional range suitable for a friendly traveling companion; not an elderly witch, shrill caricature or breathy whisper. Natural speech at an easy conversational pace, clean studio recording without effects or background noise. Not an imitation of any actor or existing character.",
}
ORC_TEXT = "[warmly] Come in, traveler. There is room by the fire, and you look as though you could use a rest. [amused] You brought all that gear, but forgot your lunch? A warrior should plan ahead. [firmly] Stay close. Watch the road, and we will see each other safely home. [softly] It is good to have a friend along."
TROLL_TEXT = "[warmly] Welcome, traveler. Take a breath. The road will still be there when you are ready. [amused] So many bags, and still you say there is nothing to eat. [serious] Keep your eyes open now. We walk together, and we watch out for each other. [cheerfully] Another adventure, another story to tell when we get home."


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
        text = ORC_TEXT if role.startswith("orc") else TROLL_TEXT
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
