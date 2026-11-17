"""Build the home's kit, headless (art/home/README.md).

    blender -b --factory-startup -P art/home/build.py -- --stage textures|door|export|looks
                                                          [--sets FloorTiles,PaperLeaves]

Stages:
    textures  the home's texture sets (looks.py LOOKS) into art/home/out/textures, with the unit's
              bake (art/unit/bake.py)
    door      HomeDoor: the DoorKit's layout kept new, baked on the M's own door parts (the unit's
              M must be built first: its atlas pack is art/unit/out/M/unit.blend)
    export    art/home/out/Home.fbx (the home front, the door's parts in HomeDoor, the
              furnishings: one MeshPart each) and src/shared/Home/Specs.luau

The ground floor (art/lobby) wears the sets, stands the home front in every gap and the
furnishings round the floor, and draws the look sheets.
"""

import argparse
import importlib.util
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
UNIT = os.path.abspath(os.path.join(HERE, "..", "unit"))
sys.path.insert(0, UNIT)
sys.path.insert(0, HERE)

import bpy  # noqa: E402

import bake  # noqa: E402
import front  # noqa: E402
import furnish  # noqa: E402
import home_spec as K  # noqa: E402
import looks  # noqa: E402
import materials as M  # noqa: E402  the unit's looks: the door's hardware keeps them
import render  # noqa: E402

TEX = os.path.join(HERE, "out", "textures")
UNIT_TEX = os.path.join(UNIT, "out", "textures")
FBX = os.path.join(HERE, "out", "Home.fbx")
SETS = set(looks.LOOKS) | set(looks.SIZES)  # the sets baked here; the rest are the unit's


def register():
    """Teach the unit's bake the home's sets: their sizes and which take the part's paint."""
    for name, (_, _, size) in looks.LOOKS.items():
        bake.SIZES[name] = size
    bake.SIZES.update(looks.SIZES)
    bake.TINTED.update(looks.TINTED)


def unit_kit():
    """The unit's own build module (its Unit and Spec), for the door's parts."""
    s = importlib.util.spec_from_file_location("unit_build", os.path.join(UNIT, "build.py"))
    mod = importlib.util.module_from_spec(s)
    s.loader.exec_module(mod)
    return mod


def door_unit(uk, coll):
    """The M at rest, shut and latched, its small parts wearing the M's atlas pack."""
    unit = uk.Unit(uk.Spec(K.DOOR_SIZE), coll)
    unit.pose(0.0, locked=True)
    dk = [unit.objs[n] for n in ("BottomBar", "LatchBolt", "Padlock", "Hardware", "Drum", "NumberPlate")]
    bake.copy_atlas(dk, os.path.join(UNIT, "out", K.DOOR_SIZE, "unit.blend"))
    return unit


def material(name, set_name, for_export):
    if set_name is None:
        return render.simple(f"plain_{name}", front.PLAIN[name], 0.4)
    return bake.textured(set_name, TEX if set_name in SETS else UNIT_TEX, for_export=for_export)


def texsets():
    """Every exported part's texture set (None: plain, the game sets its Material and Color)."""
    out = {n: front.TEXSET.get(n) for n in front.BUILDERS}
    out.update(furnish.TEXSET)
    out.update({n: "HomeDoor" for n in front.DOOR_PARTS})
    return out


