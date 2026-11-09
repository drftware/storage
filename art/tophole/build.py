"""Build the sawn top in Blender, headless (art/tophole/README.md).

    blender -b --factory-startup -P art/tophole/build.py -- --stage textures|export|renders

Stages:
    textures  the TopHole texture set (the cut edges, the bent tongues, the channel's cut ends,
              the panel's rim), baked from the wall hole's recipe into out/textures
    export    out/TopHole.fbx and src/shared/StorageUnit/TopHole/Specs.luau
    renders   the look sheets, art/sheets/tophole-*.png

The wall hole's kit (art/hole/build.py) is loaded as a library with this folder's spec, so its
flat drawing, strips, cut faces, atlas packing and recipe are the same code; only the frame
differs: the wall hole stands its sheet out along X, the top lays it flat with its ribs up. The
holed tops wear the unit's own Partition set (art/unit/out/textures: build the unit first),
mapped exactly as the unit's `Top` is (art/unit/parts.py), so a holed top is the top it replaces.
"""

import argparse
import importlib.util
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
UNIT = os.path.join(HERE, "..", "unit")
HOLE = os.path.abspath(os.path.join(HERE, "..", "hole"))
sys.path.insert(0, UNIT)
sys.path.insert(0, HERE)  # first: this folder's spec.py

import bpy  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402

import bake  # noqa: E402
import geo  # noqa: E402
import parts as unit_parts  # noqa: E402
import render  # noqa: E402
import spec as K  # noqa: E402

OUT = os.path.join(HERE, "out")
TEX = os.path.join(OUT, "textures")
UNIT_TEX = os.path.join(UNIT, "out", "textures")
SHEETS = os.path.join(K.ROOT, "art", "sheets")
FBX = os.path.join(OUT, "TopHole.fbx")
SPECS = os.path.join(K.ROOT, "src", "shared", "StorageUnit", "TopHole", "Specs.luau")


def hole_kit():
    """The wall hole's build, as a library: it imports `spec`, which is already this folder's, so
    its folds, atlas size, set name and seed are the top's; the bake's out paths are pointed here."""
    s = importlib.util.spec_from_file_location("hole_build", os.path.join(HOLE, "build.py"))
    mod = importlib.util.module_from_spec(s)
    s.loader.exec_module(mod)
    assert mod.K is K, "the hole's build must see the top's spec"
    mod.kit.OUT, mod.kit.TEX, mod.kit.UVS, mod.kit.FBX = (OUT, TEX, os.path.join(OUT, "uvs.npz"),
                                                          FBX)
    return mod


hb = hole_kit()
kit = hb.kit
Part, fill, at_folds, sides, kerf, dist_to = (hb.Part, hb.fill, hb.at_folds, hb.sides, hb.kerf,
                                              hb.dist_to)
KERF, NEAR, FAR, TAB, TAB_EDGE, PANEL_KERF, PANEL_RIM = (hb.KERF, hb.NEAR, hb.FAR, hb.TAB,
                                                         hb.TAB_EDGE, hb.PANEL_KERF, hb.PANEL_RIM)
EDGES = ("Edge", "PanelEdge")  # the TopHole set's two pieces: the hole's, and the panel's


# --- the frame -------------------------------------------------------------------------------

def stand(s, dy=0.0):
    """A point of the front sheet: (x, y) up to face s (+1 the top, the saw's side; -1 the
    underside), `dy` added to y (a hole-frame point into a unit's frame)."""
    return lambda a, y: (a, y + dy, K.Z_SHEET + K.offset(a) + s * K.SHEET / 2)


def top_uv(size):
    """The front sheet's mapping, as `parts.flat_sheet` maps the unit's: (x, y) in the unit's
    frame to the Partition texture's clean upper band."""
    D = K.SIZES[size]["depth"]
    ya, yb = K.F + 0.02, (K.F + D) / 2 + K.LAP / 2
    v0 = K.TOP_BAND[0]
    scale = min(1.0, (K.TOP_BAND[1] - v0) * 10.0 / (yb - ya))
    return lambda a, y: (a / 4.0, v0 + (y - ya) * scale / 10.0), ya, yb


def crossings(ring_pts, y):
    """Where a closed ring crosses the line Y = y, left to right."""
    xs = []
    for (ax, ay), (bx, by) in zip(ring_pts, ring_pts[1:] + ring_pts[:1]):
        if (ay - y) * (by - y) < 0:
            xs.append(ax + (bx - ax) * (y - ay) / (by - ay))
    return sorted(xs)


