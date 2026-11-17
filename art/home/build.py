"""Build the home's kit, headless (art/home/README.md).

    blender -b --factory-startup -P art/home/build.py -- --stage textures|door|export|looks|cards|furniture
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
import cards  # noqa: E402
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
        return render.simple(f"plain_{name}", front.PLAIN.get(name) or cards.PLAIN_COLOURS[name], 0.4)
    return bake.textured(set_name, TEX if set_name in SETS else UNIT_TEX, for_export=for_export)


def texsets():
    """Every exported part's texture set (None: plain, the game sets its Material and Color)."""
    out = {n: front.TEXSET.get(n) for n in front.BUILDERS}
    out.update(furnish.TEXSET)
    out.update(cards.TEXSET)
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
    for name, mesh in list(front.meshes(s).items()) + list(furnish.meshes().items()) + \
            list(cards.meshes().items()):
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
    K.write_luau(lua, rows, plate, toggle, front.lamp_at(s), {k: list(v) for k, v in cards.STYLES.items()})


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


# --- the name cards' sheet (S5-03g1b, D-322) ------------------------------------------------------
# Four homes along the hall, a style over each door, lettered in the game's own fonts (Studio's
# font files, as Font.fromName finds them): a close-up of each from the floor, then the four from
# down the hall and from across the floor. art/sheets/home-cards.png, judged at phone size.
FONTS = "/Applications/RobloxStudio.app/Contents/Resources/content/fonts"
CARD_NAMES = ("MAPLEFOX", "SKYE", "JUNIPER_88", "NOVA")
CARD_XS = (-30.0, -10.0, 10.0, 30.0)  # the four homes' middles along the wall (the slots' pitch)
CARD_Z = 11.4                         # the card's middle (art/lobby/spec.py CARD)
HALL_DOOR = (8.4, 8.4)                # a doorway: across, tall


def font_file(family, weight):
    """The font file Studio draws `family` at `weight` with (its families JSON)."""
    import json
    want = {"Regular": 400, "Medium": 500, "SemiBold": 600, "Bold": 700}[weight]
    with open(os.path.join(FONTS, "families", f"{family}.json")) as f:
        faces = json.load(f)["faces"]
    face = next(x for x in faces if x["weight"] == want and x["style"] == "normal")
    assert face["assetId"].startswith("rbxasset://fonts/"), f"{family} {weight} isn't on disk"
    return os.path.join(FONTS, face["assetId"][len("rbxasset://fonts/"):])


def lettering(body, family, weight, at, size, mat, coll, offset=0.0):
    """Words fitted to a face (TextScaled's way: as big as fits), centred, facing -y."""
    import math
    from mathutils import Matrix
    cu = bpy.data.curves.new("card_words", "FONT")
    cu.body = body
    cu.font = bpy.data.fonts.load(font_file(family, weight), check_existing=True)
    cu.align_x, cu.align_y = "CENTER", "CENTER"
    cu.size, cu.offset = 1.0, offset
    ob = bpy.data.objects.new("card_words", cu)
    coll.objects.link(ob)
    ob.data.materials.append(mat)
    bpy.context.view_layer.update()
    w, h = ob.dimensions.x, ob.dimensions.y
    k = min(size[0] / max(w, 1e-6), size[1] / max(h, 1e-6))
    ob.matrix_world = (Matrix.Translation(at) @ Matrix.Rotation(math.pi / 2, 4, "X")
                       @ Matrix.Scale(k, 4))
    return ob


