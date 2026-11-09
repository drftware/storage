"""Build the crawl hole in Blender, headless (art/hole/README.md).

    blender -b --factory-startup -P art/hole/build.py -- --stage textures|export|renders

Stages:
    textures  the Hole texture set (the cut edges, the bent tongues, the panel's rim), baked from
              its recipe into out/textures
    export    out/CrawlHole.fbx and src/shared/StorageUnit/CrawlHole/Specs.luau
    renders   the look sheets, art/sheets/hole-*.png

The holed walls and the fallen panel wear the unit's own Partition set (art/unit/out/textures:
build the unit first), mapped exactly as the unit's side walls are, so a holed wall looks like
the wall it replaces. The bright strips round the cut, the cut faces and the tongues wear the
Hole set, baked here through the finds' atlas, bake and export (art/finds/build.py), as the saw
does.

Every sheet is drawn flat, as (along, up) on the wall, filled by a constrained triangulation with
a line at every fold of the corrugation, then stood out by the sheet's offset at each point: so
the cut follows the ribs exactly, wherever it crosses them.
"""

import argparse
import importlib.util
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
UNIT = os.path.join(HERE, "..", "unit")
FINDS = os.path.abspath(os.path.join(HERE, "..", "finds"))
sys.path.insert(0, UNIT)
sys.path.insert(0, HERE)  # first: this folder's spec.py

import bpy  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402
from mathutils.geometry import delaunay_2d_cdt  # noqa: E402

import bake  # noqa: E402
import geo  # noqa: E402
import parts as unit_parts  # noqa: E402
import render  # noqa: E402
import spec as K  # noqa: E402
from nodes import hexc  # noqa: E402

OUT = os.path.join(HERE, "out")
TEX = os.path.join(OUT, "textures")
UNIT_TEX = os.path.join(UNIT, "out", "textures")
SHEETS = os.path.join(K.ROOT, "art", "sheets")
FBX = os.path.join(OUT, "CrawlHole.fbx")
SPECS = os.path.join(K.ROOT, "src", "shared", "StorageUnit", "CrawlHole", "Specs.luau")


def finds_kit():
    """The finds' build, as a library: it imports `spec`, which is already this folder's, so its
    atlas size, set name and dust are the hole's; its out paths are pointed here."""
    s = importlib.util.spec_from_file_location("finds_build", os.path.join(FINDS, "build.py"))
    mod = importlib.util.module_from_spec(s)
    s.loader.exec_module(mod)
    assert mod.K is K, "the finds' build must see the hole's spec"
    mod.OUT, mod.TEX, mod.UVS, mod.FBX = OUT, TEX, os.path.join(OUT, "uvs.npz"), FBX
    return mod


kit = finds_kit()

# What a face of the Hole set is, for the recipe (a face attribute).
KERF, NEAR, FAR, TAB, TAB_EDGE, PANEL_KERF, PANEL_RIM = range(7)
EDGE = "Edge_Pos"  # the one the bake sees; Edge_Neg is its mirror, wearing the same texels


# --- flat geometry: (a along the wall, z up) --------------------------------------------------

def area(poly):
    return 0.5 * sum(p[0] * q[1] - q[0] * p[1] for p, q in zip(poly, poly[1:] + poly[:1]))


def inside(pt, poly):
    x, y, hit = pt[0], pt[1], False
    for (ax, ay), (bx, by) in zip(poly, poly[1:] + poly[:1]):
        if (ay > y) != (by > y) and x < ax + (y - ay) * (bx - ax) / (by - ay):
            hit = not hit
    return hit


def seg_dist(p, a, b):
    ax, az, bx, bz = a[0], a[1], b[0], b[1]
    dx, dz = bx - ax, bz - az
    L = dx * dx + dz * dz
    t = 0.0 if L == 0 else max(0.0, min(1.0, ((p[0] - ax) * dx + (p[1] - az) * dz) / L))
    return math.hypot(p[0] - ax - t * dx, p[1] - az - t * dz)


def dist_to(p, poly):
    return min(seg_dist(p, a, b) for a, b in zip(poly, poly[1:] + poly[:1]))


