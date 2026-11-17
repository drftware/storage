"""Bake the home's texture sets, headless (art/home/README.md).

    blender -b --factory-startup -P art/home/build.py -- --stage textures

Writes art/home/out/textures/<Set>_{Color,Normal,Roughness,Metalness}.png with the unit's bake
(art/unit/bake.py), from the recipes in looks.py. The ground floor wears them (art/lobby).
"""

import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "unit"))
sys.path.insert(0, HERE)

import bpy  # noqa: E402

import bake  # noqa: E402
import looks  # noqa: E402

TEX = os.path.join(HERE, "out", "textures")


def register():
    """Teach the unit's bake the home's sets: their sizes and which take the part's paint."""
    for name, (_, _, size) in looks.LOOKS.items():
        bake.SIZES[name] = size
    bake.TINTED.update(looks.TINTED)


def stage_textures():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    register()
    for name, (recipe, (w, h), _) in looks.LOOKS.items():
        p = bake.plane(f"bake_{name}", w, h)
        bake.bake_set(name, [(p, bake.Rig(f"bk_{name}", recipe))], TEX, samples=12)
        bpy.data.objects.remove(p)


STAGES = {"textures": stage_textures}

if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--stage", choices=list(STAGES), required=True)
    STAGES[ap.parse_args(argv).stage]()
    print("DONE")
