#!/usr/bin/env python3
"""Regenerates tools/tests/blizzard_api.lua from the client's exported UI code.

The test mock (mock.lua) uses the generated file to behave like the real
client where a mistake would otherwise only show up in game:

- CreateFrame refuses a template that no always-loaded Blizzard addon
  defines for the Camelot game type ("Couldn't find inherited node"), which
  catches load-on-demand templates such as CollectionsCountTemplate and typos.
- RegisterEvent refuses an event the client does not have.
- A FontString created from an unknown font object has no font, so SetText
  fails with "Font not set", as it does in game.
- SOUNDKIT holds exactly the client's keys.
- The API audit test checks every widget method and global the addon touches
  against the client's documented API.

Run it after a client update (the export path is the first argument, or the
WOW_UI_EXPORT environment variable, or the Forever default):

    .venv/bin/python tools/tests/gen_blizzard_api.py

It needs lupa only to evaluate Blizzard's API documentation tables.
"""
import os
import re
import sys
from pathlib import Path

from lupa.lua51 import LuaRuntime

HERE = Path(__file__).resolve().parent
OUT = HERE / "blizzard_api.lua"
DEFAULT_EXPORT = Path(
    "/Applications/World of Warcraft/_classic_beta_/BlizzardInterfaceCode/Interface/AddOns"
)

# Camelot is a game type inside the mainline family: a file tagged mainline
# loads unless it also excludes camelot, and "standard" means retail only.
GAME_TYPES = {"camelot", "mainline"}
FAMILY_DIR = "Mainline"
GAME_DIR = "Camelot"

TAG_RE = re.compile(r"\[(\w+)\s+([^\]]*)\]")
XML_TAG_RE = re.compile(r"<(\w+)\b([^<>]*?)/?>", re.S)
ATTR_RE = re.compile(r"(\w+)\s*=\s*\"([^\"]*)\"")
LUA_FUNC_RE = re.compile(r"^function\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(", re.M)
LUA_ASSIGN_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)\s*=[^=]", re.M)
LUA_METHOD_RE = re.compile(r"^\s*function\s+([A-Za-z_]\w*)[:.]([A-Za-z_]\w*)\s*\(", re.M)
LUA_FIELD_RE = re.compile(r"^\s*([A-Za-z_]\w*)\.([A-Za-z_]\w*)\s*=[^=]", re.M)
LUA_DERIVE_RE = re.compile(r"^\s*([A-Za-z_]\w*)\s*=\s*CreateFromMixins\(([^)]*)\)", re.M)
LUA_MIXIN_RE = re.compile(r"^\s*Mixin\(\s*([A-Za-z_]\w*)\s*,([^)]*)\)", re.M)

# Templates the mock models (mock.lua TEMPLATE_BUILDERS). For these the
# generator lists every method their Blizzard mixins define, so the mock can
# answer a real method it does not model with a harmless no-op, while a
# method no mixin defines stays nil and fails the way it would in game.
MODELED_TEMPLATES = [
    "PortraitFrameTemplate", "PortraitFrameTemplateNoCloseButton", "ButtonFrameTemplate",
    "DefaultPanelTemplate", "InsetFrameTemplate", "InsetFrameTemplate2", "InsetFrameTemplate3",
    "InsetFrameTemplate4", "ShadowOverlayTemplate", "BackdropTemplate", "SearchBoxTemplate",
    "InputBoxTemplate", "InputBoxInstructionsTemplate", "WowStyle1FilterDropdownTemplate",
    "WowStyle1DropdownTemplate", "WowScrollBoxList", "MinimalScrollBar", "WowTrimScrollBar",
    "PanelTabButtonTemplate", "PanelDragBarTemplate", "ClickToDragTemplate",
    "UIPanelButtonTemplate", "UIPanelButtonNoTooltipTemplate", "MagicButtonTemplate",
    "UIPanelCloseButton", "UIPanelCloseButtonDefaultAnchors", "UIResetButtonTemplate",
    "UICheckButtonTemplate", "CheckboxWithLabelTemplate", "MinimalCheckboxTemplate",
    "SharedButtonSmallTemplate", "NewFeatureLabelTemplate", "NewFeatureLabelNoAnimateTemplate",
    "CollectionsBackgroundTemplate", "ColoredProgressBarTemplate", "LargeSideTabButtonTemplate",
    "TabSystemTemplate", "TabSystemOwnerTemplate", "GameTooltipTemplate",
    "ModelSceneMixinTemplate", "PanningModelSceneMixinTemplate", "ModelSceneControlFrameTemplate",
    "ModelTemplate", "ModelWithZoomTemplate", "ModelWithControlsTemplate",
]


