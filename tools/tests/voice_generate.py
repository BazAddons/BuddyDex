"""Offline regression checks for recording requests and emotion-aware caching."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import numpy as np

spec = importlib.util.spec_from_file_location("voice_generate", Path(__file__).resolve().parents[1] / "voice/generate.py")
gen = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gen)


class RecordingTests(unittest.TestCase):
    def test_v4_dialogue_and_v3_compatibility(self):
        pcm = (np.sin(np.arange(22050) * .1) * 4000).astype("<i2").tobytes()
        with tempfile.TemporaryDirectory() as folder:
            for model in ("eleven_v4", "eleven_v3"):
                with patch.object(gen.urllib.request, "urlopen") as request:
                    request.return_value.__enter__.return_value.read.return_value = pcm
                    out = str(Path(folder) / (model + ".ogg"))
                    gen.record("test-key", "selected-voice", "[warmly] Hello.", out, model)
                    sent = request.call_args.args[0]
                    payload = json.loads(sent.data)
                    self.assertEqual(payload["model_id"], model)
                    if model == "eleven_v4":
                        self.assertIn("/text-to-dialogue?", sent.full_url)
                        self.assertEqual(payload["inputs"], [{"text": "[warmly] Hello.", "voice_id": "selected-voice"}])
                    else:
                        self.assertIn("/text-to-speech/selected-voice?", sent.full_url)
                    self.assertTrue(Path(out).read_bytes().startswith(b"OggS"))

    def test_emotion_or_voice_changes_invalidate_cache(self):
        def fake_record(key, voice, text, path, model):
            Path(path).write_bytes(b"test-audio")
            return 10

        with tempfile.TemporaryDirectory() as folder, \
             patch.object(gen, "ROOT", folder), \
             patch.object(gen, "api_key", return_value="test-key"), \
             patch.object(gen, "write_lua_manifest"), \
             patch.object(gen, "record", side_effect=fake_record) as recording, \
             patch.object(gen, "load_lines", return_value={"greet": [("Welcome, friend.", "[warmly]", None)]}) as lines, \
             patch.object(gen.sys, "argv", ["generate.py", "--voice", "orc-male", "--lore", "3310", "greet:1"]):
            gen.main()
            gen.main()
            self.assertEqual(recording.call_count, 1, "unchanged clip should be reused")
            lines.return_value = {"greet": [("Welcome, friend.", "[amused]", None)]}
            gen.main()
            self.assertEqual(recording.call_count, 2, "emotion edit must generate new delivery")
            self.assertEqual(recording.call_args.args[2], "[amused] Welcome, friend.")
            with patch.dict(gen.VOICES, {"orc-male": "new-approved-voice"}):
                gen.main()
            self.assertEqual(recording.call_count, 3, "voice edit must invalidate old recording")


if __name__ == "__main__":
    unittest.main()