def stage_textures(only=None):
    """only: the sets to bake (`--sets FloorTiles,PaperLeaves`), so the rest keep their maps."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    register()
    for name, (recipe, (w, h), _) in looks.LOOKS.items():
        if only and name not in only:
            continue
        p = bake.plane(f"bake_{name}", w, h)
        bake.bake_set(name, [(p, bake.Rig(f"bk_{name}", recipe))], TEX, samples=12)
        bpy.data.objects.remove(p)


def stage_door():
    """HomeDoor on the M's own parts: the curtain and bar kept new (looks.py), the hardware,
    drum and latch bolt the climb's (inside, over your head), the padlock and plate left blank."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    register()
    uk = unit_kit()
    unit = door_unit(uk, uk.collection("Unit"))
    o, s = unit.objs, unit.spec
    slat = bake.Rig("hd_slat", looks.door_slat)
    items = [(o["Slat_A"], slat), (o["Slat_B"], slat), (o["Slat_C"], slat),
             (o["BottomBar"], bake.Rig("hd_bar", looks.door_bar)),
             (o["LatchBolt"], bake.Rig("hd_bolt", M.latch_bolt)),
             (o["Hardware"], bake.Rig("hd_hw", lambda nb: M.hardware(nb, s))),
             (o["Drum"], bake.Rig("hd_drum", M.drum))]
    bake.bake_set("HomeDoor", items, TEX, samples=48)


def world_box(ob):
    vs = [ob.matrix_world @ v.co for v in ob.data.vertices]
    lo = [min(v[i] for v in vs) for i in range(3)]
    hi = [max(v[i] for v in vs) for i in range(3)]
    return lo, hi


def stage_export():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    register()
    uk = unit_kit()
    unit = door_unit(uk, uk.collection("Unit"))
    s = unit.spec
    for name, ob in list(unit.objs.items()):  # the M's own front and box go: the home's replace them
        if name not in front.DOOR_PARTS:
            me = ob.data
            bpy.data.objects.remove(ob)
            if me is not None:
                bpy.data.meshes.remove(me)
    coll = bpy.context.scene.collection
    objs = {n: unit.objs[n] for n in front.DOOR_PARTS}
    for name, mesh in list(front.meshes(s).items()) + list(furnish.meshes().items()):
        objs[name] = mesh.build(coll)
    sets = texsets()
    rows = {}
    bpy.ops.object.select_all(action="DESELECT")
    for name, ob in objs.items():
        assert ob.name == name, f"{name} imported as {ob.name}"
        ob.hide_render = ob.hide_viewport = False
        ob.hide_set(False)
        ob.data.materials.clear()
        ob.data.materials.append(material(name, sets[name], True))
        lo, hi = world_box(ob)
        tris = sum(len(p.vertices) - 2 for p in ob.data.polygons)
        assert tris < 20000, f"{name} has {tris} triangles (Roblox's cap)"
        rows[name] = dict(size=(hi[0] - lo[0], hi[2] - lo[2], hi[1] - lo[1]),
                          centre=tuple((lo[i] + hi[i]) / 2 for i in range(3)), tris=tris)
        ob.select_set(True)
    bpy.context.view_layer.objects.active = objs["Facade"]
    os.makedirs(os.path.dirname(FBX), exist_ok=True)
    bpy.ops.export_scene.fbx(
        filepath=FBX, use_selection=True, object_types={"MESH"},
        apply_scale_options="FBX_SCALE_UNITS", axis_forward="Z", axis_up="Y",
        use_mesh_modifiers=True, mesh_smooth_type="OFF", use_tspace=False,
        add_leaf_bones=False, bake_anim=False, path_mode="COPY", embed_textures=True)
    print("FBX", FBX, os.path.getsize(FBX), f"{sum(r['tris'] for r in rows.values())} triangles",
          {n: r["tris"] for n, r in rows.items()})
    plate, toggle = front.switch_at(s)
    lua = os.path.join(K.ROOT, "src", "shared", "Home", "Specs.luau")
    os.makedirs(os.path.dirname(lua), exist_ok=True)
    K.write_luau(lua, rows, plate, toggle, front.lamp_at(s))