def at_folds(poly):
    """The polygon with a point added wherever an edge crosses a fold of the sheet."""
    out = []
    for p, q in zip(poly, poly[1:] + poly[:1]):
        out.append(p)
        lo, hi = sorted((p[0], q[0]))
        cuts = K.folds(lo, hi)
        if q[0] < p[0]:
            cuts = cuts[::-1]
        for a in cuts:
            t = (a - p[0]) / (q[0] - p[0])
            out.append((a, p[1] + (q[1] - p[1]) * t))
    return out


def fill(outer, holes=()):
    """Triangles filling `outer` less `holes`, none of them across a fold: (points, triangles),
    each triangle counter-clockwise in (a, z)."""
    outer = at_folds(outer)
    holes = [at_folds(h) for h in holes]
    verts, edges = [], []

    def ring(poly):
        base = len(verts)
        verts.extend(poly)
        edges.extend((base + i, base + (i + 1) % len(poly)) for i in range(len(poly)))

    ring(outer)
    for h in holes:
        ring(h)
    a0, a1 = min(p[0] for p in outer), max(p[0] for p in outer)
    z0, z1 = min(p[1] for p in outer), max(p[1] for p in outer)
    for a in K.folds(a0, a1):
        i = len(verts)
        verts += [(a, z0 - 1.0), (a, z1 + 1.0)]
        edges.append((i, i + 1))
    vs, _, fs, _, _, _ = delaunay_2d_cdt([Vector(v) for v in verts], edges, [], 0, 1e-7)
    pts = [(v.x, v.y) for v in vs]
    tris = []
    for f in fs:
        c = tuple(sum(pts[i][k] for i in f) / 3 for k in (0, 1))
        if inside(c, outer) and not any(inside(c, h) for h in holes):
            t = tuple(f)
            tris.append(t if area([pts[i] for i in t]) > 0 else t[::-1])
    return pts, tris


# --- meshes --------------------------------------------------------------------------------

class Part:
    """One MeshPart's mesh: faces tagged with what they are, points with how far from the cut."""

    def __init__(self, name):
        self.m = geo.Mesh(name)
        self.kinds, self.cut = [], []

    def vert(self, co, cut=0.0):
        self.cut.append(cut)
        return self.m.vert(co)

    def face(self, idx, kind, uv=None):
        self.m.face(idx, uv)
        self.kinds.append(kind)

    def quad_idx(self, idx, kind, want=None):
        """A quad of four points already added; turned to face `want` if given."""
        if want is not None:
            n = geo._normal([self.m.verts[i] for i in idx])
            if n.dot(Vector(want)) < 0:
                idx = idx[::-1]
        self.face(list(idx), kind)

    def sheet(self, pts, tris, to3d, flip, kind=0, cut=None, uv=None):
        """Triangles in (a, z) stood up by `to3d(a, z)`; `flip` turns them over."""
        idx = {}
        for t in tris:
            for i in t:
                if i not in idx:
                    idx[i] = self.vert(to3d(*pts[i]), cut(pts[i]) if cut else 0.0)
        for t in tris:
            tt = t[::-1] if flip else t
            self.face([idx[i] for i in tt], kind, [uv(*pts[i]) for i in tt] if uv else None)

    def build(self, coll=None, sharp=40.0):
        ob = self.m.build(coll, sharp_angle=None)
        me = ob.data
        assert len(me.polygons) == len(self.kinds), f"{self.m.name}: a face was dropped"
        assert len(me.vertices) == len(self.cut), f"{self.m.name}: a point was dropped"
        for p in me.polygons:
            p.use_smooth = True
        me.set_sharp_from_angle(angle=math.radians(sharp))
        kind = me.attributes.new("kind", "FLOAT", "FACE")
        kind.data.foreach_set("value", [float(k) for k in self.kinds])
        cut = me.attributes.new("cut", "FLOAT", "POINT")
        cut.data.foreach_set("value", self.cut)
        return ob


def wall_uv(side):
    off = K.U_OFF[side]
    return lambda a, z: ((a + off) / 4.0, z / K.H)


def stand(s):
    """A point of the wall's sheet: (a, z) out to face s (+1 the +X face, -1 the other)."""
    return lambda a, z: (K.offset(a) + s * K.SHEET / 2, a, z)


