"""Build the packed unit's stacks in Blender, headless (art/packed/README.md).

    blender -b --factory-startup -P art/packed/build.py -- --stage export|renders

Stages:
    export    out/Packed.fbx (every block, one MeshPart each) and src/shared/Packed/Specs.luau
    renders   the look sheets, art/sheets/packed-*.png (they need the boxes built: their textures)

No bake of its own: every block's faces map onto the boxes' Cardboard atlas islands, computed by
the boxes' own packer, so a block wears exactly the texels a box of its kind does.
"""

import argparse
import importlib.util
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
UNIT = os.path.join(HERE, "..", "unit")
BOXES = os.path.abspath(os.path.join(HERE, "..", "boxes"))
sys.path.insert(0, UNIT)
sys.path.insert(0, HERE)  # first: this folder's spec.py

import bpy  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402

import geo  # noqa: E402
import render  # noqa: E402
import spec as K  # noqa: E402

OUT = os.path.join(HERE, "out")
FBX = os.path.join(OUT, "Packed.fbx")
SPECS = os.path.join(K.ROOT, "src", "shared", "Packed", "Specs.luau")
SHEETS = os.path.join(K.ROOT, "art", "sheets")
X, Y, Z = Vector((1, 0, 0)), Vector((0, 1, 0)), Vector((0, 0, 1))


def boxes_kit():
    """The boxes' own build module (their faces, atlas packer, material and room), loaded as a
    library: it imports a `spec` of its own, so ours is set aside while it loads."""
    mine = sys.modules.pop("spec")
    sys.path.insert(0, BOXES)
    try:
        s = importlib.util.spec_from_file_location("boxes_build", os.path.join(BOXES, "build.py"))
        mod = importlib.util.module_from_spec(s)
        s.loader.exec_module(mod)
    finally:
        sys.modules["boxes_spec"] = sys.modules.pop("spec", None)
        sys.modules["spec"] = mine
        sys.path.remove(BOXES)
    return mod


bk = boxes_kit()
BK = bk.K


def atlas():
    """{face key: (u0, v0, u1, v1)}: the boxes' atlas, packed exactly as their bake packed it."""
    rects, _ = bk.pack([bk.faces(n) for n in BK.ORDER] + [bk.marked_faces(False)])
    return rects


# --- geometry --------------------------------------------------------------------------------

def box_faces(skin, top_open, all_six):
    """A box's faces in its own frame (the boxes kit's: X long, Y across, Z up, the middle of its
    bottom at the origin, its long marked side facing -Y), as (key, o, r, up, w, h, bow, split).
    Twin faces wear their twin's texels, as the boxes do."""
    sides, top, size = K.SKINS[skin]
    b = BK.BOXES[size]
    w, d, h, bulge = b["w"], b["d"], b["h"], b["bulge"]
    n = K.SPLIT
    out = [
        (f"{sides}.front", Vector((-w / 2, -d / 2, 0)), X, Z, w, h, bulge, n),
        (f"{sides}.front", Vector((w / 2, d / 2, 0)), -X, Z, w, h, bulge, n),
        (f"{sides}.end", Vector((-w / 2, d / 2, 0)), -Y, Z, d, h, bulge, n),
        (f"{sides}.end", Vector((w / 2, -d / 2, 0)), Y, Z, d, h, bulge, n),
    ]
    sag = b["sag"] if top_open else 0.0
    out.append((f"{top}.top", Vector((-w / 2, -d / 2, h)), X, Y, w, d, -sag, n if top_open else 1))
    if all_six:
        out.append((f"{top}.top", Vector((-w / 2, d / 2, 0)), X, -Y, w, d, 0.0, 1))
    return out


def turned(turn, pose):
    """The box's turn as a 3x3 matrix: about up, after lying it down or letting it fall."""
    r = Matrix.Rotation(math.radians(turn), 3, "Z")
    if pose == "lying":
        return r @ Matrix.Rotation(math.radians(90.0), 3, "Y")
    if pose:
        rx, ry = pose
        return r @ Matrix.Rotation(math.radians(rx), 3, "X") @ Matrix.Rotation(math.radians(ry), 3, "Y")
    return r