def channel_cut(pts):
    """Where the saw went through the first channel: the cut's x each side (the hole's frame)."""
    xs = crossings(K.ring(pts, lambda q: q["wob"]), 0.0)
    return xs[0], xs[-1]


# --- the holed tops --------------------------------------------------------------------------

def holed_top(size, pts):
    """A `size` unit's top with the hole cut, as `parts.top` builds the plain one: the front sheet
    drawn flat round the hole, the back sheet lapped over it, the three channels, the first one
    sawn through where it crosses the hole."""
    s = K.U.Spec(size)
    W2, D, H = s.width / 2, s.depth, s.wall_height
    c = K.channel(size)
    p = Part(f"Top_{size}")
    uv, ya, yb = top_uv(size)
    rim = [(a, y + c) for a, y in K.ring(pts, lambda q: q["wob"] + q["band"])]
    flat, tris = fill([(-W2, ya), (W2, ya), (W2, yb), (-W2, yb)], [rim])
    for sd in (1, -1):
        p.sheet(flat, tris, stand(sd), sd < 0, uv=uv)
    m = p.m
    n = len(m.faces)
    t, z = K.SHEET, K.Z_SHEET

    def mapper(vs, nrm):
        return [uv(v.x, v.y) for v in vs]

    def add(v, want):
        if geo._normal([Vector(x) for x in v]).dot(want) < 0:
            v = v[::-1]
        geo.add_faces(m, v, [[0, 1, 2, 3]], mapper)

    rib = unit_parts.rib_points(-W2, W2)
    for (a, o), (b, ob) in zip(rib, rib[1:]):  # the front edge's closure strip
        add([(a, ya, z - t / 2), (b, ya, z - t / 2), (b, ya, z + ob + t / 2),
             (a, ya, z + o + t / 2)], Vector((0, -1, 0)))
    for x, sx in ((-W2, -1), (W2, 1)):
        add([(x, ya, z - t / 2), (x, yb, z - t / 2), (x, yb, z + t / 2), (x, ya, z + t / 2)],
            Vector((sx, 0, 0)))
    back = (K.F + D) / 2 - K.LAP / 2
    unit_parts.flat_sheet(m, -W2, W2, back, D, z + t + 0.004, K.TOP_BAND[0] + 0.02,
                          ends=(back,))
    chan = unit_parts.map_wall_along(H, 0)
    xl, xr = channel_cut(pts)
    lo, hi = K.CHANNEL_Z
    for k in (1, 2, 3):
        yk = K.F + (D - K.F) * k / 4
        y0, y1 = yk - K.CHANNEL_HALF, yk + K.CHANNEL_HALF
        if k == 1:
            geo.box(m, (-W2, y0, lo), (xl, y1, hi), chan, bevel=0.01)
            geo.box(m, (xr, y0, lo), (W2, y1, hi), chan, bevel=0.01)
        else:
            geo.box(m, (-W2, y0, lo), (W2, y1, hi), chan, bevel=0.01)
    p.kinds += [0] * (len(m.faces) - n)
    p.cut += [0.0] * (len(m.verts) - len(p.cut))
    return p


# --- the cut edge -----------------------------------------------------------------------------