# --- the looks' sheet (S5-03g1a, D-321) ------------------------------------------------------------
# Eight units as you walk in, each a floor, a paper and a paint, with the starter beanbag and lamp;
# under them the door colours on the lobby's teal. art/sheets/home-floors.png, judged at phone size.
LOOK_ROOM = (20.0, 30.0, 10.0)   # a home's inside (the XL slot): across, deep, tall
LOOK_PANELS = (("Boards", None, "Plain", "WarmWhite"), ("Carpet", "Oatmeal", "Stripes", "Blush"),
               ("Checker", "Cherry", "Daisies", "Butter"), ("Matting", "Charcoal", "Leaves", "Sage"),
               ("Carpet", "Denim", "Leaves", "DuckEgg"), ("Checker", "Charcoal", "Stripes", "Ink"),
               ("Boards", None, "Daisies", "Lavender"), ("Matting", "Slate", "Plain", "Terracotta"))
LOOK_RES = (640, 360)            # a panel: a phone's landscape screen at about half size


def look_wall(name, set_name, w, h, tile, loc, rot, tint):
    """A plane w x h studs, its UVs in studs over the set's tile, stood at loc turned by rot."""
    import math
    ob = bake.plane(name, w, h, (0.0, 0.0, w / tile, h / tile))
    ob.location = loc
    ob.rotation_euler = tuple(math.radians(r) for r in rot)
    ob.data.materials.append(material(name, set_name, False))
    ob["tint"] = (*render.hexc(tint), 1.0) if tint else (1.0, 1.0, 1.0, 1.0)
    return ob


def look_room(floor, floor_tint, paper, paint):
    """One unit's inside wearing a look: walls, floor and ceiling, origin at the doorway's middle."""
    w, d, h = LOOK_ROOM
    floors = {i: s for i, s, _ in K.FLOORS}
    papers = dict(K.PAPERS)
    hexes = dict(K.PAINTS)
    fcols = {i: dict(c) for i, _, c in K.FLOORS}
    tint = fcols[floor].get(floor_tint) if floor_tint else None
    out = [look_wall("LookFloor", floors[floor], w, d, K.FLOOR_TILE, (-w / 2, 0.0, 0.0), (0, 0, 0), tint)]
    pt, tile = hexes[paint], K.PAPER_TILE
    out.append(look_wall("LookLeft", papers[paper], d, h, tile, (-w / 2, 0.0, 0.0), (90, 0, 90), pt))
    out.append(look_wall("LookRight", papers[paper], d, h, tile, (w / 2, d, 0.0), (90, 0, -90), pt))
    out.append(look_wall("LookBack", papers[paper], w, h, tile, (-w / 2, d, 0.0), (90, 0, 0), pt))
    out.append(look_wall("LookTop", "Plaster", w, d, 4.0, (-w / 2, d, h), (180, 0, 0), "#F1EBDF"))
    oak = render.simple("look_oak", render.hexc("#B98A5E"), 0.5)
    b, pr = K.BASE, K.BASE_PROUD
    for name, lo, hi in (("BaseL", (-w / 2, 0, 0), (-w / 2 + pr, d, b)),
                         ("BaseR", (w / 2 - pr, 0, 0), (w / 2, d, b)),
                         ("BaseB", (-w / 2, d - pr, 0), (w / 2, d, b))):
        out.append(render.box_obj(name, lo, hi, oak, bpy.context.scene.collection))
    return out


def look_furniture():
    """The starter beanbag and floor lamp, where a new home has them about."""
    import math
    coll = bpy.context.scene.collection
    out = []
    for name, at, turn, tint in (("Beanbag", (5.2, 11.5), -22.0, "#B98A3C"),
                                 ("FloorLamp", (7.6, 14.5), 0.0, None),
                                 ("LampShade", (7.6, 14.5), 0.0, "#F1E8D6")):
        ob = furnish.BUILDERS[name]().build(coll)
        ob.data.materials.clear()
        ob.data.materials.append(material(name, furnish.TEXSET[name], False))
        ob.location = (at[0], at[1], 0.0)
        ob.rotation_euler = (0.0, 0.0, math.radians(turn))
        ob["tint"] = (*render.hexc(tint), 1.0) if tint else (1.0, 1.0, 1.0, 1.0)
        out.append(ob)
    return out


