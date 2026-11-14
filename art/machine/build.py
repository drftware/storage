"""Build the machine in the car in Blender, headless (art/machine/README.md).

    blender -b --factory-startup -P art/machine/build.py -- --stage textures|export|renders

Stages:
    textures  the Machine texture set, baked from its recipe into out/textures
    export    out/Machine.fbx (eight MeshParts) and src/shared/Machine/Specs.luau
    renders   the look sheets, art/sheets/machine-*.png (the car shots need the elevator built)

It borrows the finds' bake and export (art/finds/build.py), pointed at its own spec and out folder,
as the battery does, and the elevator's build for the car round it in the sheets.
"""

import argparse
import importlib.util
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
UNIT = os.path.join(HERE, "..", "unit")
FINDS = os.path.abspath(os.path.join(HERE, "..", "finds"))
ELEVATOR = os.path.abspath(os.path.join(HERE, "..", "elevator"))
sys.path.insert(0, UNIT)
sys.path.insert(0, HERE)  # first: this folder's spec.py

import bpy  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402

import bake  # noqa: E402
import geo  # noqa: E402
import render  # noqa: E402
import spec as K  # noqa: E402
from nodes import NB, hexc  # noqa: E402

OUT = os.path.join(HERE, "out")
TEX = os.path.join(OUT, "textures")
SHEETS = os.path.join(K.ROOT, "art", "sheets")
FBX = os.path.join(OUT, f"{K.SET}.fbx")
SPECS = os.path.join(K.ROOT, "src", "shared", "Machine", "Specs.luau")


def finds_kit():
    s = importlib.util.spec_from_file_location("finds_build", os.path.join(FINDS, "build.py"))
    mod = importlib.util.module_from_spec(s)
    s.loader.exec_module(mod)
    assert mod.K is K, "the finds' build must see the machine's spec"
    mod.OUT, mod.TEX, mod.UVS, mod.FBX = OUT, TEX, os.path.join(OUT, "uvs.npz"), FBX
    return mod


kit = finds_kit()

# What a face is, for the recipe (a face attribute).
(ENAMEL, STEEL, LINER, SHELF, BLACK, CHROME, PLATE, FLAP, IVORY) = range(9)

TEXTURED = ["Machine", "MachineCoil", "MachineButton", "MachineFlap"]
PLAIN = list(K.PLAIN)


# --- geometry --------------------------------------------------------------------------------

def box(F, kind, lo, hi, bevel=0.0, seg=1):
    lo, hi = [min(a, b) for a, b in zip(lo, hi)], [max(a, b) for a, b in zip(lo, hi)]
    F.add(kind, geo.box, tuple(lo), tuple(hi), None, bevel, seg)


def slab(m, xs, zs, solid, y0, y1):
    """A plate across X-Z, its face at y0 (toward -Y, the front), y1 - y0 deep, cut into a grid by
    xs and zs; solid(cx, cz) says which cells are plate. Its face and the walls round its edges
    and holes share their points; it has no back (the door's back is inside the cabinet)."""
    cache = {}

    def v(x, y, z):
        key = (round(x, 5), round(y, 5), round(z, 5))
        if key not in cache:
            cache[key] = m.vert((x, y, z))
        return cache[key]

    nx, nz = len(xs) - 1, len(zs) - 1
    cells = [[solid((xs[i] + xs[i + 1]) / 2, (zs[j] + zs[j + 1]) / 2) for j in range(nz)]
             for i in range(nx)]

    def at(i, j):
        return 0 <= i < nx and 0 <= j < nz and cells[i][j]

    for i in range(nx):
        for j in range(nz):
            if not cells[i][j]:
                continue
            x0, x1, z0, z1 = xs[i], xs[i + 1], zs[j], zs[j + 1]
            m.face((v(x0, y0, z0), v(x1, y0, z0), v(x1, y0, z1), v(x0, y0, z1)), None, False)
            if not at(i + 1, j):   # a wall facing +X
                m.face((v(x1, y0, z0), v(x1, y1, z0), v(x1, y1, z1), v(x1, y0, z1)), None, False)
            if not at(i - 1, j):   # facing -X
                m.face((v(x0, y0, z1), v(x0, y1, z1), v(x0, y1, z0), v(x0, y0, z0)), None, False)
            if not at(i, j + 1):   # facing +Z
                m.face((v(x0, y0, z1), v(x1, y0, z1), v(x1, y1, z1), v(x0, y1, z1)), None, False)
            if not at(i, j - 1):   # facing -Z
                m.face((v(x0, y1, z0), v(x1, y1, z0), v(x1, y0, z0), v(x0, y0, z0)), None, False)


