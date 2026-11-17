"""Writes every kit find's game row into src/shared/Finds/Rows.luau (F-G1f, D-265; PIPELINE.md).

Plain Python, no Blender, so a row's numbers change without rebuilding a mesh. It reads each
set's GAME rows (art/finds/<set>/spec.py) and art/finds/WAVES.md's set tables, where a find is
judged once its catalog line is ticked built (its Built cell dated), and writes one generated
Luau module, formatted by StyLua. scripts/art.sh runs it after every set's export and alone
(`scripts/art.sh rows`); scripts/check.sh runs it with --check, which fails if the module is
stale or was edited by hand.

    python3 art/finds/rows.py [--check]
"""

import importlib.util
import math
import os
import re
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
OUT = os.path.join(ROOT, "src", "shared", "Finds", "Rows.luau")
SETS_LUAU = os.path.join(ROOT, "src", "shared", "Finds", "Sets")
WAVES = os.path.join(HERE, "WAVES.md")

# The kit's sets in the order they were built, which is the deal's order (Deal.findFrom picks
# by place within a grade, so a new set goes on the end).
SETS = ["lights", "figures", "windups", "squishies"]

GRADES = ["Common", "Uncommon", "Rare", "Epic", "Legendary", "Secret"]  # Grades.Names
SIZES = ["Small", "Medium", "Large"]
ROW = ["key", "catalog", "name", "grade", "worth", "from_", "loose", "grip", "heft", "size",
       "pickUp", "drop", "verb", "press"]
NEEDED = ["key", "catalog", "name", "grade", "worth", "grip", "heft", "size", "pickUp", "drop"]
PRESS = ["verb", "on", "lasts", "out", "off", "reset", "noise", "heard", "lure", "toy", "down", "walks"]
STEP = ["motion", "loop", "sound", "hit"]
SOUND = ["id", "from", "length", "volume", "pitch"]


def fail(msg):
    sys.exit(f"rows.py: {msg}")


def load(setname):
    """The GAME rows of art/finds/<setname>/spec.py, imported as the build imports it."""
    folder = os.path.join(HERE, setname)
    sys.path.insert(0, os.path.join(HERE, "kit"))
    try:
        spec = importlib.util.spec_from_file_location(f"spec_{setname}", os.path.join(folder, "spec.py"))
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
    finally:
        sys.path.pop(0)
    return getattr(module, "GAME", [])