def hall(coll):
    """The hall's wall with four doorways: sage below the oak rail at 10, cream above to the deck,
    oak casings, the doors down in four of the home's colours, an oak floor and a white ceiling."""
    sage = render.simple("hall_sage", render.hexc("#93A68F"), 0.85)
    cream = render.simple("hall_cream", render.hexc("#E6DDCC"), 0.85)
    oak = render.simple("hall_oak", render.hexc("#B98A5E"), 0.5)
    floor = render.simple("hall_floor", render.hexc("#9C7553"), 0.45)
    ceil = render.emissive("hall_ceil", render.hexc("#F5F2EB"), 0.6)  # lit by lamps not drawn
    x0, x1 = -70.0, 70.0
    dw, dh = HALL_DOOR
    box = lambda n, lo, hi, m: render.box_obj(n, lo, hi, m, coll)
    edges = [x0] + [e for x in CARD_XS for e in (x - dw / 2, x + dw / 2)] + [x1]
    for i in range(0, len(edges), 2):
        box("hall_low", (edges[i], 0.0, 0.0), (edges[i + 1], 0.4, 10.0), sage)
    for k, x in enumerate(CARD_XS):
        box("hall_lintel", (x - dw / 2, 0.0, dh), (x + dw / 2, 0.4, 10.0), sage)
        door = render.simple(f"hall_door{k}", render.hexc(K.DOORS[k][1]), 0.45)
        groove = render.simple(f"hall_groove{k}", tuple(c * 0.6 for c in render.hexc(K.DOORS[k][1])), 0.6)
        box("hall_door", (x - dw / 2, 0.3, 0.0), (x + dw / 2, 0.4, dh), door)
        z = 0.55
        while z < dh:
            box("hall_slat", (x - dw / 2, 0.27, z), (x + dw / 2, 0.3, z + 0.05), groove)
            z += 0.55
        for sx in (-1, 1):
            a, b = sorted((x + sx * dw / 2, x + sx * (dw / 2 + 0.5)))
            box("hall_casing", (a, -0.12, 0.0), (b, 0.0, dh + 0.5), oak)
        box("hall_head", (x - dw / 2 - 0.5, -0.12, dh), (x + dw / 2 + 0.5, 0.0, dh + 0.5), oak)
    box("hall_up", (x0, 0.0, 10.0), (x1, 0.4, 14.0), cream)
    box("hall_rail", (x0, -0.12, 10.0 - 0.16), (x1, 0.0, 10.0 + 0.16), oak)
    box("hall_base", (x0, -0.07, 0.0), (x1, 0.0, 0.55), oak)
    box("hall_floor", (x0, -80.0, -0.2), (x1, 0.4, 0.0), floor)
    box("hall_ceiling", (x0, -80.0, 14.0), (x1, 0.4, 14.2), ceil)
    for sx, m in ((-1, sage), (1, sage)):  # the hall's two ends, so nothing shows past them
        a, b = sorted((sx * 70.0, sx * 70.4))
        box("hall_end", (a, -80.0, 0.0), (b, 0.4, 14.0), m)
    for x in (-40.0, -20.0, 0.0, 20.0, 40.0):
        for y in (-9.0, -30.0):
            ld = bpy.data.lights.new("hall_lamp", "AREA")
            ld.shape, ld.size, ld.energy = "DISK", 2.2, 900.0
            ld.color = (1.0, 0.88, 0.72)
            lo = bpy.data.objects.new("hall_lamp", ld)
            lo.location = (x, y, 13.8)
            coll.objects.link(lo)


def hall_cards(coll):
    """Each style's plate over its door, its lettering, and the neon's light on the wall."""
    faces = K.card_faces()
    for k, (style, _, paint, (fam, weight), ink, glow) in enumerate(K.CARDS):
        x = CARD_XS[k]
        for name in cards.STYLES[style]:
            ob = cards.BUILDERS[name]().build(coll)
            ob.data.materials.clear()
            if name == "CardNeonTube":
                ob.data.materials.append(render.emissive("neon_tube", render.hexc(glow), 6.0))
            else:
                ob.data.materials.append(material(name, cards.TEXSET[name], False))
            ob.location = (x, 0.0, CARD_Z)
            tinted = cards.TEXSET[name] in looks.TINTED and paint
            ob["tint"] = (*render.hexc(paint), 1.0) if tinted else (1.0, 1.0, 1.0, 1.0)
        (cx, cy, cz), size = faces[style]
        at = (x + cx, cy - 0.004, CARD_Z + cz)
        if glow:
            core = render.emissive("neon_core", render.hexc(ink), 5.0)
            halo = render.emissive("neon_halo", render.hexc(glow), 3.0)
            lettering(CARD_NAMES[k], fam, weight, at, size, core, coll)
            lettering(CARD_NAMES[k], fam, weight, (at[0], at[1] + 0.002, at[2]), size, halo, coll, 0.025)
            rng, _ = K.CARD_LIGHT
            ld = bpy.data.lights.new("neon_light", "POINT")
            ld.energy, ld.color, ld.shadow_soft_size = 60.0 * rng / 9.0, render.hexc(glow), 0.4
            lo = bpy.data.objects.new("neon_light", ld)
            lo.location = (x, -0.9, CARD_Z)
            coll.objects.link(lo)
        else:
            mat = render.simple(f"ink_{style}", render.hexc(ink), 0.7)
            lettering(CARD_NAMES[k], fam, weight, at, size, mat, coll)