def split_values(args):
    return {v for v in re.split(r"[,\s]+", args.strip().lower()) if v}


def tags_allow(tags):
    """True when a TOC line's (or header's) tags let it load for Camelot in game."""
    for name, args in tags:
        name = name.lower()
        values = split_values(args)
        if name == "allowloadgametype" and not (values & GAME_TYPES):
            return False
        if name == "excludeloadgametype" and (values & GAME_TYPES):
            return False
        if name == "allowload" and not (values & {"game", "both"}):
            return False
        if name == "allowloadtextlocale" and "enus" not in values:
            return False
    return True


def parse_toc(path):
    header, files = {}, []
    for raw in path.read_text(errors="replace").splitlines():
        line = raw.strip()
        if not line:
            continue
        if line.startswith("##"):
            m = re.match(r"##\s*([^:]+):\s*(.*)$", line)
            if m:
                key = m.group(1).strip().lower()
                header.setdefault(key, []).append(m.group(2).strip())
            continue
        if line.startswith("#"):
            continue
        tags = TAG_RE.findall(line)
        name = TAG_RE.sub("", line).strip()
        files.append((name, tags))
    return header, files


def addon_loads(header):
    def first(key):
        return (header.get(key) or [""])[0].lower()

    if first("loadondemand") in ("1", "true"):
        return False
    if header.get("loadwith"):
        return False
    allow = first("allowload")
    if allow and allow not in ("both", "game"):
        return False
    for value in header.get("allowloadgametype", []):
        if not (split_values(value) & GAME_TYPES):
            return False
    for value in header.get("excludeloadgametype", []):
        if split_values(value) & GAME_TYPES:
            return False
    return True


def resolve(base, relative):
    rel = relative.replace("[Family]", FAMILY_DIR).replace("[Game]", GAME_DIR)
    path = base
    for part in re.split(r"[\\/]", rel):
        if part in ("", "."):
            continue
        if part == "..":
            path = path.parent
            continue
        path = path / part
    return path


class Collector:
    def __init__(self, root):
        self.root = root
        self.templates = {}
        self.intrinsics = {}
        self.template_info = {}      # name -> (element, [mixins], [inherits])
        self.mixin_methods = {}      # mixin -> set of method names
        self.mixin_parents = {}      # mixin -> [mixins it was built from]
        self.fonts = set()
        self.lua_globals = set()
        self.seen = set()
        self.loaded_addons = []

    def load_file(self, path):
        key = str(path).lower()
        if key in self.seen or not path.is_file():
            return
        self.seen.add(key)
        if path.suffix.lower() == ".lua":
            self.scan_lua(path)
        elif path.suffix.lower() == ".xml":
            self.scan_xml(path)

    def scan_lua(self, path):
        text = path.read_text(errors="replace")
        self.lua_globals.update(LUA_FUNC_RE.findall(text))
        for name in LUA_ASSIGN_RE.findall(text):
            if name not in ("local", "return", "end", "if", "for", "while"):
                self.lua_globals.add(name)
        for owner, method in LUA_METHOD_RE.findall(text) + LUA_FIELD_RE.findall(text):
            self.mixin_methods.setdefault(owner, set()).add(method)
        for owner, parents in LUA_DERIVE_RE.findall(text) + LUA_MIXIN_RE.findall(text):
            names = [p.strip() for p in parents.split(",") if re.match(r"^\s*[A-Za-z_]\w*\s*$", p)]
            self.mixin_parents.setdefault(owner, []).extend(names)

    def scan_xml(self, path):
        text = path.read_text(errors="replace")
        text = re.sub(r"<!--.*?-->", "", text, flags=re.S)
        for tag, attr_text in XML_TAG_RE.findall(text):
            attrs = dict(ATTR_RE.findall(attr_text))
            lowered = tag.lower()
            if lowered in ("include", "script") and attrs.get("file"):
                self.load_file(resolve(path.parent, attrs["file"]))
                continue
            name = attrs.get("name")
            if not name:
                continue
            if lowered in ("font", "fontfamily"):
                self.fonts.add(name)
            def listed(key):
                return [v.strip() for v in attrs.get(key, "").split(",") if v.strip()]

            if attrs.get("intrinsic") == "true":
                self.intrinsics[name] = tag
                self.template_info[name] = (tag, listed("mixin") + listed("secureMixin"), listed("inherits"))
            elif attrs.get("virtual") == "true":
                self.templates[name] = tag
                self.template_info[name] = (tag, listed("mixin") + listed("secureMixin"), listed("inherits"))

    def mixin_closure(self, mixin, seen=None):
        seen = seen if seen is not None else set()
        if mixin in seen:
            return set()
        seen.add(mixin)
        methods = set(self.mixin_methods.get(mixin, ()))
        for parent in self.mixin_parents.get(mixin, ()):
            methods |= self.mixin_closure(parent, seen)
        return methods

    def template_methods(self, name, seen=None):
        """Every method the template's mixins (and inherited templates') define."""
        seen = seen if seen is not None else set()
        if name in seen or name not in self.template_info:
            return set()
        seen.add(name)
        element, mixins, inherits = self.template_info[name]
        methods = set()
        for mixin in mixins:
            methods |= self.mixin_closure(mixin)
        for parent in inherits:
            methods |= self.template_methods(parent, seen)
        if element in self.intrinsics:
            methods |= self.template_methods(element, seen)
        return {m for m in methods if re.match(r"^[A-Z]", m)}

    def run(self):
        for toc in sorted(self.root.glob("*/*.toc")):
            addon_dir = toc.parent
            if toc.stem.lower() != addon_dir.name.lower():
                continue
            header, files = parse_toc(toc)
            if not addon_loads(header):
                continue
            self.loaded_addons.append(addon_dir.name)
            for name, tags in files:
                if tags_allow(tags):
                    self.load_file(resolve(addon_dir, name))