def holed(F, kind, outer, holes, y0, y1):
    """A slab of `outer` (x0, x1, z0, z1) with rectangular `holes` cut through it."""
    xs = sorted({outer[0], outer[1]} | {h[0] for h in holes} | {h[1] for h in holes})
    zs = sorted({outer[2], outer[3]} | {h[2] for h in holes} | {h[3] for h in holes})

    def solid(cx, cz):
        return not any(h[0] < cx < h[1] and h[2] < cz < h[3] for h in holes)
    F.add(kind, slab, xs, zs, solid, y0, y1)


def inbox(m, lo, hi, front=False):
    """A box seen from inside: its faces toward its middle, the front (-Y) left open."""
    (x0, y0, z0), (x1, y1, z1) = lo, hi
    vs = [m.vert(p) for p in ((x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0),
                              (x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1))]
    a = lambda *ix: tuple(vs[i] for i in ix)  # noqa: E731
    m.face(a(3, 2, 6, 7), None, False)   # back, facing -Y
    m.face(a(0, 3, 7, 4), None, False)   # left, facing +X
    m.face(a(2, 1, 5, 6), None, False)   # right, facing -X
    m.face(a(4, 7, 6, 5), None, False)   # top, facing -Z
    m.face(a(0, 1, 2, 3), None, False)   # bottom, facing +Z
    if front:
        m.face(a(0, 4, 5, 1), None, False)


def quad_front(m, x0, x1, z0, z1, y):
    """One face toward -Y."""
    m.face((m.vert((x0, y, z0)), m.vert((x1, y, z0)), m.vert((x1, y, z1)), m.vert((x0, y, z1))),
           None, False)


def cull(F, hidden):
    """Drop the faces nobody can see, so the atlas spends its texels on the ones they can."""
    m = F.m
    keep = []
    for i, f in enumerate(m.faces):
        vs = [m.verts[j] for j in f]
        if not hidden(sum(vs, Vector()) / len(vs), geo._normal(vs)):
            keep.append(i)
    m.faces = [m.faces[i] for i in keep]
    m.uvs = [m.uvs[i] for i in keep]
    m.smooth = [m.smooth[i] for i in keep]
    F.kinds = [F.kinds[i] for i in keep]


def hidden(c, n):
    """Against the car's wall, on the floor, between the cabinet's panels, or under a shelf."""
    side = K.W / 2 - K.SHELL
    if n.y > 0.9 and c.y > K.D / 2 - 0.05:
        return True                                   # the back, against the wall
    if n.z < -0.9 and c.z < K.PLINTH[0] + 0.01:
        return True                                   # undersides on the floor
    if n.z > 0.9 and abs(c.z - K.PLINTH[0]) < 0.005:
        return True                                   # the plinth's top, under the cabinet
    if abs(n.x) > 0.9 and abs(abs(c.x) - side) < 0.005:
        return True                                   # between the side panels and what they hold
    if n.z > 0.9 and abs(c.z - (K.H - K.SHELL)) < 0.005 and abs(c.x) < side:
        return True                                   # the door's top, under the cap
    lx, ly0, ly1, lz0, lz1 = K.LINER
    inside = abs(c.x) < -lx + 0.01 and ly0 - 0.01 < c.y < ly1 + 0.01 and lz0 - 0.01 < c.z < lz1
    if n.z < -0.9 and inside and c.z < lz1 - 0.01 and c.y > K.SHELF[0] + 0.02:
        return True                                   # a shelf's underside: you look down on it
    if n.z > 0.9 and abs(c.z - lz0) < 0.005:
        return True                                   # the liner's floor, behind the bottom rail
    return False