def corners(size, rot):
    b = BK.BOXES[K.SKINS[size][2]]
    w, d, h = b["w"], b["d"], b["h"]
    return [rot @ Vector((sx * w / 2, sy * d / 2, z)) for sx in (-1, 1) for sy in (-1, 1) for z in (0, h)]


def lay(name):
    """Each box of a block placed: [(box, rot 3x3, offset)], in the block's frame."""
    blk = K.BLOCKS[name]
    front = -blk["depth"] / 2
    placed, tops = [], []
    for box, x, proud, turn, on, pose in blk["boxes"]:
        rot = turned(turn, pose)
        cs = corners(box, rot)
        lo = Vector([min(c[i] for c in cs) for i in range(3)])
        hi = Vector([max(c[i] for c in cs) for i in range(3)])
        base = 0.0 if on is None else tops[on]
        off = Vector((x - (lo.x + hi.x) / 2, front - proud - lo.y, base - lo.z))
        if blk["kind"] != "Toppled":
            # Nudged in to keep within the block's width, its bowed sides and all, so two blocks
            # side by side at their widths never run into each other.
            # (a box laid down shows its flat top and bottom to the sides)
            reach = 0.0 if pose else BK.BOXES[K.SKINS[box][2]]["bulge"]
            half = blk["width"] / 2
            off.x -= max(0.0, hi.x + off.x + reach - half)
            off.x += max(0.0, -half - (lo.x + off.x - reach))
        placed.append((box, rot, off))
        tops.append(hi.z + off.z)
    return placed


def block_mesh(name, rects):
    """One block's mesh: its boxes' faces, each a SPLIT x SPLIT grid (one quad where a box sits on
    it), bowed out at its middle, UV'd onto the box's own islands."""
    blk = K.BLOCKS[name]
    placed = lay(name)
    covered = {on for *_, on, _ in blk["boxes"] if on is not None}
    verts, polys, uvs = [], [], []
    for i, (box, rot, off) in enumerate(placed):
        pose = blk["boxes"][i][5]
        for key, o, r, up, w, h, bow, n in box_faces(box, i not in covered, pose is not None):
            u0, v0, u1, v1 = rects[key]
            nrm = r.cross(up).normalized()
            facing = (rot @ nrm).z
            if facing < -0.5 or (facing > 0.5 and i in covered):
                bow = 0.0  # flat on the floor, or under the box it holds up
            base = len(verts)
            for j in range(n + 1):
                for k in range(n + 1):
                    s, t = k / n, j / n
                    p = o + r * (s * w) + up * (t * h)
                    p += nrm * (bow * math.sin(math.pi * s) * math.sin(math.pi * t))
                    verts.append(rot @ p + off)
                    uvs.append((u0 + s * (u1 - u0), v0 + t * (v1 - v0)))
            for j in range(n):
                for k in range(n):
                    a = base + j * (n + 1) + k
                    polys.append((a, a + 1, a + n + 2, a + n + 1))
    me = bpy.data.meshes.new(name)
    me.from_pydata([tuple(v) for v in verts], [], polys)
    me.update()
    uv = me.uv_layers.new(name="UVMap")
    for poly in me.polygons:
        poly.use_smooth = True
        for li in poly.loop_indices:
            uv.data[li].uv = uvs[me.loops[li].vertex_index]
    me.set_sharp_from_angle(angle=math.radians(35))
    return me


def build_all(coll=None):
    rects = atlas()
    objs = {}
    for name in K.ORDER:
        ob = bpy.data.objects.new(name, block_mesh(name, rects))
        (coll or bpy.context.scene.collection).objects.link(ob)
        objs[name] = ob
    return objs