def tab(p, pts, t, to3d=lambda v: v):
    """A tongue of steel left on the cut and bent down into the unit: a curled strip of the sheet,
    its root on the hole's outline, reaching in over the hole. (The wall hole's `tab`, laid flat.)"""
    n = len(pts)
    mid = round(t["at"] * n) % n
    k = max(1, round(t["root"] / 2 / K.STEP))
    cols = [pts[(mid + j) % n] for j in range(-k, k + 1)]
    bend = math.radians(t["bend"])
    phis = [0.0, bend * 0.4, bend]
    up, down = Vector((0.0, 0.0, 1.0)), Vector((0.0, 0.0, -1.0))
    rows = []
    for ci, q in enumerate(cols):
        u = (ci / (len(cols) - 1)) * 2 - 1
        reach = t["reach"] * (1.0 - 0.45 * u * u) * (0.85 + 0.3 * ((ci * 37) % 7) / 6)
        a, y = q["a"] + q["na"] * q["wob"], q["z"] + q["nz"] * q["wob"]
        root = Vector((a, y, K.Z_SHEET + K.offset(a)))
        inward = Vector((-q["na"], -q["nz"], 0.0))
        along = Vector((-q["nz"], q["na"], 0.0))
        col = []
        pos = root.copy()
        for r, phi in enumerate(phis):
            if r > 0:
                pos = pos + reach / (len(phis) - 1) * (math.cos(phi) * inward
                                                       + math.sin(phi) * down)
                if r == len(phis) - 1:
                    pos = pos - along * (u * reach * 0.35)
            col.append((pos.copy(), math.sin(phi) * inward + math.cos(phi) * up))
        rows.append(col)
    h = K.SHEET / 2
    last = len(phis) - 1
    cut_of = [0.03, 0.015, 0.0]
    front = [[p.vert(pp + nn * h, cut_of[r]) for r, (pp, nn) in enumerate(col)] for col in rows]
    back = [[p.vert(pp - nn * h, cut_of[r]) for r, (pp, nn) in enumerate(col)] for col in rows]
    for ci in range(len(rows) - 1):
        for r in range(last):
            want = sum((rows[c][rr][1] for c in (ci, ci + 1) for rr in (r, r + 1)), Vector())
            p.quad_idx((front[ci][r], front[ci + 1][r], front[ci + 1][r + 1], front[ci][r + 1]),
                       TAB, want)
            p.quad_idx((back[ci][r], back[ci + 1][r], back[ci + 1][r + 1], back[ci][r + 1]),
                       TAB, -want)
        out = ((rows[ci][last][0] + rows[ci + 1][last][0])
               - (rows[ci][last - 1][0] + rows[ci + 1][last - 1][0]))
        p.quad_idx((back[ci][last], back[ci + 1][last], front[ci + 1][last], front[ci][last]),
                   TAB_EDGE, out)
    for ci, other in ((0, 1), (len(rows) - 1, len(rows) - 2)):
        for r in range(last):
            out = rows[ci][r][0] - rows[other][r][0]
            p.quad_idx((back[ci][r], back[ci][r + 1], front[ci][r + 1], front[ci][r]),
                       TAB_EDGE, out)


def channel_end(p, x, facing, kind, at=lambda v: v, proud=0.003):
    """A sawn end of the channel: bright steel, standing `proud` off the box's own end."""
    lo, hi = K.CHANNEL_Z
    c = K.CHANNEL_HALF
    xx = x + facing * proud
    idx = [p.vert(tuple(at(Vector(v)))) for v in ((xx, -c, lo), (xx, c, lo), (xx, c, hi),
                                                  (xx, -c, hi))]
    want = at(Vector((x + facing, 0.0, lo))) - at(Vector((x, 0.0, lo)))
    p.quad_idx(idx, kind, want)


def lay():
    """Where the fallen panel goes, the hole's frame to the hole's frame: down to the floor face
    up, propped on the channel's stub (its back edge and the stub's back on the floor, so its
    front edge stands up a little), then slid aside and turned as it landed."""
    zb = K.Z_SHEET - K.SHEET / 2            # the underside's flats
    yb = K.Y1 - K.KERF                      # its back edge
    tilt = Matrix.Rotation(-math.atan2(zb - K.CHANNEL_Z[0], yb - K.CHANNEL_HALF), 4, "X")
    cx = (K.X0 + K.X1) / 2
    turn = Matrix.Rotation(math.radians(K.FALL_TURN), 4, "Z")
    return (Matrix.Translation((cx + K.FALL_SLIDE[0], yb + K.FALL_SLIDE[1], 0.0)) @ turn @ tilt
            @ Matrix.Translation((-cx, -yb, -zb)))