def machine_geo():
    """The cabinet, the door, the rails and everything behind the glass: one MeshPart."""
    F = kit.Find("Machine")
    w, d, h, s = K.W / 2, K.D / 2, K.H, K.SHELL
    face = K.FRONT - 0.04   # the cabinet's sides and cap stand a little proud of the door
    # the cabinet: two sides, the cap, the plinth
    for sx in (-1, 1):
        box(F, ENAMEL, (sx * w, face, 0.0), (sx * (w - s), d, h), K.BEVEL)
    box(F, ENAMEL, (-(w - s), face, h - s), (w - s, d, h), K.BEVEL)
    box(F, BLACK, (-(w - s), K.FRONT + K.PLINTH[1], 0.0), (w - s, d, K.PLINTH[0]))

    # the door: one plate with the window, the flap, the sign and the return cup cut through it
    wx0, wx1 = K.WINDOW
    fx0, fx1, fz0, fz1 = K.FLAP
    sx0, sx1, sz0, sz1 = K.SIGN
    cx, cz, cw, ch = K.CUP
    cup = (cx - cw / 2, cx + cw / 2, cz - ch / 2, cz + ch / 2)
    holed(F, ENAMEL, (-(w - s), w - s, K.PLINTH[0], h - s),
          [(wx0, wx1, K.ROWS[0][0], K.WINDOW_TOP), (fx0, fx1, fz0, fz1), (sx0, sx1, sz0, sz1), cup],
          K.FRONT, K.FRONT + K.DOOR)

    # the coin plate, its slot's chrome boss and the slot, and the return cup's back
    px0, px1, pz0, pz1 = K.PLATE
    holed(F, PLATE, (px0, px1, pz0, pz1), [cup], K.FRONT - K.PLATE_T, K.FRONT)
    bx, bz, br = K.SLOT
    boss_y = K.FRONT - K.PLATE_T - 0.025
    F.add(CHROME, geo.cylinder, "y", (bx, boss_y, bz), br, 0.05, 20, None, True, False, 0.012)
    box(F, BLACK, (bx - 0.028, boss_y - 0.028, bz - 0.11), (bx + 0.028, boss_y - 0.022, bz + 0.11))
    F.add(BLACK, quad_front, cup[0], cup[1], cup[2], cup[3], K.FRONT + 0.1)

    # the bin behind the flap
    F.add(BLACK, inbox, (fx0, K.FRONT + K.DOOR, fz0), (fx1, K.BIN_BACK, fz1))

    # inside: the white liner, the shelves with their lips, the dividers, the motor boxes
    lx, ly0, ly1, lz0, lz1 = K.LINER
    F.add(LINER, inbox, (lx, ly0, lz0), (-lx, ly1, lz1))
    sy, st, lip = K.SHELF
    rows = K.rows()
    for r, row in enumerate(rows):
        top = row["shelf"]
        box(F, SHELF, (lx, sy, top - st), (-lx, ly1, top))
        box(F, SHELF, (lx, sy, top), (-lx, sy + 0.03, top + lip))
        roof = rows[r + 1]["shelf"] - st if r + 1 < len(rows) else lz1
        box(F, SHELF, (-K.DIVIDER / 2, sy + 0.12, top), (K.DIVIDER / 2, ly1, roof))
    mw, md, mh = K.MOTOR
    for b in K.bays():
        box(F, BLACK, (b["x"] - mw / 2, ly1 - md, b["shelf"]), (b["x"] + mw / 2, ly1, b["shelf"] + mh))
        F.add(CHROME, geo.cylinder, "y", (b["x"], ly1 - md - 0.02, b["coil"]), 0.085, 0.04, 14, None,
              True, False)

    # the tubes' sockets, either end of each tube
    for row in rows:
        tz = row["top"] - 0.08
        for sx in (-1, 1):
            x0 = sx * (K.TUBE_X + 0.01)
            box(F, BLACK, (x0, K.TUBE_Y - 0.055, tz - 0.08), (sx * (-lx - 0.005), K.TUBE_Y + 0.055, tz + 0.08))

    # the rails across the glass, each bay's price window bezel and its button's collar
    ry0, ry1 = K.RAIL_Y
    pdx, pw, ph = K.PRICE
    pb = K.PRICE_BEZEL
    for row in rows:
        box(F, STEEL, (wx0 - 0.08, ry0, row["bottom"]), (wx1 + 0.08, ry1, row["rail"]))
    for b in K.bays():
        px, z = b["x"] + pdx, b["rail"]
        holed(F, BLACK, (px - pw / 2 - pb, px + pw / 2 + pb, z - ph / 2 - pb, z + ph / 2 + pb),
              [(px - pw / 2, px + pw / 2, z - ph / 2, z + ph / 2)], ry0 - 0.04, ry0)
        br_, bd = K.BUTTON_BEZEL
        F.add(BLACK, geo.cylinder, "y", (b["x"] + K.BUTTON[0], ry0 - bd / 2, z), br_, bd, 20, None,
              True, False)
    cull(F, hidden)
    return F


