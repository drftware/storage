"""Render the next-floor cards' faces in Blender, headless (art/cards/README.md).

    blender -b --factory-startup -P art/cards/build.py -- --stage faces|sheet

Stages:
    faces  one picture per version of a floor, out/<Version>.png (NextFloor.Versions' names)
    sheet  the four side by side at a phone's card size, art/sheets/cards-phone.png

Each face is staged from the game's own exported models (the padlock, the Mannequin in its
standing pose, the hall's caged bulb, the freight elevator), lit and rendered with the unit's
render kit (art/unit/render.py).
"""

import argparse
import json
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "unit"))
sys.path.insert(0, HERE)  # first: this folder's spec.py

import bpy  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402

import render  # noqa: E402
import spec as K  # noqa: E402

FACES = ("PowerOut", "TwicePadlocks", "TwiceMonsters", "CaughtToLobby")

# Roblox's frame to Blender's and back (the same matrix both ways): x = -X, y = Z, z = Y, as the
# Mannequin's own build has it for its poses.
FLIP = Matrix(((-1, 0, 0, 0), (0, 0, 1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    render.setup(K.SAMPLES, K.PX)
    render.world((0.002, 0.0025, 0.004), 1.0)


def bring(path):
    """The model at `path`, imported; its mesh objects by name."""
    before = set(bpy.context.scene.objects)
    bpy.ops.import_scene.fbx(filepath=path)
    return {o.name: o for o in bpy.context.scene.objects if o not in before and o.type == "MESH"}


def bounds(objs):
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    bpy.context.view_layer.update()
    for o in objs:
        for c in o.bound_box:
            p = o.matrix_world @ Vector(c)
            lo = Vector(map(min, lo, p))
            hi = Vector(map(max, hi, p))
    return lo, hi


def place(objs, matrix):
    """Moves `objs` together by `matrix`, about the middle of their bounds."""
    lo, hi = bounds(objs)
    mid = (lo + hi) / 2
    for o in objs:
        o.matrix_world = matrix @ Matrix.Translation(-mid) @ o.matrix_world


def light(kind, name, energy, color, at, target, size=1.0, spot=None):
    data = bpy.data.lights.new(name, kind)
    data.energy, data.color = energy, color
    if kind == "AREA":
        data.size = size
    elif kind == "SPOT":
        data.spot_size, data.spot_blend = math.radians(spot or 30.0), 0.6
        data.shadow_soft_size = 0.05
    else:
        data.shadow_soft_size = size
    ob = bpy.data.objects.new(name, data)
    bpy.context.scene.collection.objects.link(ob)
    ob.location = at
    ob.rotation_euler = (Vector(target) - Vector(at)).to_track_quat("-Z", "Y").to_euler()
    return ob


def plane(name, corners, mat):
    me = bpy.data.meshes.new(name)
    me.from_pydata([Vector(c) for c in corners], [], [[0, 1, 2, 3]])
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    ob.data.materials.append(mat)
    return ob


def cylinder(name, a, b, r, mat):
    a, b = Vector(a), Vector(b)
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=r, depth=(b - a).length,
                                        location=(a + b) / 2)
    ob = bpy.context.active_object
    ob.name = name
    ob.rotation_euler = (b - a).to_track_quat("Z", "Y").to_euler()
    ob.data.materials.append(mat)
    return ob


def shoot(cam_spec, name, exposure):
    loc, target, lens = cam_spec
    cam = render.camera(loc, target, lens=lens)
    os.makedirs(K.OUT, exist_ok=True)
    render.shoot(cam, os.path.join(K.OUT, f"{name}.png"), exposure=exposure)


# --- the faces ---------------------------------------------------------------------------------

def power_out():
    """The hall's caged bulb, dead, hanging in the dark; the torch catches its cage."""
    reset()
    parts = bring(K.BULB)
    place(list(parts.values()), Matrix.Identity(4))
    glass = parts.get("Glass")
    if glass:
        glass.data.materials.clear()
        dead = render.simple("dead_glass", (0.05, 0.05, 0.055, 1), rough=0.12)
        glass.data.materials.append(dead)
    lo, hi = bounds(parts.values())
    cylinder("cord", (0, 0, hi.z - 0.02), (0, 0, hi.z + 6.0), 0.035,
             render.simple("cord", (0.01, 0.01, 0.01, 1), rough=0.5))
    g = sum(bounds([glass] if glass else parts.values()), Vector()) / 2
    wall = render.simple("wall", (0.08, 0.085, 0.09, 1), rough=0.7)
    plane("wall", [(-8, 2.4, -8), (8, 2.4, -8), (8, 2.4, 8), (-8, 2.4, 8)], wall)
    light("SPOT", "pool", K.BULB_POOL, K.COLD, g + Vector((0.0, -0.4, 1.6)), g + Vector((0, 2.4, 0.3)),
          spot=50)
    light("AREA", "rim", K.BULB_RIM, K.COLD, g + Vector((-0.6, 1.2, 0.9)), g, size=1.0)
    light("SPOT", "torch", K.BULB_TORCH, (1.0, 0.86, 0.68), g + Vector((0.6, -1.8, -0.9)), g, spot=22)
    loc, target, lens = K.BULB_CAM
    shoot((g + Vector(loc), g + Vector(target), lens), "PowerOut", K.BULB_EXPOSURE)


def twice_padlocks():
    """Two padlocks side by side on a steel door, the right one swung as if just hung."""
    reset()
    left = list(bring(K.PADLOCK).values())
    place(left, Matrix.Translation((-K.LOCK_GAP, 0, 0)))
    right = list(bring(K.PADLOCK).values())
    place(right, Matrix.Translation((K.LOCK_GAP, 0, -K.LOCK_DROP))
          @ Matrix.Rotation(math.radians(-K.LOCK_SWING), 4, "Y"))
    steel = render.simple("door", (0.10, 0.105, 0.11, 1), rough=0.42, metal=0.85)
    plane("door", [(-4, 0.16, -4), (4, 0.16, -4), (4, 0.16, 4), (-4, 0.16, 4)], steel)
    light("AREA", "bulb", K.LOCK_KEY, K.WARM, (-1.4, -1.6, 1.8), (0, 0, 0), size=0.8)
    light("AREA", "rim", K.LOCK_RIM, K.COLD, (1.8, -0.4, 1.2), (0, 0, 0), size=1.0)
    shoot(K.LOCK_CAM, "TwicePadlocks", K.LOCK_EXPOSURE)


def twice_monsters():
    """Two Mannequins standing as they're found at the end of a dark hall, a tube behind them."""
    reset()
    with open(K.POSES) as f:
        still = json.load(f).get("Still", {})
    for at, turn in K.FIGURES:
        parts = bring(K.MANNEQUIN)
        stand = Matrix.Translation(Vector(at)) @ Matrix.Rotation(math.radians(turn), 4, "Z")
        for name, ob in parts.items():
            t = still.get(name.split(".")[0])
            m = Matrix([t[0:4], t[4:8], t[8:12], t[12:16]]) if t else Matrix.Identity(4)
            ob.matrix_world = stand @ FLIP @ m @ FLIP
    concrete = render.simple("floor", (0.07, 0.07, 0.068, 1), rough=0.55)
    plane("floor", [(-6, -4, 0), (6, -4, 0), (6, 30, 0), (-6, 30, 0)], concrete)
    wall = render.simple("wall", (0.05, 0.052, 0.056, 1), rough=0.5, metal=0.6)
    plane("left", [(-4.2, -4, 0), (-4.2, 30, 0), (-4.2, 30, 11), (-4.2, -4, 11)], wall)
    plane("right", [(4.2, 30, 0), (4.2, -4, 0), (4.2, -4, 11), (4.2, 30, 11)], wall)
    light("AREA", "tube", K.FIG_BACK, K.SICK, (0.0, 14.0, 9.5), (0.0, 8.0, 2.0), size=3.0)
    light("SPOT", "torch", K.FIG_TORCH, (1.0, 0.86, 0.68), (0.5, -2.0, 3.6), (0.0, 7.5, 1.0),
          spot=24)
    shoot(K.FIG_CAM, "TwiceMonsters", K.FIG_EXPOSURE)


def caught_to_lobby():
    """Down the shaft at the car far below, its cables running down to it, red from the pit."""
    reset()
    car = list(bring(K.ELEVATOR).values())
    lo, hi = bounds(car)
    place(car, Matrix.Translation((0, 0, (hi.z - lo.z) / 2)))
    lo, hi = bounds(car)
    w, d, h = K.SHAFT
    concrete = render.simple("shaft", (0.09, 0.085, 0.08, 1), rough=0.8)
    x, y = w / 2, d / 2
    plane("w1", [(-x, -y, -8), (x, -y, -8), (x, -y, h), (-x, -y, h)], concrete)
    plane("w2", [(x, y, -8), (-x, y, -8), (-x, y, h), (x, y, h)], concrete)
    plane("w3", [(-x, y, -8), (-x, -y, -8), (-x, -y, h), (-x, y, h)], concrete)
    plane("w4", [(x, -y, -8), (x, y, -8), (x, y, h), (x, -y, h)], concrete)
    steel = render.simple("cable", (0.15, 0.15, 0.16, 1), rough=0.3, metal=1.0)
    beam = render.simple("beam", (0.05, 0.05, 0.055, 1), rough=0.45, metal=0.9)
    z = K.BEAMS
    while z < h:
        for c in ([(-x, -y), (x, -y)], [(x, -y), (x, y)], [(x, y), (-x, y)], [(-x, y), (-x, -y)]):
            (ax, ay), (bx, by) = c
            a = Vector((ax * 0.97, ay * 0.97, z))
            b = Vector((bx * 0.97, by * 0.97, z))
            cylinder("beam", a, b, 0.22, beam)
        z += K.BEAMS
    mid = (lo + hi) / 2
    for dx in (-0.45, -0.15, 0.15, 0.45):
        cylinder("cable", (mid.x + dx, mid.y, hi.z), (mid.x + dx, mid.y, h), 0.06, steel)
    for sx in (-1, 1):
        for sy in (-1, 1):
            light("POINT", "pit", K.DOWN_GLOW, K.RED, (sx * (x - 0.6), sy * (y - 0.6), -4), (0, 0, 0),
                  size=1.0)
    light("POINT", "lamp", K.DOWN_CAR, K.WARM, (mid.x, mid.y, hi.z + 0.8), (0, 0, 0), size=0.4)
    shoot(K.DOWN_CAM, "CaughtToLobby", K.DOWN_EXPOSURE)


def stage_faces():
    power_out()
    twice_padlocks()
    twice_monsters()
    caught_to_lobby()


def stage_sheet():
    """The four faces side by side at the size a Galaxy A16 shows a card, on the car's dark."""
    cw = K.SHEET_CARD_PX
    ch = round(cw * K.PX[1] / K.PX[0])
    gap = 14
    W, H = gap + len(FACES) * (cw + gap), ch + 2 * gap
    sheet = bpy.data.images.new("sheet", W, H, alpha=False)
    pixels = [0.04, 0.04, 0.045, 1.0] * (W * H)
    for i, name in enumerate(FACES):
        img = bpy.data.images.load(os.path.join(K.OUT, f"{name}.png"))
        img.scale(cw, ch)
        src = list(img.pixels)
        x0 = gap + i * (cw + gap)
        for row in range(ch):
            a = (row * cw) * 4
            b = ((gap + row) * W + x0) * 4
            pixels[b:b + cw * 4] = src[a:a + cw * 4]
    sheet.pixels = pixels
    os.makedirs(K.SHEETS, exist_ok=True)
    sheet.filepath_raw = os.path.join(K.SHEETS, "cards-phone.png")
    sheet.file_format = "PNG"
    sheet.save()
    print("SHEET", sheet.filepath_raw)


STAGES = {"faces": stage_faces, "sheet": stage_sheet,
          "PowerOut": power_out, "TwicePadlocks": twice_padlocks,
          "TwiceMonsters": twice_monsters, "CaughtToLobby": caught_to_lobby}

if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--stage", choices=list(STAGES), required=True)
    STAGES[ap.parse_args(argv).stage]()
    print("DONE")
