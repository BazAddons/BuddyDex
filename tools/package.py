#!/usr/bin/env python3
"""Build and verify the CurseForge ZIP; optionally update an installed addon.

python tools/package.py --output-dir C:/Users/brett/BuddyDex-builds \
    --install-dir "C:/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns/BuddyDex"
Honors .pkgmeta exclusions. Copies release files only; never touches saved variables.
"""
import argparse
import fnmatch
import hashlib
from pathlib import Path
import re
import shutil
import zipfile

from lupa.lua51 import LuaRuntime
import yaml

ROOT = Path(__file__).resolve().parents[1]


def digest(path):
    return hashlib.sha256(path.read_bytes()).digest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--install-dir", type=Path)
    args = parser.parse_args()
    config = yaml.safe_load((ROOT / ".pkgmeta").read_text())
    package = config["package-as"]
    assert package == "BuddyDex"
    toc = (ROOT / "BuddyDex.toc").read_text()
    version = re.search(r"^## Version: ([\w.-]+)$", toc, re.M)[1]
    assert re.search(r"^## Interface: \d+$", toc, re.M)
    files = []
    for path in ROOT.rglob("*"):
        if not path.is_file():
            continue
        rel = path.relative_to(ROOT).as_posix()
        if any(rel == x or rel.startswith(x + "/") or fnmatch.fnmatchcase(rel, x) for x in config["ignore"]):
            continue
        assert path.suffix not in (".pyc", ".tmp"), rel
        files.append((path, rel))
    args.output_dir.mkdir(parents=True, exist_ok=True)
    archive = args.output_dir / f"BuddyDex-v{version}.zip"
    with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as bundle:
        for path, rel in files:
            bundle.write(path, package + "/" + rel)
    with zipfile.ZipFile(archive) as bundle:
        assert bundle.testzip() is None, "ZIP CRC failure"
        names = set(bundle.namelist())
        assert {name.split("/")[0] for name in names} == {package}
        assert [name for name in names if name.endswith(".toc")] == ["BuddyDex/BuddyDex.toc"]
        assert "BuddyDex/LICENSE" in names
        assert not any("/tools/" in name or "/docs/" in name or "/.git/" in name or name.endswith("manifest.json") for name in names)
        for line in toc.splitlines():
            if line.strip() and not line.startswith("#"):
                assert package + "/" + line.replace("\\", "/") in names, line
        for path, rel in files:
            assert hashlib.sha256(bundle.read(package + "/" + rel)).digest() == digest(path), rel
        lua = LuaRuntime(unpack_returned_tuples=True)
        ns = lua.table()
        lua.execute(bundle.read("BuddyDex/voice/Manifest.lua").decode(), package, ns)
        mappings = 0
        for _, voice in ns.VoicePack.voices.items():
            for _, rel in voice.items():
                assert package + "/voice/" + rel.replace("\\", "/") in names, rel
                mappings += 1
    changed = 0
    if args.install_dir:
        assert args.install_dir.name == package, "Install target must be the BuddyDex addon folder"
        for path, rel in files:
            target = args.install_dir / rel
            if not target.exists() or digest(target) != digest(path):
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(path, target)
                changed += 1
            assert digest(target) == digest(path), rel
        print(f"Installed and verified {len(files)} release files; {changed} updated")
    changelog = args.output_dir / f"BuddyDex-v{version}-changelog.md"
    shutil.copy2(ROOT / config["manual-changelog"]["filename"], changelog)
    print(f"Verified {archive}: {len(files)} files, {mappings} audio mappings, {archive.stat().st_size / 1048576:.2f} MiB")


if __name__ == "__main__":
    main()