def coil_geo():
    """One chrome coil along Y, its axis through the origin, its middle there: a helix from the
    front, then its tail bending in to the motor's hub at the back."""
    F = kit.Find("MachineCoil")
    y0, y1 = K.COIL_Y
    mid = (y0 + y1) / 2
    yh = y1 - 0.14
    n = int(K.COIL_TURNS * K.COIL_STEPS)
    path = []
    for k in range(n + 1):
        a = 2 * math.pi * K.COIL_TURNS * k / n - math.pi / 2
        path.append((K.COIL_R * math.cos(a), y0 + (yh - y0) * k / n - mid, K.COIL_R * math.sin(a)))
    ae = 2 * math.pi * K.COIL_TURNS - math.pi / 2
    path += [(0.45 * K.COIL_R * math.cos(ae), yh + 0.06 - mid, 0.45 * K.COIL_R * math.sin(ae)),
             (0.0, yh + 0.11 - mid, 0.0), (0.0, y1 - mid, 0.0)]
    F.add(CHROME, geo.sweep, path, K.COIL_WIRE, K.COIL_SEGS)
    return F


def button_geo():
    """A chunky push button, its back at the origin, standing out toward -Y: a chrome collar and a
    domed ivory face."""
    F = kit.Find("MachineButton")
    _, r, length = K.BUTTON
    F.add(CHROME, geo.cylinder, "y", (0.0, -0.025, 0.0), r, 0.05, 24, None, True, False, 0.01)
    F.add(IVORY, geo.cylinder, "y", (0.0, -0.05 - (length - 0.05) / 2, 0.0), r - 0.018,
          length - 0.05, 24, None, True, False, 0.02)
    return F


def flap_geo():
    """The bin's push flap, hung from its top edge: the hinge's middle is the origin. A painted
    steel plate with a pull lip at its foot and two knuckles at its head."""
    F = kit.Find("MachineFlap")
    fx0, fx1, fz0, fz1 = K.FLAP
    fw, fh, t = fx1 - fx0 - 0.04, fz1 - fz0 - 0.03, K.FLAP_T
    box(F, FLAP, (-fw / 2, -t / 2, -fh), (fw / 2, t / 2, -0.02), 0.012)
    box(F, STEEL, (-0.45, -t / 2 - 0.05, -fh), (0.45, -t / 2, -fh + 0.07), 0.012)
    for sx in (-1, 1):
        F.add(CHROME, geo.cylinder, "x", (sx * (fw / 2 - 0.2), 0.0, -0.02), 0.032, 0.22, 12, None,
              True, True)
    return F


def plain_geo(name):
    """The untextured parts, in the machine's frame."""
    m = geo.Mesh(name)
    if name == "MachineGlass":
        geo.box(m, (K.WINDOW[0], K.GLASS_Y, K.ROWS[0][0]), (K.WINDOW[1], K.GLASS_Y + 0.01, K.WINDOW_TOP))
    elif name == "MachineTubes":
        for row in K.rows():
            geo.cylinder(m, "x", (0.0, K.TUBE_Y, row["top"] - K.TUBE_DROP), K.TUBE_R, 2 * K.TUBE_X, 10)
    elif name == "MachinePrices":
        pdx, pw, ph = K.PRICE
        for b in K.bays():
            px, z = b["x"] + pdx, b["rail"]
            geo.box(m, (px - pw / 2, K.PRICE_Y, z - ph / 2), (px + pw / 2, K.PRICE_Y + 0.01, z + ph / 2))
    elif name == "MachineSign":
        sx0, sx1, sz0, sz1 = K.SIGN
        geo.box(m, (sx0, K.SIGN_Y[0], sz0), (sx1, K.SIGN_Y[1], sz1))
    return m


GEO = {"Machine": machine_geo, "MachineCoil": coil_geo, "MachineButton": button_geo,
       "MachineFlap": flap_geo}
SHARP = {"Machine": 30, "MachineCoil": 60, "MachineButton": 40, "MachineFlap": 30}


INSIDE = 0.55  # the liner's and shelves' texels a stud, of the rest's: they're seen through glass