def check_overlaps(name):
    """No two standing boxes of a block share floor where their heights overlap (each box's
    footprint as its turned rectangle, by separating axes)."""
    placed = lay(name)
    rows = []
    for box, rot, off in placed:
        cs = [c + off for c in corners(box, rot)]
        rows.append((cs, min(c.z for c in cs), max(c.z for c in cs)))

    def axes(cs):
        flat = sorted({(round(c.x, 6), round(c.y, 6)) for c in cs})
        out = []
        for a in flat:
            for b in flat:
                e = (b[0] - a[0], b[1] - a[1])
                ln = math.hypot(*e)
                if ln > 1e-6:
                    out.append((-e[1] / ln, e[0] / ln))
        return out

    for i in range(len(rows)):
        for j in range(i + 1, len(rows)):
            (a, alo, ahi), (b, blo, bhi) = rows[i], rows[j]
            if min(ahi, bhi) - max(alo, blo) <= 0.02:
                continue
            apart = False
            for ax in axes(a) + axes(b):
                pa = [c.x * ax[0] + c.y * ax[1] for c in a]
                pb = [c.x * ax[0] + c.y * ax[1] for c in b]
                if min(max(pa), max(pb)) - max(min(pa), min(pb)) <= 0.02:
                    apart = True
                    break
            assert apart, f"{name}: boxes {i} and {j} overlap"


# --- export ---------------------------------------------------------------------------------

def to_roblox(v):
    """Blender's (x, y, z) to Roblox's, through the FBX's axes (as the boxes')."""
    return (-v[0], v[2], v[1])


def bounds(ob):
    vs = [v.co for v in ob.data.vertices]
    lo = [min(v[i] for v in vs) for i in range(3)]
    hi = [max(v[i] for v in vs) for i in range(3)]
    return lo, hi


def f3(v):
    return ", ".join(f"{c:.3f}" for c in v)


def write_luau(rows):
    lines = [
        "--!strict",
        "-- Generated by art/packed/build.py --stage export from art/packed/spec.py. Don't edit:",
        "-- change the spec and rebuild (scripts/art.sh packed).",
        "-- Studs, Roblox axes. A block is one MeshPart of moving boxes stacked as people stack them;",
        "-- its pivot is the middle of its footprint on the floor, its front (the side meant to face a",
        "-- path or the doorway) its LookVector. Width and Depth are the footprint it's laid by (blocks",
        "-- stand side by side at Pitch); Lo and Hi are how far its boxes really reach from the pivot,",
        "-- askew corners and all; Tall is its top.",
        "",
        "export type Kind = \"Column\" | \"Wide\" | \"Half\" | \"Toppled\"",
        "export type Block = {",
        "\tKind: Kind,",
        "\tWidth: number,",
        "\tDepth: number,",
        "\tTall: number,",
        "\tLo: Vector3,",
        "\tHi: Vector3,",
        "\tTris: number,",
        "}",
        "",
        "local Blocks: { [string]: Block } = {",
    ]
    for name in K.ORDER:
        r = rows[name]
        lines += [
            f"\t{name} = {{",
            f"\t\tKind = \"{r['kind']}\",",
            f"\t\tWidth = {r['width']:.3f},",
            f"\t\tDepth = {r['depth']:.3f},",
            f"\t\tTall = {r['tall']:.3f},",
            f"\t\tLo = Vector3.new({f3(r['lo'])}),",
            f"\t\tHi = Vector3.new({f3(r['hi'])}),",
            f"\t\tTris = {r['tris']},",
            "\t},",
        ]
    order = ", ".join(f"\"{n}\"" for n in K.ORDER)
    lines += [
        "}",
        "",
        "return {",
        f"\tCeiling = {K.CEILING:.3f}, -- the unit's steel top",
        f"\tPitch = {K.PITCH:.3f}, -- blocks stand side by side this far apart",
        "\tBlocks = Blocks,",
        f"\tOrder = {{ {order} }},",
        "}",
        "",
    ]
    os.makedirs(os.path.dirname(SPECS), exist_ok=True)
    with open(SPECS, "w") as f:
        f.write("\n".join(lines))


def plain():
    """The export's material: a plain colour, so the import brings no SurfaceAppearance and the
    game gives each block the boxes' own (Packed.prepare)."""
    return render.simple("Cardboard", (0.6, 0.45, 0.3, 1.0), rough=0.8)


