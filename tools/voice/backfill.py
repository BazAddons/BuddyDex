#!/usr/bin/env python3
"""Resume missing exact-text recordings without replacing valid older models.

One writer only. API credentials and billing responses never enter the repository.
Default is audit-only; --record explicitly spends the available API credit balance.
"""
import argparse
import functools
import importlib.util
import json
import os
from pathlib import Path
import re
import time
import urllib.request
import zlib

import numpy as np
import soundfile as sf

spec = importlib.util.spec_from_file_location('voice_generate', Path(__file__).with_name('generate.py'))
gen = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gen)
gen.load_lines = functools.lru_cache(None)(gen.load_lines)
ROOT = Path(gen.ROOT)


def save(path, data):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + '.tmp')
    temporary.write_text(json.dumps(data, indent=2, sort_keys=True), encoding='utf-8')
    os.replace(temporary, path)


def subscription(key):
    req = urllib.request.Request('https://api.elevenlabs.io/v1/user/subscription',
                                 headers={'xi-api-key': key})
    with urllib.request.urlopen(req, timeout=30) as response:
        data = json.load(response)
    return {k: data.get(k) for k in ('character_count', 'character_limit',
                                    'next_character_count_reset_unix')}


def audible(path):
    try:
        audio, rate = sf.read(path, dtype='float32')
        return (rate == 22050 and audio.ndim == 1 and len(audio) > rate // 10
                and np.isfinite(audio).all() and float(np.max(np.abs(audio))) > .001)
    except (RuntimeError, ValueError, OSError):
        return False