def read_api_docs(root):
    """Evaluates every API documentation table with stubbed globals."""
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(
        """
        DOCS = {}
        local auto = {}
        auto.__index = function(t, k) local v = setmetatable({}, auto); rawset(t, k, v); return v end
        -- Some documentation files do arithmetic on constants at load time.
        local function zero() return 0 end
        auto.__add, auto.__sub, auto.__mul, auto.__div, auto.__unm = zero, zero, zero, zero, zero
        auto.__concat = function() return "" end
        Enum = setmetatable({}, auto)
        Constants = setmetatable({}, auto)
        APIDocumentation = { AddDocumentationTable = function(_, t) DOCS[#DOCS + 1] = t end }
        """
    )
    for path in sorted((root / "Blizzard_APIDocumentationGenerated").glob("*.lua")):
        try:
            lua.execute(path.read_text(errors="replace"))
        except Exception as exc:  # a broken doc file should not stop the rest
            print(f"warning: {path.name}: {exc}", file=sys.stderr)

    widget, globals_, namespaces, events = set(), set(), {}, set()
    docs = lua.globals().DOCS
    for i in range(1, len(docs) + 1):
        doc = docs[i]
        kind = doc["Type"]
        functions = doc["Functions"]
        names = []
        if functions is not None:
            for j in range(1, len(functions) + 1):
                fn = functions[j]
                if fn["Name"]:
                    names.append(fn["Name"])
        if kind == "ScriptObject":
            widget.update(names)
        elif kind == "System":
            ns = doc["Namespace"]
            if ns:
                namespaces.setdefault(ns, set()).update(names)
            else:
                globals_.update(names)
            evs = doc["Events"]
            if evs is not None:
                for j in range(1, len(evs) + 1):
                    if evs[j]["LiteralName"]:
                        events.add(evs[j]["LiteralName"])
    return widget, globals_, namespaces, events


def read_soundkit(root):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute((root / "Blizzard_SharedXML" / FAMILY_DIR / "SoundKitConstants.lua").read_text())
    kit = lua.globals().SOUNDKIT
    return {k: int(v) for k, v in kit.items() if isinstance(v, (int, float))}


def wrap_words(words, indent, width=100):
    lines, current = [], indent
    for word in words:
        if len(current) + len(word) + 1 > width and current.strip():
            lines.append(current.rstrip())
            current = indent
        current += word + " "
    if current.strip():
        lines.append(current.rstrip())
    return lines


def lua_words(name, words, indent="    "):
    """A set or map packed as whitespace-separated words in a long string.

    Packing keeps the file a fraction of the size of one table entry per
    line; the loader at the end of the generated file unpacks it.
    """
    return [f"{indent}{name} = [[", *wrap_words(sorted(words), indent + "    "), f"{indent}]],"]