def hole_wall(size, side, pts):
    """A side wall of a `size` unit with the hole cut, mapped as the unit's `side` wall is."""
    D = K.SIZES[size]
    p = Part(f"HoleWall_{size}_{side}")
    outer = [(K.F, K.Z0), (D, K.Z0), (D, K.Z1), (K.F, K.Z1)]
    rim = K.ring(pts, lambda q: q["wob"] + q["band"])  # the wall stops where the strips start
    flat, tris = fill(outer, [rim])
    for s in (1, -1):
        p.sheet(flat, tris, stand(s), s < 0, uv=wall_uv(side))
    # the sheet's two ends, and the top and bottom tracks, as the unit builds them
    m = p.m
    n = len(m.faces)
    mapper = unit_parts.map_wall_along(K.H, 1, u_off=K.U_OFF[side])
    for a in (K.F, D):
        o = K.offset(a)
        v = [(o - K.SHEET / 2, a, K.Z0), (o + K.SHEET / 2, a, K.Z0), (o + K.SHEET / 2, a, K.Z1),
             (o - K.SHEET / 2, a, K.Z1)]
        geo.add_faces(m, v, [[0, 1, 2, 3]], mapper)
        geo.add_faces(m, v, [[3, 2, 1, 0]], mapper)
    unit_parts.tracks(m, 1, K.F, D, 0.0, +1, K.H)
    p.kinds += [0] * (len(m.faces) - n)
    p.cut += [0.0] * (len(m.verts) - len(p.cut))
    return p


def kerf(p, ring_pts, s_lo, s_hi, to3d_w, inward, kind):
    """The cut's own faces round a ring, one connected strip: from face s_lo to face s_hi of the
    sheet, facing `inward(i)` (a 3D direction) at each edge."""
    n = len(ring_pts)
    lo = [p.vert(to3d_w(a, z, s_lo)) for a, z in ring_pts]
    hi = [p.vert(to3d_w(a, z, s_hi)) for a, z in ring_pts]
    quads = [(lo[i], lo[(i + 1) % n], hi[(i + 1) % n], hi[i]) for i in range(n)]
    # one way round for the whole strip, by the majority of its edges
    votes = sum(1 if geo._normal([p.m.verts[j] for j in q]).dot(Vector(inward(i))) > 0 else -1
                for i, q in enumerate(quads))
    for q in quads:
        p.face(list(q if votes > 0 else q[::-1]), kind)


def tab(p, pts, t):
    """A tongue of steel left on the cut and bent toward +X: a curled strip of the sheet, its
    root on the hole's outline, reaching into the hole."""
    n = len(pts)
    mid = round(t["at"] * n) % n
    k = max(1, round(t["root"] / 2 / K.STEP))
    cols = [pts[(mid + j) % n] for j in range(-k, k + 1)]
    bend = math.radians(t["bend"])
    phis = [0.0, bend * 0.4, bend]       # the curl: gentle at the root, bent at the tip
    rows = []
    for ci, q in enumerate(cols):
        u = (ci / (len(cols) - 1)) * 2 - 1        # -1 .. 1 across the root
        reach = t["reach"] * (1.0 - 0.45 * u * u) * (0.85 + 0.3 * ((ci * 37) % 7) / 6)
        a, z = q["a"] + q["na"] * q["wob"], q["z"] + q["nz"] * q["wob"]
        root = Vector((K.offset(a), a, z))
        inward = Vector((0.0, -q["na"], -q["nz"]))
        along = Vector((0.0, -q["nz"], q["na"]))  # along the outline
        col = []
        pos = root.copy()
        for r, phi in enumerate(phis):
            if r > 0:
                step = reach / (len(phis) - 1)
                d = math.cos(phi) * inward + math.sin(phi) * Vector((1.0, 0.0, 0.0))
                pos = pos + step * d
                if r == len(phis) - 1:
                    pos = pos - along * (u * reach * 0.35)   # the tip narrows
            nrm = -math.sin(phi) * inward + math.cos(phi) * Vector((1.0, 0.0, 0.0))
            col.append((pos.copy(), nrm))
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
        # the tip's cut face
        out = ((rows[ci][last][0] + rows[ci + 1][last][0])
               - (rows[ci][last - 1][0] + rows[ci + 1][last - 1][0]))
        p.quad_idx((back[ci][last], back[ci + 1][last], front[ci + 1][last], front[ci][last]),
                   TAB_EDGE, out)
    # the two sides' cut faces
    for ci, other in ((0, 1), (len(rows) - 1, len(rows) - 2)):
        for r in range(last):
            out = rows[ci][r][0] - rows[other][r][0]
            p.quad_idx((back[ci][r], back[ci][r + 1], front[ci][r + 1], front[ci][r]),
                       TAB_EDGE, out)