def thin(o):
    """Shrink the liner's and the shelves' islands before the pack (every island is its own kind's,
    so scaling them about the origin only moves them, and the pack places them anyway)."""
    me = o.data
    attr = me.attributes.get("kind")
    if attr is None:
        return
    kinds = [0.0] * len(me.polygons)
    attr.data.foreach_get("value", kinds)
    lay = me.uv_layers.active.data
    for p, k in zip(me.polygons, kinds):
        if round(k) in (LINER, SHELF):
            for i in p.loop_indices:
                lay[i].uv = lay[i].uv * INSIDE
    me.update()


def unwrap(objs, pad=4):
    """Each part smart-projected alone, then every island packed together at one shared scale
    (the elevator's way), so the coil's wire and the cabinet keep the same texels a stud."""
    for o in objs:
        bpy.ops.object.select_all(action="DESELECT")
        o.select_set(True)
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.0, area_weight=0.0,
                                 correct_aspect=True, scale_to_bounds=False)
        bpy.ops.object.mode_set(mode="OBJECT")
        thin(o)
    ts = bpy.context.scene.tool_settings
    ts.use_uv_select_sync = True
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.pack_islands(rotate=True, rotate_method="CARDINAL", scale=True, margin_method="FRACTION",
                            margin=pad / K.TEX, shape_method="CONCAVE")
    bpy.ops.object.mode_set(mode="OBJECT")
    clash = kit.clashes(objs)
    assert not clash, f"faces share texels in the atlas: {clash}"


def build_all(baking, coll=None):
    objs = {n: GEO[n]().build(SHARP[n], coll) for n in TEXTURED}
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


def build_plain(coll=None):
    out = {}
    for n in PLAIN:
        ob = plain_geo(n).build(coll, sharp_angle=30)
        ob.data.materials.append(render.simple(f"plain_{n}", K.PLAIN[n], 0.3))
        out[n] = ob
    return out


def box_of(ob):
    vs = [v.co for v in ob.data.vertices]
    return (Vector([min(v[i] for v in vs) for i in range(3)]),
            Vector([max(v[i] for v in vs) for i in range(3)]))


# --- the recipe --------------------------------------------------------------------------------