def main():
    root = Path(sys.argv[1] if len(sys.argv) > 1 else os.environ.get("WOW_UI_EXPORT", DEFAULT_EXPORT))
    if not root.is_dir():
        sys.exit(f"no exported UI code at {root}")

    collector = Collector(root)
    collector.run()
    widget, api_globals, namespaces, events = read_api_docs(root)
    soundkit = read_soundkit(root)

    namespaced = [f"{ns}.{fn}" for ns, fns in namespaces.items() for fn in fns]
    out = [
        "-- Generated by tools/tests/gen_blizzard_api.py from the WoW: Forever client's",
        "-- exported UI code (Camelot game type, always-loaded Blizzard addons only).",
        "-- Do not edit by hand; rerun the generator after a client update.",
        "--",
        "-- Sets are packed as words; maps as key=value words. The loader at the",
        "-- bottom turns them into BLIZZARD.<name>[key] lookups.",
        "local RAW = {",
    ]
    out += lua_words("widgetMethods", widget)
    out += lua_words("templates", [f"{k}={v}" for k, v in collector.templates.items()])
    out += lua_words("intrinsics", [f"{k}={v}" for k, v in collector.intrinsics.items()])
    out += lua_words("fonts", collector.fonts)
    out += lua_words("events", events)
    out += lua_words("apiGlobals", api_globals)
    out += lua_words("apiNamespaced", namespaced)
    out += lua_words("luaGlobals", collector.lua_globals)
    out += lua_words("soundkit", [f"{k}={v}" for k, v in soundkit.items()])
    out.append("    templateMethods = [[")
    for name in MODELED_TEMPLATES:
        if name not in collector.templates:
            sys.exit(f"modeled template {name} is not defined by any always-loaded addon")
        methods = sorted(collector.template_methods(name))
        out += wrap_words([f"{name}=" + ",".join(methods)], "        ", width=10**6)
    out.append("    ]],")
    out += [
        "}",
        "",
        "BLIZZARD = {}",
        "for name, words in pairs(RAW) do",
        "    if name == \"templateMethods\" then",
        "        -- Template=Method,Method words; parsed below.",
        "        BLIZZARD[name] = words",
        "    else",
        "    local set = {}",
        "    for word in words:gmatch(\"%S+\") do",
        "        local key, value = word:match(\"^([^=]+)=(.+)$\")",
        "        if key then",
        "            set[key] = tonumber(value) or value",
        "        else",
        "            set[word] = true",
        "        end",
        "    end",
        "    BLIZZARD[name] = set",
        "    end",
        "end",
        "",
        "-- templateMethods.PortraitFrameTemplate.SetTitle = true, from comma lists.",
        "do",
        "    local packed = BLIZZARD.templateMethods",
        "    BLIZZARD.templateMethods = {}",
        "    for word in packed:gmatch(\"%S+\") do",
        "        local name, list = word:match(\"^([^=]+)=(.*)$\")",
        "        local set = {}",
        "        for method in list:gmatch(\"[^,]+\") do set[method] = true end",
        "        BLIZZARD.templateMethods[name] = set",
        "    end",
        "end",
        "",
        "-- apiNamespaces.C_CVar.GetCVar = true, from the C_CVar.GetCVar words.",
        "BLIZZARD.apiNamespaces = {}",
        "for word in pairs(BLIZZARD.apiNamespaced) do",
        "    local ns, fn = word:match(\"^([^.]+)%.(.+)$\")",
        "    BLIZZARD.apiNamespaces[ns] = BLIZZARD.apiNamespaces[ns] or {}",
        "    BLIZZARD.apiNamespaces[ns][fn] = true",
        "end",
    ]
    OUT.write_text("\n".join(out) + "\n")

    print(f"loaded addons: {len(collector.loaded_addons)}")
    print(f"templates: {len(collector.templates)}, intrinsics: {len(collector.intrinsics)}, fonts: {len(collector.fonts)}")
    print(f"widget methods: {len(widget)}, api globals: {len(api_globals)}, namespaces: {len(namespaces)}, events: {len(events)}")
    print(f"lua globals: {len(collector.lua_globals)}, soundkit: {len(soundkit)}")
    print(f"wrote {OUT} ({OUT.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()