def lay():
    """Where the fallen panel's points go: (a, z, w) on the wall, `w` out toward +X, to the floor
    on the +X side, its face that was toward the saw up, resting on its ribs."""
    h0 = K.RIB + K.SHEET / 2
    cx = K.GAP + (K.TOP - K.BOTTOM) / 2
    cy = (K.FROM + K.TO) / 2 + K.SLIDE
    turn = Matrix.Rotation(math.radians(K.TURN), 3, "Z")

    def f(a, z, w):
        v = Vector((K.GAP + (z - K.BOTTOM) - cx, a + K.SLIDE - cy, 0.0))
        v = turn @ v
        return (v.x + cx, v.y + cy, h0 - w)

    return f


def sides(pts, a, b):
    """The strip between rings `a` and `b` (as many points as `pts`) cut at its four corners:
    four polygons."""
    n = len(pts)
    cuts = sorted(max(range(n), key=lambda i: pts[i]["na"] * da + pts[i]["nz"] * dz)
                  for da, dz in ((1, -1), (1, 1), (-1, 1), (-1, -1)))
    out = []
    for k in range(4):
        i0, i1 = cuts[k], cuts[(k + 1) % 4]
        span = [(i0 + j) % n for j in range((i1 - i0) % n + 1)]
        out.append([a[i] for i in span] + [b[i] for i in reversed(span)])
    return out


def edge_and_panel(pts):
    """The Hole set's part (the strips round the cut, its faces, the tongues, the panel's rim and
    cut faces) and the panel's Partition part, both falling toward +X."""
    e = Part(EDGE)
    hole = K.ring(pts, lambda q: q["wob"])
    rim = K.ring(pts, lambda q: q["wob"] + q["band"])
    near = lambda q: dist_to(q, hole)  # noqa: E731
    # the saw's side (-X) and the far side (+X), each strip in its four sides, so the atlas packs
    # them as straight strips rather than hollow squares
    for piece in sides(pts, hole, rim):
        flat, tris = fill(piece)
        e.sheet(flat, tris, stand(-1), True, NEAR, near)
        e.sheet(flat, tris, stand(1), False, FAR, near)
    hf = at_folds(hole)
    cx, cz = (K.FROM + K.TO) / 2, (K.BOTTOM + K.TOP) / 2

    def toward_middle(ring_pts):
        def f(i):
            a, z = ring_pts[i]
            return (0.0, cx - a, cz - z)
        return f

    kerf(e, hf, -1, 1, lambda a, z, s: stand(s)(a, z), toward_middle(hf), KERF)
    for t in K.TABS:
        tab(e, pts, t)

    # the panel: the hole less the blade's width, its top face's rim in the Hole set
    f = lay()
    edge = K.ring(pts, lambda q: q["wob"] - K.KERF)
    inner = K.ring(pts, lambda q: q["wob"] - K.KERF - q["pband"])
    top = lambda a, z: f(a, z, K.offset(a) - K.SHEET / 2)   # noqa: E731
    bottom = lambda a, z: f(a, z, K.offset(a) + K.SHEET / 2)   # noqa: E731
    for piece in sides(pts, edge, inner):
        flat, tris = fill(piece)
        e.sheet(flat, tris, top, True, PANEL_RIM, lambda q: dist_to(q, edge))
    ef = at_folds(edge)
    ctr = Vector(f(cx, cz, 0.0))

    def outward(i):
        a, z = ef[i]
        return tuple(Vector(f(a, z, 0.0)) - ctr)

    kerf(e, ef, -1, 1, lambda a, z, s: f(a, z, K.offset(a) + s * K.SHEET / 2), outward,
         PANEL_KERF)

    panel = Part("Panel_Pos")
    uv = wall_uv("Left")
    flat, tris = fill(inner)
    panel.sheet(flat, tris, top, True, uv=uv)
    flat, tris = fill(edge)
    panel.sheet(flat, tris, bottom, False, uv=uv)
    return e, panel


def mirror(ob, name):
    """`ob` mirrored across the wall's middle plane (X), its faces turned back out."""
    me = ob.data.copy()
    me.name = name
    me.transform(Matrix.Scale(-1.0, 4, (1.0, 0.0, 0.0)))
    me.flip_normals()
    me.update()
    out = bpy.data.objects.new(name, me)
    for c in ob.users_collection:
        c.objects.link(out)
    return out