def audit():
    manifests, valid, owners = {}, {}, {}
    for voice in gen.VOICES:
        path = ROOT / 'voice' / voice / 'manifest.json'
        manifests[voice] = json.loads(path.read_text()) if path.exists() else {}
        valid[voice] = set()
        for name, entry in manifests[voice].items():
            source = entry.get('source', 'mini')
            if source.startswith('lore:'):
                owners.setdefault(source, set()).add(voice)
            pile = gen.load_lines(source).get(entry['moment'], [])
            index = entry['line'] - 1
            if (0 <= index < len(pile) and pile[index][0] == entry['text']
                    and entry.get('voice_id', gen.VOICES[voice]) == gen.VOICES[voice]
                    and audible(ROOT / 'voice' / voice / name)):
                valid[voice].add(entry['text'])
    lua = gen.LuaRuntime(unpack_returned_tuples=True)
    lua.execute('NS = {}')
    lua.execute("assert(loadfile([[%s]]))('BuddyDex', NS)" % (ROOT / 'Data' / 'Lore.lua'))
    sources = ['lore:' + str(n) for n in sorted(lua.eval('NS.Lore').keys())]
    unresolved = [s for s in sources if len(owners.get(s, ())) != 1]
    if unresolved:
        raise RuntimeError('Unresolved profile voice groups: ' + ', '.join(unresolved))
    order = ['forsaken-male', 'forsaken-female'] + [v for v in gen.VOICES if not v.startswith('forsaken-')]
    requests = [(v, 'npc') for v in order]
    requests += [(next(iter(owners[s])), s) for s in sources]
    requests += [('male', 'mini'), ('female', 'mini')]
    queued, seen = [], set()
    for voice, source in requests:
        for moment, pile in sorted(gen.load_lines(source).items()):
            for number, (text, tone, say) in enumerate(pile, 1):
                pair = (voice, text)
                if text in valid[voice] or pair in seen:
                    continue
                spoken = say or text
                if re.search(r'\{\w+\}', spoken):
                    raise RuntimeError(f'Unresolved spoken placeholder: {voice}/{source}/{moment}:{number}')
                tone = tone or gen.TONES.get(moment)
                if isinstance(tone, list):
                    tone = tone[zlib.crc32(text.encode()) % len(tone)]
                if tone:
                    spoken = f'{tone} {spoken}'
                queued.append(dict(voice=voice, source=source, moment=moment, line=number,
                                   text=text, say=say, spoken=spoken))
                seen.add(pair)
    return manifests, queued


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--record', action='store_true')
    parser.add_argument('--state-dir', type=Path, required=True)
    parser.add_argument('--max-clips', type=int, default=0)
    args = parser.parse_args()
    args.state_dir.mkdir(parents=True, exist_ok=True)
    # Fail immediately rather than racing another manifest writer. A leftover lock
    # requires checking the process before removal, never automatic restart.
    lock = args.state_dir / 'writer.lock'
    with lock.open('x') as handle:
        handle.write(str(os.getpid()))
    try:
        manifests, queue = audit()
        save(args.state_dir / 'queue.json', queue)
        counts = {}
        for job in queue:
            group = job['voice'] + ('/shared' if job['source'] == 'npc' else '/personal' if job['source'].startswith('lore:') else '/mini')
            counts[group] = counts.get(group, 0) + 1
        print(json.dumps(dict(missing=len(queue), characters=sum(len(j['spoken']) for j in queue), groups=counts)), flush=True)
        if not args.record:
            return
        key = Path.home().joinpath('.config/BuddyDex/elevenlabs-api-key.txt').read_text().strip()
        initial = subscription(key)
        state = dict(started=time.time(), initial=initial, made=0, characters_sent=0,
                     remaining=len(queue), status='recording')
        save(args.state_dir / 'progress.json', state)
        try:
            for job in queue:
                if args.max_clips and state['made'] >= args.max_clips:
                    state['status'] = 'batch_limit'
                    break
                if state['made'] % 20 == 0:
                    balance = subscription(key)
                # Keep an estimated balance between checks; never enable overages.
                if balance['character_limit'] - balance['character_count'] < len(job['spoken']):
                    balance = subscription(key)
                    if balance['character_limit'] - balance['character_count'] < len(job['spoken']):
                        state['status'] = 'credits_exhausted'
                        break
                voice = job['voice']
                name = f"{gen.source_of(job['source'])[2]}{job['moment']}_{job['line']}.ogg"
                path = ROOT / 'voice' / voice / name
                path.parent.mkdir(parents=True, exist_ok=True)
                pending = path.with_suffix('.pending.ogg')
                try:
                    gen.record(key, gen.VOICES[voice], job['spoken'], str(pending), 'eleven_v4')
                    if not audible(pending):
                        raise RuntimeError(f'Invalid generated audio: {voice}/{name}')
                    duration = sf.info(pending).duration
                    if duration > 25:
                        raise RuntimeError(f'Overlong generated audio ({duration:.1f}s): {voice}/{name}')
                    os.replace(pending, path)
                finally:
                    if pending.exists():
                        pending.unlink()
                entry = {k: job[k] for k in ('source', 'moment', 'line', 'text', 'say', 'spoken')}
                entry.update(model='eleven_v4', voice_id=gen.VOICES[voice])
                manifests[voice][name] = entry
                save(path.parent / 'manifest.json', manifests[voice])
                state['made'] += 1
                state['characters_sent'] += len(job['spoken'])
                state['remaining'] -= 1
                balance['character_count'] += len(job['spoken'])
                save(args.state_dir / 'progress.json', state)
                print(f"made {state['made']}/{len(queue)} {voice}/{name} {duration:.1f}s", flush=True)
                if state['made'] % 100 == 0:
                    gen.write_lua_manifest()
            else:
                state['status'] = 'finished'
        except BaseException as error:
            detail = str(error).lower()
            if 'payment_issue' in detail:
                state['status'] = 'payment_required'
            elif 'quota_exceeded' in detail or 'insufficient_credits' in detail:
                state['status'] = 'credits_exhausted'
            else:
                state['status'] = 'interrupted'
            state['error_type'] = type(error).__name__
            raise
        finally:
            gen.write_lua_manifest()
            state['ended'] = time.time()
            try:
                state['final'] = subscription(key)
                state['credits_used'] = state['final']['character_count'] - initial['character_count']
            finally:
                save(args.state_dir / 'progress.json', state)
                with (args.state_dir / 'runs.jsonl').open('a', encoding='utf-8') as ledger:
                    ledger.write(json.dumps(state, sort_keys=True) + '\n')
    finally:
        lock.unlink()


if __name__ == '__main__':
    main()
