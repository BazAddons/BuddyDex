#!/usr/bin/env python3
"""Verify recording never starts with overdue billing or insufficient credits."""
import contextlib
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location(
    'backfill', Path(__file__).resolve().parents[1] / 'voice' / 'backfill.py')
backfill = importlib.util.module_from_spec(spec)
spec.loader.exec_module(backfill)


class BillingGuard(unittest.TestCase):
    def run_guard(self, status, limit, expected):
        job = dict(voice='forsaken-male', source='npc', moment='greet', line=1,
                   text='Hello.', say=None, spoken='[warmly] Hello.')
        balance = dict(status=status, character_count=10, character_limit=limit)
        original_read = Path.read_text

        def read(path, *args, **kwargs):
            if path.name == 'elevenlabs-api-key.txt':
                return 'test-credential-never-sent'
            return original_read(path, *args, **kwargs)

        with tempfile.TemporaryDirectory() as folder:
            with (patch.object(backfill, 'audit', return_value=({}, [job])),
                  patch.object(backfill, 'subscription', return_value=balance),
                  patch.object(backfill.gen, 'record') as record,
                  patch.object(backfill.gen, 'write_lua_manifest'),
                  patch.object(Path, 'read_text', read),
                  patch('sys.argv', ['backfill', '--record', '--state-dir', folder]),
                  contextlib.redirect_stdout(io.StringIO())):
                backfill.main()
                record.assert_not_called()
            state = json.loads(Path(folder, 'progress.json').read_text())
            self.assertEqual(state['status'], expected)
            self.assertEqual(state['made'], 0)
            self.assertEqual(state['credits_used'], 0)
            self.assertEqual(state['remaining'], 1)
            self.assertFalse(Path(folder, 'writer.lock').exists())
            self.assertEqual(len(Path(folder, 'runs.jsonl').read_text().splitlines()), 1)

    def test_overdue_subscription_never_synthesizes(self):
        self.run_guard('past_due', 600000, 'payment_required')

    def test_insufficient_credit_never_synthesizes(self):
        self.run_guard('active', 10, 'credits_exhausted')


if __name__ == '__main__':
    unittest.main()
