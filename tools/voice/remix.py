#!/usr/bin/env python3
"""Save a selected designed base and generate separate Voice Remix previews.

Output stays outside the release tree. A remix is not official until selected.
"""
import argparse
import base64
import json
import os
from pathlib import Path
import urllib.error
import urllib.request


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-dir", type=Path, required=True)
    parser.add_argument("--option", choices=list("ABC"), required=True)
    parser.add_argument("--base-name", required=True)
    parser.add_argument("--description", required=True, help="Changes to make to the base voice")
    parser.add_argument("--prompt-strength", type=float, default=0.35)
    parser.add_argument("--guidance-scale", type=float, default=5)
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()
    if not (5 <= len(args.description) <= 1000 and 0 <= args.prompt_strength <= 1
            and 0 <= args.guidance_scale <= 100):
        parser.error("Invalid description length or remix strength/guidance")
    key = os.environ.get("ELEVENLABS_API_KEY", "").strip()
    if not key:
        parser.error("Set ELEVENLABS_API_KEY privately")

    def call(route, body=None):
        request = urllib.request.Request(
            "https://api.elevenlabs.io" + route,
            data=json.dumps(body).encode() if body is not None else None,
            method="POST" if body is not None else "GET",
            headers={"xi-api-key": key, "Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(request, timeout=90) as response:
                return json.load(response)
        except urllib.error.HTTPError as err:
            try:
                detail = json.loads(err.read()).get("detail", {})
                message = detail.get("message", "") if isinstance(detail, dict) else ""
            except (ValueError, AttributeError):
                message = ""
            raise SystemExit(f"ElevenLabs HTTP {err.code}: {message[:300]}") from None

    source_path = args.source_dir / "auditions.json"
    source = json.loads(source_path.read_text(encoding="utf-8"))
    selected = next(p for p in source["previews"] if p["option"] == args.option)
    if source.get("base_voice_id"):
        assert source["base_selected_option"] == args.option, "Existing base choice differs"
        voice = call("/v1/voices/" + source["base_voice_id"])
    else:
        matches = [v for v in call("/v1/voices").get("voices", [])
                   if v.get("name") == args.base_name]
        assert len(matches) <= 1, "Ambiguous saved base name"
        if matches:
            voice = matches[0]
            assert voice.get("description") == source["description"], "Saved base differs"
        else:
            voice = call("/v1/text-to-voice", {
                "voice_name": args.base_name,
                "voice_description": source["description"],
                "generated_voice_id": selected["generated_voice_id"]})
        assert voice.get("voice_id") and voice.get("name") == args.base_name
        source.update(status="selected_as_remix_base", base_selected_option=args.option,
                      base_voice_id=voice["voice_id"], base_voice_name=args.base_name)
        source_path.write_text(json.dumps(source, indent=2) + "\n", encoding="utf-8")
    verified = call("/v1/voices/" + voice["voice_id"])
    assert verified["voice_id"] == voice["voice_id"] and verified["name"] == args.base_name
    print(f"Verified base {source['role']} {args.option}: {voice['voice_id']}", flush=True)

    out = args.output_dir / source["role"]
    out.mkdir(parents=True, exist_ok=True)
    manifest = out / "auditions.json"
    settings = {
        "role": source["role"], "operation": "voice_remix",
        "base_voice_id": voice["voice_id"], "source_option": args.option,
        "source_manifest": str(source_path.resolve()),
        "description": args.description, "text": source["text"],
        "prompt_strength": args.prompt_strength, "guidance_scale": args.guidance_scale}
    if manifest.exists():
        cached = json.loads(manifest.read_text(encoding="utf-8"))
        if (all(cached.get(k) == v for k, v in settings.items())
                and len(cached.get("previews", [])) == 3
                and all((out / p["file"]).is_file() for p in cached["previews"])):
            print(f"have {source['role']}: three remix previews", flush=True)
            return
        raise SystemExit("Existing remix differs; choose a new output directory")

    route = f"/v1/text-to-voice/{voice['voice_id']}/remix?output_format=mp3_44100_128"
    print(f"Remixing {source['role']}: accent-only previews", flush=True)
    result = call(route, {"voice_description": args.description, "text": source["text"],
                          "prompt_strength": args.prompt_strength,
                          "guidance_scale": args.guidance_scale})
    previews = result.get("previews", [])
    assert len(previews) == 3, f"Expected three previews, received {len(previews)}"
    saved = []
    for letter, preview in zip("ABC", previews):
        audio = base64.b64decode(preview["audio_base_64"], validate=True)
        assert audio, "Empty remix audio"
        filename = f"{source['role']}-{letter}.mp3"
        (out / filename).write_bytes(audio)
        saved.append({"option": letter, "file": filename,
                      "generated_voice_id": preview["generated_voice_id"],
                      "duration_secs": preview.get("duration_secs"),
                      "media_type": preview.get("media_type")})
    settings.update(text=result.get("text", source["text"]),
                    status="awaiting_user_selection", previews=saved)
    manifest.write_text(json.dumps(settings, indent=2) + "\n", encoding="utf-8")
    print(f"saved {source['role']}: A, B, C remix files", flush=True)


if __name__ == "__main__":
    main()