def stage_cards():
    import numpy as np
    import tempfile
    bpy.ops.wm.read_factory_settings(use_empty=True)
    register()
    coll = bpy.context.scene.collection
    render.setup(64, (640, 360))
    render.world((0.16, 0.15, 0.13), 1.0)
    hall(coll)
    hall_cards(coll)
    tmp = os.environ.get("CARD_SHOTS") or tempfile.mkdtemp(prefix="home-cards-")  # each shot
    os.makedirs(tmp, exist_ok=True)
    scene = bpy.context.scene

    def shot(name, loc, target, lens, res):
        scene.render.resolution_x, scene.render.resolution_y = res
        path = os.path.join(tmp, f"{name}.png")
        render.shoot(render.camera(loc, target, lens=lens), path)
        img = bpy.data.images.load(path)
        out = (bake.pixels(img)[..., :3] * 255.0 + 0.5).astype(np.uint8)
        bpy.data.images.remove(img)
        return out
    # close up: standing in front of each door, looking up at its card
    close = [shot(f"close{k}", (x - 2.0, -12.0, 5.0), (x, 0.0, 10.4), 24.0, (640, 360))
             for k, x in enumerate(CARD_XS)]
    # down the hall from beside the first door, and from across the floor
    far = [shot("hall", (-62.0, -14.0, 5.0), (30.0, 0.0, 10.0), 32.0, (1280, 720)),
           shot("across", (0.0, -50.0, 5.0), (0.0, 0.0, 8.6), 24.0, (1280, 720))]
    sheet = np.vstack([np.hstack(close), np.hstack(far)])
    out = os.path.join(K.ROOT, "art", "sheets", "home-cards.png")
    bake.write_png(out, sheet)
    print("SHEET", out)


# --- the counter's furniture sheet (S5-03g1c1, D-323) ---------------------------------------------
# The four new pieces set out as a shop would, by a person for scale, then a unit made into a place
# to hang out: the pallet on the rug, crates and the beanbag round it, the folding table on the
# right wall, the steel shelf on the back with boxes on it. art/sheets/home-furniture.png.
FURN_RES = (640, 360)  # a panel: a phone's landscape screen at about half size


def place(name, at, turn, tint=None):
    """One part of a piece at `at` in a unit, turned about z (degrees); a plain part in `tint`
    when given, a tinted set's part painted it."""
    import math
    ob = furnish.BUILDERS[name]().build(bpy.context.scene.collection)
    ob.data.materials.clear()
    set_name = furnish.TEXSET.get(name)
    if set_name is None and tint:
        mat = render.simple(f"plain_{name}_{tint}", render.hexc(tint), 0.45)
    else:
        mat = material(name, set_name, False)
    ob.data.materials.append(mat)
    ob.location = (at[0], at[1], 0.0)
    ob.rotation_euler = (0.0, 0.0, math.radians(turn))
    ob["tint"] = (*render.hexc(tint), 1.0) if tint and set_name else (1.0, 1.0, 1.0, 1.0)
    return ob


def piece(kind, at, turn, tints=None):
    return [place(n, at, turn, (tints or {}).get(n)) for n in K.PIECES[kind]]