def unwrap(ob, pad=2):
    """Smart-project the edge, then pack its islands by their real shapes, turned any way: its
    strips are long and thin, and packed as boxes they'd leave most of the atlas empty."""
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    bpy.context.scene.tool_settings.use_uv_select_sync = True
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(55), island_margin=0.0, area_weight=0.0,
                             correct_aspect=True, scale_to_bounds=False)
    bpy.ops.uv.pack_islands(rotate=True, rotate_method="ANY", scale=True, margin_method="FRACTION",
                            margin=pad / K.TEX, shape_method="CONCAVE")
    bpy.ops.object.mode_set(mode="OBJECT")
    clash = kit.clashes([ob])
    assert not clash, f"faces share texels in the atlas: {clash}"


def build_all(baking, coll=None):
    """The Hole set's objects: the edge falling toward +X (and, unless baking, its mirror)."""
    pts = K.outline()
    e, _ = edge_and_panel(pts)
    ob = e.build(coll)
    kit.settle([ob])
    if baking:
        unwrap(ob)
        kit.keep_uvs({EDGE: ob})
    else:
        kit.wear_uvs({EDGE: ob})
        print(f"atlas: faces on unpainted texels {kit.unpainted({EDGE: ob})}")
    print(f"atlas: {kit.density([ob]):.0f} texels a stud, uv {kit.uv_hash([ob])}")
    objs = {EDGE: ob}
    if not baking:
        objs["Edge_Neg"] = mirror(ob, "Edge_Neg")
    return objs


def build_partition(coll=None):
    """The holed walls (both sizes, both sides) and the fallen panel, in the unit's Partition."""
    pts = K.outline()
    objs = {}
    for size in K.SIZES:
        for side in ("Left", "Right"):
            p = hole_wall(size, side, pts)
            objs[p.m.name] = p.m.build(coll, sharp_angle=35.0)
    _, panel = edge_and_panel(pts)
    ob = panel.m.build(coll, sharp_angle=35.0)
    objs["Panel_Pos"] = ob
    objs["Panel_Neg"] = mirror(ob, "Panel_Neg")
    return objs


# --- the recipe --------------------------------------------------------------------------------