def edges(pts):
    """The TopHole set's two pieces in the hole's frame: `Edge` (the strips round the cut on both
    faces, the cut's faces, the tongues, the channel's sawn ends) stays with the top; `PanelEdge`
    (the fallen panel's rim and cut faces, its stub's sawn ends) falls with the panel."""
    e = Part("Edge")
    hole = K.ring(pts, lambda q: q["wob"])
    rim = K.ring(pts, lambda q: q["wob"] + q["band"])
    near = lambda q: dist_to(q, hole)  # noqa: E731
    for piece in sides(pts, hole, rim):
        flat, tris = fill(piece)
        e.sheet(flat, tris, stand(1), False, NEAR, near)
        e.sheet(flat, tris, stand(-1), True, FAR, near)
    hf = at_folds(hole)
    cx, cy = (K.X0 + K.X1) / 2, (K.Y0 + K.Y1) / 2
    kerf(e, hf, -1, 1, lambda a, y, s: stand(s)(a, y),
         lambda i: (cx - hf[i][0], cy - hf[i][1], 0.0), KERF)
    for t in K.TABS:
        tab(e, pts, t)
    xl, xr = channel_cut(pts)
    channel_end(e, xl, 1, KERF)
    channel_end(e, xr, -1, KERF)

    M = lay()
    pe = Part("PanelEdge")
    edge = K.ring(pts, lambda q: q["wob"] - K.KERF)
    inner = K.ring(pts, lambda q: q["wob"] - K.KERF - q["pband"])

    def fallen(s):
        return lambda a, y: tuple(M @ Vector(stand(s)(a, y)))

    for piece in sides(pts, edge, inner):
        flat, tris = fill(piece)
        pe.sheet(flat, tris, fallen(1), False, PANEL_RIM, lambda q: dist_to(q, edge))
    ef = at_folds(edge)
    ctr = M @ Vector((cx, cy, K.Z_SHEET))

    def outward(i):
        a, y = ef[i]
        return tuple(M @ Vector((a, y, K.Z_SHEET)) - ctr)

    kerf(pe, ef, -1, 1, lambda a, y, s: fallen(s)(a, y), outward, PANEL_KERF)
    channel_end(pe, xl + K.KERF, -1, PANEL_KERF, at=lambda v: M @ v)
    channel_end(pe, xr - K.KERF, 1, PANEL_KERF, at=lambda v: M @ v)
    return e, pe


def panel(pts):
    """The cut-out panel where it fell, in the unit's Partition (mapped as an M's top), the
    channel's stub under it."""
    M = lay()
    p = Part("Panel")
    uv_m, _, _ = top_uv("M")
    c = K.channel("M")
    uv = lambda a, y: uv_m(a, y + c)  # noqa: E731
    edge = K.ring(pts, lambda q: q["wob"] - K.KERF)
    inner = K.ring(pts, lambda q: q["wob"] - K.KERF - q["pband"])
    flat, tris = fill(inner)
    p.sheet(flat, tris, lambda a, y: tuple(M @ Vector(stand(1)(a, y))), False, uv=uv)
    flat, tris = fill(edge)
    p.sheet(flat, tris, lambda a, y: tuple(M @ Vector(stand(-1)(a, y))), True, uv=uv)
    xl, xr = channel_cut(pts)
    stub = geo.Mesh("stub")
    geo.box(stub, (xl + K.KERF, -K.CHANNEL_HALF, K.CHANNEL_Z[0]),
            (xr - K.KERF, K.CHANNEL_HALF, K.CHANNEL_Z[1]), unit_parts.map_wall_along(K.H, 0),
            bevel=0.01)
    p.m.extend(stub, M)
    return p


# --- building ---------------------------------------------------------------------------------

def unwrap(objs, pad=2):
    """The wall hole's unwrap for both pieces at once: smart-projected, then packed together by
    their real shapes, turned any way (long thin strips leave a box packing mostly empty)."""
    bpy.ops.object.select_all(action="DESELECT")
    for ob in objs:
        ob.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.context.scene.tool_settings.use_uv_select_sync = True
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(55), island_margin=0.0, area_weight=0.0,
                             correct_aspect=True, scale_to_bounds=False)
    bpy.ops.uv.pack_islands(rotate=True, rotate_method="ANY", scale=True, margin_method="FRACTION",
                            margin=pad / K.TEX, shape_method="CONCAVE")
    bpy.ops.object.mode_set(mode="OBJECT")
    clash = kit.clashes(objs)
    assert not clash, f"faces share texels in the atlas: {clash}"


def build_edges(baking, coll=None):
    """The TopHole set's objects."""
    e, pe = edges(K.outline())
    objs = {"Edge": e.build(coll), "PanelEdge": pe.build(coll)}
    kit.settle(list(objs.values()))
    if baking:
        unwrap(list(objs.values()))
        kit.keep_uvs(objs)
    else:
        kit.wear_uvs(objs)
        print(f"atlas: faces on unpainted texels {kit.unpainted(objs)}")
    print(f"atlas: {kit.density(list(objs.values())):.0f} texels a stud, "
          f"uv {kit.uv_hash(list(objs.values()))}")
    return objs