def look(nb):
    """A supply machine that has ridden this car for years: oxblood enamel gone a little chalky,
    chipped to grey primer and then to steel on every edge a cart or a boot has hit, scuffed along
    its foot; brushed steel rails smudged round the buttons; a white liner yellowed and grimed in
    its corners; galvanized shelves; black plastic worn shiny where hands go."""
    L = kit.Look(nb, K.SEED)
    x, y, z = L.x, L.y, L.z
    enamel, steel, liner, shelf = L.k(ENAMEL), L.k(STEEL), L.k(LINER), L.k(SHELF)
    black, chrome, plate, flap, ivory = L.k(BLACK), L.k(CHROME), L.k(PLATE), L.k(FLAP), L.k(IVORY)

    # oxblood enamel, a little uneven and chalky where it faced the lamp for years
    ox = nb.tint(hexc("#5A1814"), nb.mr(L.noise(3.0, 1, detail=4), 0.3, 0.7, 0.82, 1.12))
    ox = nb.mixc(nb.mul(L.up, 0.25), ox, hexc("#7A3A33"))
    C = kit.Coat(L, ox, nb.mr(L.noise(6.0, 2, detail=3), 0.3, 0.7, 0.36, 0.52), 0.0)

    # where it's been hit: exposed edges and a band along its foot, chipped through the enamel to
    # grey primer, the deepest chips through to steel, a few of those rusting
    ao = nb.ao(0.08, local=True)
    edge = nb.mul(nb.edge(0.02, k=5.0), nb.ss(ao, 0.55, 0.85))
    foot = nb.mul(nb.ss(z, 0.95, 0.35), nb.ss(nb.mul(L.ny, -1.0), 0.3, 0.7))
    hit = nb.add(nb.mul(edge, 0.85), nb.mul(foot, 0.55), clamp=True)
    chip_n = L.noise(26.0, 3, detail=3, rough=0.65)
    chip = nb.mul(enamel, nb.ss(nb.add(chip_n, nb.mul(hit, 0.42)), 0.86, 0.9))
    deep = nb.mul(enamel, nb.ss(nb.add(chip_n, nb.mul(hit, 0.42)), 0.95, 0.98))
    C.paint(chip, hexc("#77746D"), 0.7, 0.0, height=-0.25)
    C.paint(deep, hexc("#8E9194"), 0.42, 0.9, height=-0.4)
    rust = nb.mul(deep, nb.ss(L.noise(9.0, 4, detail=3), 0.55, 0.62))
    C.paint(rust, hexc("#5C3520"), 0.85, 0.2)
    # scuffs and long scratches on the enamel: pale where a cart's corner dragged along it
    scr = nb.ss(L.noise(60.0, 5, stretch=(0.06, 1.0, 1.0), detail=1), 0.76, 0.8)
    scr2 = nb.ss(L.noise(50.0, 6, stretch=(1.0, 1.0, 0.07), detail=1), 0.77, 0.81)
    scuffed = nb.mul(enamel, nb.mul(nb.add(scr, scr2, clamp=True),
                                    nb.ss(L.noise(2.0, 7, detail=2), 0.45, 0.6)))
    C.paint(nb.mul(scuffed, 0.6), hexc("#8A5A52"), 0.6)

    # brushed steel rails, smudged dark round the buttons where thumbs land
    brushed = nb.tint(hexc("#C4C7C9"), nb.mr(L.noise(80.0, 8, stretch=(0.02, 1.0, 1.0), detail=2),
                                             0.3, 0.7, 0.86, 1.06))
    C.paint(steel, brushed, nb.mr(L.noise(40.0, 9, stretch=(0.03, 1.0, 1.0), detail=2), 0.3, 0.7,
                                  0.3, 0.46), 0.7)
    smudge = nb.mul(steel, nb.ss(L.noise(5.0, 10, detail=3), 0.5, 0.7))
    C.paint(nb.mul(smudge, 0.5), hexc("#6E7072"), 0.55)

    # the coin plate: darker brushed steel, a ring worn bright round the slot's boss
    pl = nb.tint(hexc("#9A9EA0"), nb.mr(L.noise(90.0, 11, stretch=(1.0, 1.0, 0.02), detail=2),
                                        0.3, 0.7, 0.85, 1.05))
    C.paint(plate, pl, 0.38, 1.0)
    bx, bz, br = K.SLOT
    ring = nb.mul(plate, nb.band(L.dist(nb.sub(x, bx), nb.sub(z, bz)), br, br + 0.05, 0.02))
    C.paint(ring, hexc("#C9CCCE"), 0.25)

    # the white liner, yellowed, grimy in its corners and behind the coils
    cream = nb.tint(hexc("#B8B3A3"), nb.mr(L.noise(4.0, 12, detail=4), 0.3, 0.7, 0.86, 1.02))
    C.paint(liner, cream, 0.62, 0.0)
    grime = nb.mul(liner, nb.ss(ao, 0.85, 0.4))
    C.paint(grime, hexc("#5E574A"), 0.8)

    # galvanized shelves: the zinc's spangle, a little dull; scuffed along their lips
    spangle = nb.voronoi(L.vec(s=13), 24.0, out="Color")
    zinc = nb.tint(hexc("#A3A8AA"), nb.mr(nb.gray(spangle), 0.0, 1.0, 0.86, 1.08))
    C.paint(shelf, zinc, nb.mr(nb.gray(spangle), 0.0, 1.0, 0.32, 0.5), 0.85)

    # black: powder-coated steel and plastic, worn to a dull shine on its edges
    C.paint(black, hexc("#141414"), 0.62, 0.0)
    C.paint(nb.mul(black, nb.mul(edge, 0.7)), hexc("#2C2C2C"), 0.4)

    # the flap: dark grey painted steel, rubbed bright in a patch at its foot where hands push
    C.paint(flap, hexc("#2B2D2F"), 0.55, 0.3)
    push = nb.mul(flap, nb.mul(nb.ss(z, -0.35, -0.7), nb.ss(nb.absf(x), 0.9, 0.2)))
    C.paint(nb.mul(push, nb.ss(L.noise(30.0, 14, detail=3), 0.35, 0.6)), hexc("#76797C"), 0.35, 0.8)

    C.chrome(chrome, s=15)
    C.paint(ivory, nb.tint(hexc("#E6DBC2"), nb.mr(L.noise(20.0, 16, detail=2), 0.3, 0.7, 0.9, 1.02)),
            0.3, 0.0)
    C.finish(ao=0.12, ao_low=0.5, dust=K.DUST)
    return C.channels(dist=0.002, strength=0.6)


def rig(name):
    r = bake.Rig(f"bk_{name}", look)
    bump = r.bsdf.inputs["Normal"].links[0].from_node
    bev = r.nb.node("ShaderNodeBevel", samples=8)
    r.nb.put(bev.inputs[0], 0.012)
    r.nb.links.new(bev.outputs[0], bump.inputs["Normal"])
    return r