def look(nb):
    """Galvanized sheet where the strips meet the wall, scraped bright by the saw's shoe toward
    the cut on the saw's side, a bright burr along the cut itself, the cut's own faces freshly
    sawn steel with the blade's stripes, the tongues bent bright with their zinc cracked off.
    Bright by colour more than by metal: a phone's lighting gives metal little to reflect."""
    L = kit.Look(nb, K.SEED)
    cut = nb.node("ShaderNodeAttribute", attribute_type="GEOMETRY",
                  attribute_name="cut").outputs["Fac"]
    galv = nb.tint(hexc("#A7ACAF"), nb.mr(L.noise(2.5, 1, detail=4), 0.3, 0.7, 0.86, 1.06))
    galv = nb.tint(galv, nb.mr(L.noise(40.0, 2, detail=2), 0.3, 0.7, 0.95, 1.03))
    C = kit.Coat(L, galv, nb.mr(L.noise(5.0, 3, detail=3), 0.3, 0.7, 0.4, 0.52), 0.7, 0.0)
    steel = nb.tint(hexc("#E4E7E9"), nb.mr(L.noise(9.0, 4, detail=3), 0.3, 0.7, 0.9, 1.04))
    near, far = L.k(NEAR, PANEL_RIM), L.k(FAR)
    faces = L.k(KERF, PANEL_KERF, TAB_EDGE)
    tabs = L.k(TAB)

    # the saw's side: the shoe scraped the zinc off in a strip, scratched along the cut
    scrape = nb.mul(near, nb.ss(cut, 0.1, 0.035))
    scrape = nb.mul(scrape, nb.mr(L.noise(14.0, 5, detail=4), 0.35, 0.65, 0.7, 1.0))
    C.paint(scrape, hexc("#CFD4D7"), 0.28, 0.45)
    scr = nb.band(L.noise(26.0, 6, stretch=(1.0, 0.25, 1.0), detail=2), 0.494, 0.506, 0.002)
    scr = nb.add(scr, nb.band(L.noise(26.0, 7, stretch=(1.0, 1.0, 0.25), detail=2), 0.494,
                              0.506, 0.002), clamp=True)
    lines = nb.mul(nb.mul(scr, near), nb.ss(cut, 0.12, 0.04))
    C.paint(lines, hexc("#EEF0F1"), 0.2, 0.45, height=-0.25)
    # a little heat, straw and blue, in patches by the cut
    heat = nb.mul(nb.ss(cut, 0.035, 0.008), nb.ss(L.noise(7.0, 8, detail=3), 0.58, 0.7))
    C.paint(nb.mul(heat, 0.55), hexc("#B59B6E"), 0.35)
    blue = nb.mul(nb.ss(cut, 0.02, 0.004), nb.ss(L.noise(7.0, 9, detail=3), 0.62, 0.72))
    C.paint(nb.mul(blue, 0.4), hexc("#7D86A3"))

    # the far side: the zinc torn back along the cut, a few scratches where the panel went through
    torn = nb.mul(far, nb.ss(cut, 0.055, 0.018))
    torn = nb.mul(torn, nb.mr(L.noise(18.0, 10, detail=4), 0.3, 0.6, 0.6, 1.0))
    C.paint(torn, hexc("#D0D4D7"), 0.28, 0.45)
    flines = nb.mul(nb.mul(scr, far), nb.mul(nb.ss(cut, 0.1, 0.03), 0.6))
    C.paint(flines, hexc("#E2E5E7"), 0.22, 0.45, height=-0.2)

    # the burr: a bright raised lip right on the cut, both faces
    burr = nb.mul(nb.add(near, far, clamp=True), nb.ss(cut, 0.022, 0.006))
    C.paint(burr, steel, 0.18, 0.45, height=0.35)

    # the cut's own faces: sawn steel, the blade's stripes across them, bright
    stripe = nb.band(L.noise(60.0, 11, stretch=(0.15, 1.0, 1.0), detail=1), 0.45, 0.55, 0.05)
    C.paint(faces, nb.mixc(nb.mul(stripe, 0.4), steel, hexc("#A4A8AC")), 0.28, 0.45)

    # the tongues: bent until the zinc cracked off, bright at the tip and the bend
    crack = nb.ss(L.noise(16.0, 12, detail=5, rough=0.7), 0.42, 0.55)
    bright = nb.mul(tabs, nb.add(nb.ss(cut, 0.025, 0.0), nb.mul(crack, 0.8), clamp=True))
    C.paint(bright, steel, 0.22, 0.45)
    C.paint(nb.mul(nb.mul(tabs, scr), 0.8), hexc("#E4E7E9"), 0.2, height=-0.2)

    C.finish(ao=0.12, ao_low=0.6, dust=0.0)
    return C.channels(dist=0.0015, strength=0.5)


def stage_textures():
    kit.reset()
    objs = build_all(baking=True)
    kit.bake_set([(ob, bake.Rig(f"bk_{name}", look)) for name, ob in objs.items()], samples=32)


# --- export ---------------------------------------------------------------------------------

def box(ob):
    vs = [ob.matrix_world @ v.co for v in ob.data.vertices]
    return (Vector([min(v[i] for v in vs) for i in range(3)]),
            Vector([max(v[i] for v in vs) for i in range(3)]))


def piece(ob):
    lo, hi = box(ob)
    s, c = hi - lo, (lo + hi) / 2
    return dict(size=(s.x, s.z, s.y), centre=K.to_roblox(c), tris=kit.tris(ob))