def look_lights():
    w, d, h = LOOK_ROOM
    ld = bpy.data.lights.new("look_lamp", "AREA")
    ld.shape, ld.size, ld.energy = "DISK", K.LAMP[0], 2600.0
    ld.color = (1.0, 0.86, 0.68)
    lamp = bpy.data.objects.new("look_lamp", ld)
    lamp.location = (0.0, K.LAMP_AT, h - 0.2)
    bpy.context.scene.collection.objects.link(lamp)
    fd = bpy.data.lights.new("look_door", "AREA")
    fd.shape, fd.size, fd.energy = "RECTANGLE", 8.0, 700.0
    fd.size_y = 8.0
    fd.color = (1.0, 0.93, 0.84)
    fill = bpy.data.objects.new("look_door", fd)
    fill.location = (0.0, -3.0, 7.0)
    fill.rotation_euler = (-1.2, 0.0, 0.0)
    bpy.context.scene.collection.objects.link(fill)


def door_strip(width, height):
    """The door colours as roll-up doors' worth of colour on the lobby's teal, sRGB, top row first."""
    import numpy as np
    def srgb(hx):
        hx = hx.lstrip("#")
        return [int(hx[i:i + 2], 16) for i in (0, 2, 4)]
    img = np.zeros((height, width, 3), dtype=np.uint8)
    img[:, :] = srgb("#2F6466")
    n = len(K.DOORS)
    pitch = width // n
    dw, top = int(pitch * 0.62), int(height * 0.14)
    for k, (_, hx) in enumerate(K.DOORS):
        x0 = k * pitch + (pitch - dw) // 2
        img[top:height, x0 - 8:x0 + dw + 8] = srgb("#B98A5E")  # the oak casing
        img[top + 8:height, x0:x0 + dw] = srgb(hx)
        for y in range(top + 8 + 14, height, 14):  # the slats' shadow lines
            img[y:y + 2, x0:x0 + dw] = (img[y:y + 2, x0:x0 + dw] * 0.82).astype(np.uint8)
    return img


def stage_looks():
    import numpy as np
    bpy.ops.wm.read_factory_settings(use_empty=True)
    register()
    render.setup(48, LOOK_RES)
    render.world((0.02, 0.018, 0.015), 1.0)
    look_lights()
    look_furniture()
    w, d, h = LOOK_ROOM
    cam = render.camera((-1.5, -1.0, 6.2), (0.8, 18.0, 3.2), lens=16.0)
    import tempfile
    tmp = tempfile.mkdtemp(prefix="home-looks-")  # the panels; only the sheet is kept
    shots = []
    for k, (floor, ft, paper, paint) in enumerate(LOOK_PANELS):
        parts = look_room(floor, ft, paper, paint)
        path = os.path.join(tmp, f"look{k + 1}.png")
        render.shoot(cam, path)
        img = bpy.data.images.load(path)
        shots.append((bake.pixels(img)[..., :3] * 255.0 + 0.5).astype(np.uint8))
        bpy.data.images.remove(img)
        for ob in parts:
            me = ob.data
            bpy.data.objects.remove(ob)
            bpy.data.meshes.remove(me)
    rows = [np.hstack(shots[i:i + 4]) for i in range(0, len(shots), 4)]
    sheet = np.vstack(rows + [door_strip(rows[0].shape[1], 220)])
    out = os.path.join(K.ROOT, "art", "sheets", "home-floors.png")
    bake.write_png(out, sheet)
    print("SHEET", out)


STAGES = {"textures": stage_textures, "door": stage_door, "export": stage_export,
          "looks": stage_looks}

if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--stage", choices=list(STAGES), required=True)
    ap.add_argument("--sets", default="", help="textures: only these sets, comma separated")
    args = ap.parse_args(argv)
    if args.stage == "textures":
        stage_textures([n for n in args.sets.split(",") if n])
    else:
        STAGES[args.stage]()
    print("DONE")