def stage_export():
    bk.reset()
    K.check()
    for name in K.ORDER:
        check_overlaps(name)
    objs = build_all()
    mat = plain()
    rows = {}
    for i, (name, ob) in enumerate(objs.items()):
        ob.data.materials.append(mat)
        lo, hi = bounds(ob)
        blk = K.BLOCKS[name]
        assert hi[2] <= K.TOP_MAX + 1e-6, f"{name} reaches {hi[2]:.2f}, past {K.TOP_MAX}"
        assert lo[2] >= -1e-6, f"{name} goes under the floor"
        rl, rh = to_roblox(lo), to_roblox(hi)
        rows[name] = dict(
            kind=blk["kind"], width=blk["width"], depth=blk["depth"], tall=hi[2],
            lo=[min(a, b) for a, b in zip(rl, rh)], hi=[max(a, b) for a, b in zip(rl, rh)],
            tris=sum(len(p.vertices) - 2 for p in ob.data.polygons))
        ob.location.x = i * 6.0
    os.makedirs(OUT, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    for ob in objs.values():
        ob.select_set(True)
    bpy.context.view_layer.objects.active = objs[K.ORDER[0]]
    bpy.ops.export_scene.fbx(
        filepath=FBX, use_selection=True, object_types={"MESH"},
        apply_scale_options="FBX_SCALE_UNITS", axis_forward="Z", axis_up="Y",
        use_mesh_modifiers=True, mesh_smooth_type="OFF", use_tspace=False,
        add_leaf_bones=False, bake_anim=False, path_mode="COPY", embed_textures=False)
    print("FBX", FBX, {n: r["tris"] for n, r in rows.items()})
    write_luau(rows)
    print("SPEC", SPECS)


# --- look sheets ----------------------------------------------------------------------------

FACING = {"door": 0.0, "back": 180.0, "right": 90.0, "left": -90.0}


def set_block(ob, x, y, facing):
    """Stand a block with the middle of its front edge at (x, y), its front looking `facing`."""
    a = math.radians(FACING[facing])
    half = K.BLOCKS[ob.data.name.split(".")[0]]["depth"] / 2
    back = Vector((-math.sin(a), math.cos(a), 0.0))  # its +Y (into it) after the turn
    ob.location = Vector((x, y, 0.0)) + back * half
    ob.rotation_euler = (0.0, 0.0, a)


def room(coll):
    """The boxes' unit room, closed over by its steel top, with the front wall either side of an 8
    wide doorway and its header."""
    bk.unit_room(coll)
    part = bpy.data.materials.get("Partition")
    steel = render.simple("Top", (0.05, 0.05, 0.055, 1.0), rough=0.7, metal=0.6)
    m = geo.Mesh("room_top")
    geo.box(m, (-6.2, -0.2, 10.0), (6.2, 12.2, 10.2), geo.map_floor(8.0))
    m.build(coll).data.materials.append(steel)
    for nm, lo, hi in (("fl", (-6.2, -0.2, 0), (-4, 0, 10)), ("fr", (4, -0.2, 0), (6.2, 0, 10)),
                       ("hd", (-4, -0.2, 8), (4, 0, 10))):
        m = geo.Mesh(f"room_{nm}")
        geo.box(m, lo, hi, geo.map_wall(10.0))
        ob = m.build(coll)
        if part:
            ob.data.materials.append(part)


def marked_box(at, turn):
    parts = bk.build_marked(bpy.context.scene.collection)
    mat = bk.material(False)
    glow = render.emissive("Cue", (*[c / 255 for c in BK.CUE["rgb"]], 1.0), 6.0)
    pivot = bpy.data.objects.new("marked", None)
    bpy.context.scene.collection.objects.link(pivot)
    for nm, ob in parts.items():
        ob.data.materials.append(glow if nm == "Seam" else mat)
        ob.parent = pivot
    pivot.location = (at[0], at[1], 0.0)
    pivot.rotation_euler = (0.0, 0.0, math.radians(turn))


def lineup(objs, mat):
    """Every block in a row on a bare floor, a 5.5 stud figure for scale, lit flat."""
    render.world((0.03, 0.03, 0.035), 1.0)
    floor = bpy.data.meshes.new("floor")
    floor.from_pydata([(-40, -20, 0), (40, -20, 0), (40, 30, 0), (-40, 30, 0)], [], [(0, 1, 2, 3)])
    fo = bpy.data.objects.new("floor", floor)
    bpy.context.scene.collection.objects.link(fo)
    fo.data.materials.append(render.simple("Floor", (0.2, 0.2, 0.2, 1.0), rough=0.9))
    x = -15.0
    for name in K.ORDER:
        w = K.BLOCKS[name]["width"]
        ob = objs[name]
        ob.location = (x + w / 2, 0.0, 0.0)
        ob.rotation_euler = (0.0, 0.0, 0.0)
        x += w + 1.2
    me = geo.Mesh("figure")
    geo.box(me, (-0.5, -0.25, 0.0), (0.5, 0.25, 5.5), geo.map_wall(10.0))
    fo = me.build(bpy.context.scene.collection)
    fo.location = (x + 0.6, 0.0, 0.0)
    fo.data.materials.append(render.simple("Figure", (0.5, 0.52, 0.55, 1.0)))
    bk.light("key", "AREA", (-8.0, -22.0, 16.0), (0.0, 0.0, 4.0), 3000.0, (1.0, 0.96, 0.9), size=14.0)
    bk.light("fill", "AREA", (14.0, -14.0, 6.0), (0.0, 0.0, 4.0), 800.0, (0.85, 0.9, 1.0), size=10.0)
    cam = render.camera((0.0, -34.0, 7.0), (0.0, 0.0, 4.6), lens=30)
    render.shoot(cam, os.path.join(SHEETS, "packed-lineup.png"), exposure=0.0)


def stage_renders():
    bk.reset()
    render.setup(96, (1600, 900))
    objs = build_all()
    mat = bk.material(False)
    for ob in objs.values():
        ob.data.materials.append(mat)
    os.makedirs(SHEETS, exist_ok=True)
    lineup(objs, mat)

    # The packed unit: the blocks as the sample lays them (copies), the doorway and the torch.
    for o in list(bpy.context.scene.objects):
        if o.type == "LIGHT" or o.name in ("floor", "figure"):
            bpy.data.objects.remove(o)
    for ob in objs.values():
        ob.location.z = -50.0
    render.world((0.002, 0.0025, 0.004), 1.0)
    room(bpy.context.scene.collection)
    for name, x, y, facing in K.SAMPLE:
        ob = objs[name].copy()
        bpy.context.scene.collection.objects.link(ob)
        set_block(ob, x, y, facing)
    bx, by, bt = K.SAMPLE_BOX
    marked_box((bx, by), bt)
    bk.light("hall", "AREA", (0.0, -3.0, 9.0), (0.0, 3.0, 0.0), 60.0, (0.85, 0.92, 1.0), size=6.0)

    # 14.6 mm is Roblox's 70 degree view on a 16:9 screen; the eye at standing height.
    door = render.camera((0.6, -1.5, 4.6), (0.0, 9.0, 3.2), lens=14.6, name="door")
    render.flashlight(door, True, (0.0, 9.0, 2.0))
    render.shoot(door, os.path.join(SHEETS, "packed-door.png"), exposure=0.4)
    path = render.camera((-0.3, 3.6, 4.6), (0.7, 9.0, 3.8), lens=14.6, name="path")
    render.flashlight(path, True, (1.5, 6.6, 3.2))
    render.shoot(path, os.path.join(SHEETS, "packed-path.png"), exposure=0.4)
    bend = render.camera((0.4, 9.9, 4.6), (-4.5, 10.4, 1.0), lens=14.6, name="bend")
    render.flashlight(bend, True, (-2.6, 10.6, 0.8))
    render.shoot(bend, os.path.join(SHEETS, "packed-clearing.png"), exposure=0.4)


STAGES = {"export": stage_export, "renders": stage_renders}

if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--stage", choices=list(STAGES), required=True)
    STAGES[ap.parse_args(argv).stage]()
    print("DONE")