def stage_export():
    kit.reset()
    objs = build_all(baking=False)
    mat = kit.material()
    for ob in objs.values():
        ob.data.materials.append(mat)
    walls = build_partition()
    part_mat = bake.textured("Partition", UNIT_TEX, for_export=True)
    for ob in walls.values():
        ob.data.materials.append(part_mat)
    objs.update(walls)
    os.makedirs(OUT, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    for ob in objs.values():
        ob.select_set(True)
    bpy.context.view_layer.objects.active = objs["HoleWall_M_Left"]
    bpy.ops.export_scene.fbx(
        filepath=FBX, use_selection=True, object_types={"MESH"},
        apply_scale_options="FBX_SCALE_UNITS", axis_forward="Z", axis_up="Y",
        use_mesh_modifiers=True, mesh_smooth_type="OFF", use_tspace=False,
        add_leaf_bones=False, bake_anim=False, path_mode="COPY", embed_textures=True)
    rows = {name: piece(ob) for name, ob in objs.items()}
    print("FBX", FBX, {n: r["tris"] for n, r in rows.items()})
    os.makedirs(os.path.dirname(SPECS), exist_ok=True)
    K.write_luau(SPECS, rows)
    print("SPEC", SPECS)


# --- look sheets ----------------------------------------------------------------------------

def room(cx, s, coll, skip_side=None):
    """A unit's shell centred across on x = cx: floor, back wall, side walls, the corridor wall
    seen from inside. `skip_side` (-1 or 1) leaves out a side wall a neighbour stands."""
    meshes = [(unit_parts.floor(s), "Concrete"), (unit_parts.wall_back(s), "Partition"),
              (unit_parts.facade_back(s), "Partition")]
    for side in (-1, 1):
        if side != skip_side:
            meshes.append((unit_parts.wall_side(s, side), "Partition"))
    for m, texset in meshes:
        ob = m.build(coll)
        ob.location.x = cx
        ob.data.materials.append(bake.textured(texset, UNIT_TEX))


def bulb(name, at, on):
    ld = bpy.data.lights.new(name, "POINT")
    ld.energy, ld.color, ld.shadow_soft_size = 220.0, (1.0, 0.674, 0.408), 0.08
    ob = bpy.data.objects.new(name, ld)
    bpy.context.scene.collection.objects.link(ob)
    ob.location = at
    ob.hide_render = not on
    return ob


def stage_renders():
    """Two M units side by side, A (x = 0) and B (x = 12): the hole sawn from A in the wall they
    share, the panel fallen into B."""
    kit.reset()
    render.setup(96, (1600, 900))
    coll = bpy.context.scene.collection
    s = K.U.Spec("M")
    room(0.0, s, coll, skip_side=1)
    room(12.0, s, coll, skip_side=-1)
    edge = build_all(baking=False)
    hmat = kit.material()
    walls = build_partition(coll)
    pmat = bake.textured("Partition", UNIT_TEX)
    at = Matrix.Translation((6.0, 0.0, 0.0))  # A's right wall
    for name, ob in {**edge, **walls}.items():
        keep = name in (EDGE, "Panel_Pos", "HoleWall_M_Right")
        ob.hide_render = not keep
        ob.matrix_world = at
        ob.data.materials.append(hmat if name.startswith("Edge") else pmat)
    render.world((0.002, 0.0025, 0.004), 1.0)
    a = bulb("bulbA", (0.0, 6.0, 8.7), True)
    b = bulb("bulbB", (12.0, 6.0, 8.7), False)
    mid = (6.0, (K.FROM + K.TO) / 2, (K.BOTTOM + K.TOP) / 2)

    # 1. from A's doorway at standing height, B dark: the hole you just sawed
    cam = render.camera((0.6, 0.9, 4.6), (5.0, 5.6, 1.6), lens=14.6)
    render.shoot(cam, os.path.join(SHEETS, "hole-near.png"), exposure=0.9)
    # 2. from B's doorway, B dark, A lit: the light through the hole, the panel on the floor
    cam = render.camera((11.4, 0.9, 4.6), (7.0, 5.6, 1.0), lens=14.6)
    render.shoot(cam, os.path.join(SHEETS, "hole-far.png"), exposure=0.2)
    # 3. the same with B's bulb on too
    b.hide_render = False
    render.shoot(cam, os.path.join(SHEETS, "hole-far-lit.png"), exposure=0.7)
    # 4. crouched in A, close: the cut, the tongues bent away, B lit beyond
    cam = render.camera((3.3, 3.6, 2.2), mid, lens=24.0)
    render.shoot(cam, os.path.join(SHEETS, "hole-close.png"), exposure=0.7)
    # 5. both dark, your torch on it from A's doorway
    a.hide_render = b.hide_render = True
    cam = render.camera((0.6, 0.9, 4.6), (5.0, 5.6, 1.6), lens=14.6)
    render.flashlight(cam, True, mid)
    render.shoot(cam, os.path.join(SHEETS, "hole-torch.png"), exposure=0.2)


STAGES = {"textures": stage_textures, "export": stage_export, "renders": stage_renders}

if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--stage", choices=list(STAGES), required=True)
    STAGES[ap.parse_args(argv).stage]()
    print("DONE")