def person(at):
    """A plain stand-in, 5.4 tall, for scale."""
    from geo import Mesh
    import geo
    m = Mesh("Person")
    for sx in (-0.45, 0.45):
        geo.cylinder(m, "z", (at[0] + sx, at[1], 1.2), 0.32, 2.4, segs=10)
    geo.box(m, (at[0] - 0.95, at[1] - 0.45, 2.4), (at[0] + 0.95, at[1] + 0.45, 4.3), bevel=0.2, segments=2)
    geo.cylinder(m, "z", (at[0], at[1], 4.85), 0.5, 1.0, segs=14, bevel=0.2)
    ob = m.build(bpy.context.scene.collection)
    ob.data.materials.append(render.simple("person", render.hexc("#8C929C"), 0.6))
    return [ob]


TINTS = {"FoldingTable": "#E5DFD2", "SteelShelf": "#93A88E"}  # the sheet's paints (the game's, g4)


def stage_furniture():
    import numpy as np
    import tempfile
    bpy.ops.wm.read_factory_settings(use_empty=True)
    register()
    render.setup(48, FURN_RES)
    render.world((0.02, 0.018, 0.015), 1.0)
    look_lights()
    look_room("Boards", None, "Plain", "WarmWhite")
    coll = bpy.context.scene.collection
    show = person((-3.4, 27.2)) + piece("SteelShelf", (-6.6, 28.4), 0.0, TINTS) + \
        piece("FoldingTable", (1.0, 27.2), 0.0, TINTS) + piece("Pallet", (6.2, 25.4), -18.0) + \
        piece("MilkCrate", (2.4, 23.0), 15.0, {"MilkCrate": "#D2A23A"})
    hang = piece("Rug", (0.0, 11.5), 0.0) + piece("Pallet", (0.0, 11.5), 0.0) + \
        piece("MilkCrate", (-3.7, 10.6), 20.0, {"MilkCrate": "#D2A23A"}) + \
        piece("MilkCrate", (3.6, 12.6), -105.0, {"MilkCrate": "#5E8C7E"}) + \
        piece("Beanbag", (0.8, 6.9), 175.0, {"Beanbag": "#B98A3C"}) + \
        piece("FloorLamp", (-6.6, 13.5), 0.0) + \
        piece("FoldingTable", (8.2, 18.5), -90.0, TINTS) + \
        piece("MilkCrate", (6.2, 17.4), 80.0, {"MilkCrate": "#B8613F"}) + \
        piece("SteelShelf", (-4.8, 28.4), 0.0, TINTS)
    for z in K.STEEL_TIERS[:3]:  # boxes standing in for finds on the shelf's tiers
        hang.append(render.box_prop(coll, (-5.6, 28.4, z), (1.3, 1.0, 0.9), 0.07))
        hang.append(render.box_prop(coll, (-3.9, 28.3, z), (0.9, 0.8, 0.7), -0.1))
    shots = []
    tmp = tempfile.mkdtemp(prefix="home-furn-")
    views = (("show", (0.0, 12.0, 4.6), (0.0, 26.0, 2.0), 24.0),
             ("unit", (-1.5, -1.0, 6.2), (0.8, 18.0, 3.2), 16.0),
             ("sit", (6.0, 5.5, 3.6), (-1.5, 13.5, 1.2), 22.0),
             ("wall", (0.5, 11.5, 4.6), (7.0, 19.5, 2.0), 26.0))
    for name, loc, target, lens in views:
        for ob in show:
            ob.hide_render = name != "show"
        for ob in hang:
            ob.hide_render = name == "show"
        cam = render.camera(loc, target, lens=lens)
        path = os.path.join(tmp, f"{name}.png")
        render.shoot(cam, path)
        img = bpy.data.images.load(path)
        shots.append((bake.pixels(img)[..., :3] * 255.0 + 0.5).astype(np.uint8))
        bpy.data.images.remove(img)
    sheet = np.vstack([np.hstack(shots[0:2]), np.hstack(shots[2:4])])
    out = os.path.join(K.ROOT, "art", "sheets", "home-furniture.png")
    bake.write_png(out, sheet)
    print("SHEET", out)


STAGES = {"textures": stage_textures, "door": stage_door, "export": stage_export,
          "looks": stage_looks, "cards": stage_cards, "furniture": stage_furniture}

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