def stage_textures():
    kit.reset()
    objs = build_all(baking=True)
    for i, ob in enumerate(objs.values()):
        ob.location.x = i * 8.0
    kit.bake_set([(ob, rig(n)) for n, ob in objs.items()], samples=32, pad=4)


# --- export ---------------------------------------------------------------------------------

def stage_export():
    kit.reset()
    objs = build_all(baking=False)
    mat = kit.material()
    for ob in objs.values():
        ob.data.materials.append(mat)
    objs.update(build_plain())
    parts = {}
    for name, ob in objs.items():
        lo, hi = box_of(ob)
        s = hi - lo
        parts[name] = dict(size=(s.x, s.z, s.y), centre=tuple((lo + hi) / 2), tris=kit.tris(ob))
    os.makedirs(OUT, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    for ob in objs.values():
        ob.select_set(True)
    bpy.context.view_layer.objects.active = objs["Machine"]
    bpy.ops.export_scene.fbx(
        filepath=FBX, use_selection=True, object_types={"MESH"},
        apply_scale_options="FBX_SCALE_UNITS", axis_forward="Z", axis_up="Y",
        use_mesh_modifiers=True, mesh_smooth_type="OFF", use_tspace=False,
        add_leaf_bones=False, bake_anim=False, path_mode="COPY", embed_textures=True)
    print("FBX", FBX, {n: p["tris"] for n, p in parts.items()})
    os.makedirs(os.path.dirname(SPECS), exist_ok=True)
    K.write_luau(SPECS, parts)


# --- look sheets ----------------------------------------------------------------------------

def elevator_kit():
    """The elevator's own build module (its spec, its finds kit), for the car round the machine."""
    mine = sys.modules.pop("spec")
    sys.path.insert(0, ELEVATOR)
    try:
        s = importlib.util.spec_from_file_location("elevator_build", os.path.join(ELEVATOR, "build.py"))
        mod = importlib.util.module_from_spec(s)
        s.loader.exec_module(mod)
    finally:
        sys.modules["elevator_spec"] = sys.modules.pop("spec", None)
        sys.modules["spec"] = mine
        sys.path.remove(ELEVATOR)
    return mod


def copy(ob, matrix):
    o = ob.copy()
    bpy.context.scene.collection.objects.link(o)
    o.matrix_world = matrix
    o.hide_render = False
    return o


def assemble(objs, at):
    """The machine whole at `at` (a Blender matrix): a coil and a button in every bay, the flap
    hung. Returns every object placed."""
    out = []
    for n in ("Machine",) + tuple(PLAIN):
        objs[n].matrix_world = at
        out.append(objs[n])
    mid = (K.COIL_Y[0] + K.COIL_Y[1]) / 2
    for b in K.bays():
        out.append(copy(objs["MachineCoil"], at @ Matrix.Translation((b["x"], mid, b["coil"]))))
        out.append(copy(objs["MachineButton"], at @ Matrix.Translation(
            (b["x"] + K.BUTTON[0], K.RAIL_Y[0] - K.BUTTON_BEZEL[1], b["rail"]))))
    fx0, fx1, _, fz1 = K.FLAP
    objs["MachineFlap"].matrix_world = at @ Matrix.Translation(((fx0 + fx1) / 2, K.GLASS_Y - 0.01, fz1))
    out.append(objs["MachineFlap"])
    objs["MachineCoil"].hide_render = True
    objs["MachineButton"].hide_render = True
    return out


def light_up(objs, on):
    """Lit as the game lights it: the tubes cold white, the price windows red, the sign; the glass
    a thin pane. Dark: the tubes grey glass, the windows black, the sign dull."""
    for n, col, k in (("MachineTubes", (0.82, 0.92, 1.0), 14.0), ("MachinePrices", (1.0, 0.07, 0.03), 4.0),
                      ("MachineSign", (1.0, 0.93, 0.78), 3.0)):
        ob = objs[n]
        ob.data.materials.clear()
        if on:
            ob.data.materials.append(render.emissive(f"glow_{n}", col, k))
        else:
            ob.data.materials.append(render.simple(f"dark_{n}", K.PLAIN[n], 0.3))
        ob.visible_shadow = False
    g = objs["MachineGlass"]
    g.data.materials.clear()
    m = bpy.data.materials.get("machine_glass") or bpy.data.materials.new("machine_glass")
    nb = NB(m)
    b = nb.node("ShaderNodeBsdfPrincipled")
    nb.put(b.inputs["Base Color"], (0.8, 0.86, 0.9))
    nb.put(b.inputs["Roughness"], 0.04)
    nb.put(b.inputs["Alpha"], 0.18)
    o = nb.node("ShaderNodeOutputMaterial")
    nb.links.new(b.outputs[0], o.inputs[0])
    g.data.materials.append(m)
    g.visible_shadow = False


def machine_lights(at, on):
    """The two lights the game gives it while it's awake: one into the bays, one spilling out of
    the glass into the car (cold fluorescent)."""
    out = []
    for name, loc, rot, size, energy in (
            ("bays", (0.0, K.TUBE_Y + 0.1, 3.6), (math.radians(90), 0, 0), (3.8, 2.6), 10.0),
            ("spill", (0.0, K.GLASS_Y - 0.15, 3.6), (math.radians(-90), 0, 0), (3.8, 3.4), 90.0)):
        ld = bpy.data.lights.get(name) or bpy.data.lights.new(name, "AREA")
        ld.shape = "RECTANGLE"
        ld.size, ld.size_y = size
        ld.energy = energy if on else 0.0
        ld.color = (0.8, 0.9, 1.0)
        ob = bpy.data.objects.get(name) or bpy.data.objects.new(name, ld)
        if ob.name not in bpy.context.scene.collection.objects:
            bpy.context.scene.collection.objects.link(ob)
        ob.matrix_world = at @ Matrix.Translation(loc) @ Matrix.Rotation(rot[0], 4, "X")
        out.append(ob)
    return out


def stage_renders():
    kit.reset()
    render.setup(96, (1600, 900))
    coll = bpy.context.scene.collection
    objs = build_all(baking=False)
    mat = kit.material()
    for ob in objs.values():
        ob.data.materials.append(mat)
    objs.update(build_plain(coll))
    os.makedirs(SHEETS, exist_ok=True)

    # 1. in the studio, three-quarter, awake
    studio = render.studio_rig()
    for o in studio:
        o.hide_render = False
    here = Matrix.Identity(4)
    placed = assemble(objs, here)
    light_up(objs, True)
    machine_lights(here, True)
    cam = render.camera((-7.0, -12.0, 5.0), (0.0, 0.0, 3.3), lens=35)
    render.shoot(cam, os.path.join(SHEETS, "machine-studio.png"), exposure=-0.6)
    for o in studio:
        o.hide_render = True
    for o in placed:
        if o.name not in objs:
            bpy.data.objects.remove(o)

    # the car round it: the elevator's build, its lamp lit, the gate shut
    ek = elevator_kit()
    car = ek.build_all(coll)
    ek.glow(car)
    for n in ("GatePicket", "GateLead", "GateStrap", "Note"):
        car[n].hide_render = True
    ek.gate(car, 1.0)
    ek.lobby(coll)
    ek.lights()
    render.world((0.002, 0.0025, 0.004), 1.0)
    at = Matrix.Translation(K.IN_CAR)
    assemble(objs, at)
    machine_lights(at, True)

    # 2. aboard, by the gate, as the ride starts: the machine awake in the back corner, cold light
    #    on the floor in front of it (14.6 mm is Roblox's 70 degree view on a 16:9 phone)
    cam = render.camera((-3.2, 2.2, 4.6), (2.8, 10.0, 3.4), lens=14.6)
    render.shoot(cam, os.path.join(SHEETS, "machine-car.png"), exposure=0.3)

    # 3. the same, dark: the first ride, or standing at a floor
    light_up(objs, False)
    machine_lights(at, False)
    render.shoot(cam, os.path.join(SHEETS, "machine-dark.png"), exposure=0.3)

    # 4. stepping up to it, awake: the rails, the windows and the buttons at arm's length
    light_up(objs, True)
    machine_lights(at, True)
    cam = render.camera((K.IN_CAR[0] - 1.2, K.IN_CAR[1] - 5.2, 4.6), (K.IN_CAR[0], K.IN_CAR[1], 3.0),
                        lens=24)
    render.shoot(cam, os.path.join(SHEETS, "machine-near.png"), exposure=0.3)


STAGES = {"textures": stage_textures, "export": stage_export, "renders": stage_renders}

if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--stage", choices=list(STAGES), required=True)
    STAGES[ap.parse_args(argv).stage]()
    print("DONE")