def ticked():
    """Each catalog line in WAVES.md's tables, and whether it's ticked built (a dated last cell,
    "Nov 15, F-02a")."""
    lines = {}
    for line in open(WAVES, encoding="utf-8"):
        if not line.startswith("|") or line.startswith("|---"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        filled = [c for c in cells if c]
        if not filled:
            continue
        built = bool(re.match(r"^[A-Z][a-z]{2} \d{1,2}, ", filled[-1]))
        lines[cells[0]] = lines.get(cells[0], False) or built
    return lines


def check_keys(where, table, allowed):
    for k in table:
        if k not in allowed:
            fail(f"{where}: unknown field {k!r} (allowed: {', '.join(allowed)})")


def number(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, float) and math.isinf(v):
        return "math.huge"
    return repr(v)


def lua(v, depth):
    """`v` as a Luau value, `depth` tabs in."""
    pad = "\t" * (depth + 1)
    if isinstance(v, str):
        return '"' + v.replace("\\", "\\\\").replace('"', '\\"') + '"'
    if isinstance(v, (bool, int, float)):
        return number(v)
    if isinstance(v, (list, tuple)):
        if all(isinstance(x, (int, float)) for x in v):
            return "{ " + ", ".join(number(x) for x in v) + " }"
        return "{\n" + "".join(f"{pad}{lua(x, depth + 1)},\n" for x in v) + "\t" * depth + "}"
    if isinstance(v, dict):
        return "{\n" + "".join(f"{pad}{k} = {lua(x, depth + 1)},\n" for k, x in v.items()) + "\t" * depth + "}"
    fail(f"can't write {v!r} as Luau")


def ordered(d, order):
    return {k: d[k] for k in order if k in d and d[k] is not None}


def sound(where, s):
    check_keys(where, s, SOUND)
    return ordered(s, SOUND)


def step(where, s):
    check_keys(where, s, STEP)
    out = ordered(s, STEP)
    if "sound" in out:
        out["sound"] = sound(where, out["sound"])
    if "hit" in out:
        check_keys(where + ".hit", out["hit"], ["part", "channel", "sound"])
        out["hit"] = ordered({**out["hit"], "sound": sound(where, out["hit"]["sound"])},
                             ["part", "channel", "sound"])
    return out


def press(where, p):
    check_keys(where, p, PRESS)
    out = ordered(p, PRESS)
    for k in ("on", "out"):
        if k in out:
            out[k] = [step(f"{where}.{k}", s) for s in out[k]]
    for k in ("off", "reset"):
        if k in out:
            out[k] = step(f"{where}.{k}", out[k])
    return out


def rows():
    lines = ticked()
    out, seen = [], set()
    for setname in SETS:
        luau_set = setname.capitalize()
        art = open(os.path.join(SETS_LUAU, luau_set + ".luau"), encoding="utf-8").read()
        for g in load(setname):
            key = g.get("key", "?")
            where = f"{setname}/spec.py {key}"
            check_keys(where, g, ROW)
            for k in NEEDED:
                if k not in g:
                    fail(f"{where}: no {k}")
            if key in seen:
                fail(f"{where}: two rows with this key")
            seen.add(key)
            if not re.search(rf"^\t{key} = \{{", art, re.M):
                fail(f"{where}: no art in Finds/Sets/{luau_set}.luau; export the set first")
            if g["catalog"] not in lines:
                fail(f"{where}: catalog line {g['catalog']!r} isn't in WAVES.md's tables")
            if g["grade"] not in GRADES:
                fail(f"{where}: grade {g['grade']!r}")
            if g["size"] not in SIZES:
                fail(f"{where}: size {g['size']!r}")
            p = press(where + ".press", g["press"]) if g.get("press") else None
            if p and g.get("verb"):
                fail(f"{where}: a verb of its own and a press; the press's verb is its word")
            row = {
                "key": key,
                "set": luau_set,
                "judged": lines[g["catalog"]],
                "name": g["name"],
                "grade": g["grade"],
                "worth": g["worth"],
                "from": g.get("from_"),
                "loose": g.get("loose"),
                "grip": list(g["grip"]),
                "heft": g["heft"],
                "size": g["size"],
                "pickUp": sound(where, g["pickUp"]),
                "drop": sound(where, g["drop"]),
                "verb": p["verb"] if p else g.get("verb"),
                "press": p,
            }
            out.append({k: v for k, v in row.items() if v is not None})
    return out


HEADER = """--!strict
-- GENERATED by art/finds/rows.py from each set's GAME rows (art/finds/<set>/spec.py): never edit
-- by hand; change the spec and run `scripts/art.sh rows`. Every kit find's game row (F-G1f,
-- D-265), in the deal's order; `Finds/Game` says what each field is.

local Game = require("./Game")

local Rows: { Game.Row } = """


def stylua():
    found = shutil.which("stylua")
    if found:
        return found
    home = os.path.expanduser("~/.rokit/bin/stylua")
    if os.path.exists(home):
        return home
    fail("no stylua (rokit installs it: rokit install)")


def text():
    raw = HEADER + lua(rows(), 0) + "\n\nreturn Rows\n"
    done = subprocess.run([stylua(), "--stdin-filepath", OUT, "-"], input=raw, capture_output=True,
                          text=True, cwd=ROOT)
    if done.returncode != 0:
        fail("stylua: " + done.stderr.strip())
    return done.stdout


def main():
    new = text()
    old = open(OUT, encoding="utf-8").read() if os.path.exists(OUT) else ""
    if "--check" in sys.argv:
        if new != old:
            fail("src/shared/Finds/Rows.luau is stale or edited by hand: run scripts/art.sh rows")
        return
    if new != old:
        with open(OUT, "w", encoding="utf-8") as f:
            f.write(new)
    judged = new.count("judged = true")
    print(f"ROWS {new.count('key = ')} finds, {judged} judged -> src/shared/Finds/Rows.luau")


if __name__ == "__main__":
    main()