def build_partition(coll=None):
    """The holed tops (both sizes) and the fallen panel, in the unit's Partition."""
    pts = K.outline()
    objs = {}
    for size in K.SIZES:
        p = holed_top(size, pts)
        objs[p.m.name] = p.m.build(coll, sharp_angle=35.0)
    objs["Panel"] = panel(pts).m.build(coll, sharp_angle=35.0)
    return objs


def stage_textures():
    kit.reset()
    objs = build_edges(baking=True)
    kit.bake_set([(ob, bake.Rig(f"bk_{name}", hb.look)) for name, ob in objs.items()],
                 samples=32)


# --- export ---------------------------------------------------------------------------------

def stage_export():
    kit.reset()
    objs = build_edges(baking=False)
    mat = kit.material()
    for ob in objs.values():
        ob.data.materials.append(mat)
    sheets = build_partition()
    part_mat = bake.textured("Partition", UNIT_TEX, for_export=True)
    for ob in sheets.values():
        ob.data.materials.append(part_mat)
    objs.update(sheets)
    os.makedirs(OUT, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    for ob in objs.values():
        ob.select_set(True)
    bpy.context.view_layer.objects.active = objs["Top_M"]
    bpy.ops.export_scene.fbx(
        filepath=FBX, use_selection=True, object_types={"MESH"},
        apply_scale_options="FBX_SCALE_UNITS", axis_forward="Z", axis_up="Y",
        use_mesh_modifiers=True, mesh_smooth_type="OFF", use_tspace=False,
        add_leaf_bones=False, bake_anim=False, path_mode="COPY", embed_textures=True)
    rows = {name: hb.piece(ob) for name, ob in objs.items()}
    print("FBX", FBX, {n: r["tris"] for n, r in rows.items()})
    os.makedirs(os.path.dirname(SPECS), exist_ok=True)
    K.write_luau(SPECS, rows, lay())
    print("SPEC", SPECS)


# --- look sheets ----------------------------------------------------------------------------

def unit(cx, size, coll, sheets, edge_objs, hmat, pmat):
    """A `size` unit at x = cx: its shell, its shut door and drum, its holed top, the cut edge
    and the panel where it fell."""
    s = K.U.Spec(size)
    hb.room(cx, s, coll)
    door = bake.textured("DoorKit", UNIT_TEX)
    for m in (unit_parts.drum(s), unit_parts.hardware(s), unit_parts.curtain_closed(s),
              unit_parts.bottom_bar(s)):
        ob = m.build(coll)
        ob.location.x = cx
        ob.data.materials.append(door)
    ob = unit_parts.frame(s).build(coll)
    ob.location.x = cx
    ob.data.materials.append(bake.textured("TrimSheet", UNIT_TEX))
    c = K.channel(size)
    for name, ob in sheets.items():
        if name == f"Top_{size}":
            ob.location.x = cx
        elif name == "Panel":
            ob.location = (cx, c, 0.0)
        ob.data.materials.append(pmat)
    for ob in edge_objs.values():
        ob.location = (cx, c, 0.0)
        ob.data.materials.append(hmat)


def plain_top(cx, size, coll, pmat):
    ob = unit_parts.top(K.U.Spec(size)).build(coll)
    ob.location.x = cx
    ob.data.materials.append(pmat)


def stage_renders():
    """An M unit (x = 0) with its top sawn, a plain M each side; then an S the same way."""
    kit.reset()
    render.setup(96, (1600, 900))
    coll = bpy.context.scene.collection
    hmat = kit.material()
    pmat = bake.textured("Partition", UNIT_TEX)
    sheets = build_partition(coll)
    edge_objs = build_edges(baking=False, coll=coll)
    sheets["Top_S"].hide_render = True
    unit(0.0, "M", coll, {k: v for k, v in sheets.items() if k != "Top_S"}, edge_objs, hmat,
         pmat)
    for cx in (-12.0, 12.0):
        plain_top(cx, "M", coll, pmat)
    render.world((0.002, 0.0025, 0.004), 1.0)
    c = K.channel("M")
    hy = c + (K.Y0 + K.Y1) / 2  # the hole's middle, in the unit
    bulb = hb.bulb("bulb", (0.0, (K.F + 12.0) / 2, 8.7), True)
    # the hall's lights, above the tops: what shows through the hole from inside
    hall = bpy.data.lights.new("hall", "AREA")
    hall.size, hall.energy, hall.color = 10.0, 900.0, (1.0, 0.86, 0.66)
    ho = bpy.data.objects.new("hall", hall)
    coll.objects.link(ho)
    ho.location = (0.0, -6.0, 15.0)
    ho.rotation_euler = (math.radians(35), 0.0, 0.0)  # down, over the units

    # 1. lying at the hole's back edge, looking down and ahead: the cut, the unit lit below
    cam = render.camera((0.3, hy + 1.0, K.Z_SHEET + 0.7), (0.0, hy - 3.8, 5.0), lens=14.6)
    render.shoot(cam, os.path.join(SHEETS, "tophole-down-lit.png"), exposure=0.6)
    # 2. your head out over it looking straight down, the unit dark: your torch down the hole
    # (you paid for this look with the saw's noise). This close, the hole fills your view.
    cam = render.camera((0.3, hy + 0.45, K.Z_SHEET + 0.75), (0.0, hy - 0.6, 0.0), lens=14.6)
    bulb.hide_render = True
    render.flashlight(cam, True, (0.0, hy - 0.3, 0.0))
    render.shoot(cam, os.path.join(SHEETS, "tophole-down-torch.png"), exposure=0.3)
    render.flashlight(cam, False, (0.0, 0.0, 0.0))
    bulb.hide_render = False
    # 3. close, lying at its edge: the cut, the bright strips, the tongues bent down
    cam = render.camera((0.5, hy + 2.0, K.Z_SHEET + 0.6), (0.0, hy - 0.2, K.Z_SHEET - 0.6),
                        lens=24.0)
    render.shoot(cam, os.path.join(SHEETS, "tophole-close.png"), exposure=0.6)
    # 4. from the back of the unit, standing: the hole above the door, the panel on the floor
    cam = render.camera((-3.2, 10.6, 4.6), (0.4, hy - 0.4, 4.6), lens=12.0)
    render.shoot(cam, os.path.join(SHEETS, "tophole-inside.png"), exposure=0.7)
    # 5. under it, looking up: the tongues, the channel sawn through, the hall's light above
    cam = render.camera((0.8, hy + 2.6, 4.4), (0.0, hy, K.Z_SHEET), lens=20.0)
    render.shoot(cam, os.path.join(SHEETS, "tophole-up.png"), exposure=0.7)
    # 6. lying on the next top, 11 studs along: a crawler sees only a glint of the cut
    cam = render.camera((-11.0, hy + 6.0, K.Z_SHEET + 0.8), (0.0, hy, K.Z_SHEET), lens=14.6)
    render.shoot(cam, os.path.join(SHEETS, "tophole-along.png"), exposure=0.6)

    # 7. an S: the same hole, a small unit's top, from the steel behind it
    kit.reset()
    render.setup(96, (1600, 900))
    coll = bpy.context.scene.collection
    hmat = kit.material()
    pmat = bake.textured("Partition", UNIT_TEX)
    sheets = build_partition(coll)
    edge_objs = build_edges(baking=False, coll=coll)
    sheets["Top_M"].hide_render = True
    unit(0.0, "S", coll, {k: v for k, v in sheets.items() if k != "Top_M"}, edge_objs, hmat,
         pmat)
    for cx in (-8.0, 8.0):
        plain_top(cx, "S", coll, pmat)
    render.world((0.002, 0.0025, 0.004), 1.0)
    c = K.channel("S")
    hy = c + (K.Y0 + K.Y1) / 2
    hb.bulb("bulb", (0.0, (K.F + 8.0) / 2, 8.7), True)
    cam = render.camera((0.3, hy + 1.0, K.Z_SHEET + 0.7), (0.0, hy - 3.8, 5.0), lens=14.6)
    render.shoot(cam, os.path.join(SHEETS, "tophole-s-down.png"), exposure=0.6)
    cam = render.camera((-2.4, 7.2, 4.6), (0.3, hy - 0.4, 7.0), lens=12.0)
    render.shoot(cam, os.path.join(SHEETS, "tophole-s-inside.png"), exposure=0.7)


STAGES = {"textures": stage_textures, "export": stage_export, "renders": stage_renders}

if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--stage", choices=list(STAGES), required=True)
    STAGES[ap.parse_args(argv).stage]()
    print("DONE")
