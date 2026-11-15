"""Build the moving boxes in Blender, headless (art/boxes/README.md).

    blender -b --factory-startup -P art/boxes/build.py -- --stage labels|textures|export|renders

Stages:
    labels    out/labels.png: the words and marks the bake prints and writes on the boxes
    textures  the Cardboard texture set, baked from the procedural recipe into out/textures
    export    out/Boxes.fbx (every box, one MeshPart each) and src/shared/Boxes/Specs.luau
    renders   the look sheets, art/sheets/boxes-*.png

Every box shares one 1024² atlas. Each box's faces are packed into it at one texel density; the
side facing +Y shows the same texels as the side facing -Y (and +X as -X, the bottom as the top),
seen from outside, so the atlas holds half of every box and the density doubles. While baking,
those twin faces sit on a parked texel, so only one of each pair is painted.
"""

import argparse
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
UNIT = os.path.join(HERE, "..", "unit")
sys.path.insert(0, UNIT)
sys.path.insert(0, HERE)  # first: this folder's spec.py, not the unit's

import bpy  # noqa: E402
from mathutils import Vector  # noqa: E402

import importlib.util  # noqa: E402

import bake  # noqa: E402
import geo  # noqa: E402
import render  # noqa: E402
import spec as K  # noqa: E402
from materials import Channels  # noqa: E402
from nodes import NB, hexc  # noqa: E402

# The finds kit's easing (art/finds/kit/ease.py), so the box's motion is played with the same sums.
_ez = importlib.util.spec_from_file_location("finds_ease", os.path.join(HERE, "..", "finds", "kit", "ease.py"))
ease = importlib.util.module_from_spec(_ez)
_ez.loader.exec_module(ease)

OUT = os.path.join(HERE, "out")
TEX = os.path.join(OUT, "textures")
UNIT_TEX = os.path.join(UNIT, "out", "textures")
LABELS = os.path.join(OUT, "labels.png")
SHEETS = os.path.join(K.ROOT, "art", "sheets")
SET = "Cardboard"
PARK = (1.0 - 2.0 / K.TEX, 1.0 - 2.0 / K.TEX)  # the twin faces' texel while baking

# What a face is, for the recipe (a face attribute).
TOP, FRONT, END, BOTTOM, INNER, RAW, FLAP_TAPED, FLAP_OUT, FLAP_IN, TAPE, TAPE_UNDER = range(11)
X, Y, Z = Vector((1, 0, 0)), Vector((0, 1, 0)), Vector((0, 0, 1))


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


# --- geometry --------------------------------------------------------------------------------

class Faces:
    """A box's mesh as grids of quads. Each grid is one face: a rectangle `size` studs, mapped
    whole onto its own island in the atlas (or onto its twin's)."""

    def __init__(self, name):
        self.name = name
        self.verts, self.st, self.local = [], [], []
        self.polys, self.key, self.kind, self.twin = [], [], [], []
        self.rects = {}  # key -> (width, height) in studs, the faces that own atlas space
        self.cur, self.part = "Body", []  # the marked box's part each face belongs to

    def grid(self, key, kind, o, r, up, w, h, twin=False, bow=0.0, flat=False):
        """A face from corner `o` (its bottom-left seen from outside), `w` studs along `r` and `h`
        along `up`; it faces r x up. `bow` pushes its middle out along that normal."""
        n = r.cross(up).normalized()
        least = 2 if bow else 1
        nu = 1 if flat else max(least, math.ceil(w / K.GRID - 1e-6))
        nv = 1 if flat else max(least, math.ceil(h / K.GRID - 1e-6))
        base = len(self.verts)
        for j in range(nv + 1):
            for i in range(nu + 1):
                s, t = i / nu, j / nv
                p = o + r * (s * w) + up * (t * h)
                p += n * (bow * math.sin(math.pi * s) * math.sin(math.pi * t))
                self.verts.append(p)
                self.st.append((s, t))
                self.local.append((s * w, t * h))
        for j in range(nv):
            for i in range(nu):
                a = base + j * (nu + 1) + i
                self.polys.append((a, a + 1, a + nu + 2, a + nu + 1))
                self.key.append(key)
                self.kind.append(kind)
                self.twin.append(twin)
                self.part.append(self.cur)
        if not twin:
            self.rects[key] = (w, h)

    def dent(self, sx, sy, reach, depth, w, d, h):
        """A crushed top corner: the corner pushed in and down, fading over `reach` studs."""
        c = Vector((sx * w / 2, sy * d / 2, h))
        way = Vector((-sx * 0.5, -sy * 0.5, -1.0)).normalized()
        for i, p in enumerate(self.verts):
            r = (p - c).length
            if r < reach:
                self.verts[i] = p + way * (depth * (1.0 - r / reach) ** 2)

    def tris(self):
        return sum(len(p) - 2 for p in self.polys)

    def build(self, rects, baking, coll=None):
        me = bpy.data.meshes.new(self.name)
        me.from_pydata([tuple(v) for v in self.verts], [], self.polys)
        me.update()
        uv = me.uv_layers.new(name="UVMap")
        lc = me.uv_layers.new(name="Local")
        for poly, key, twin in zip(me.polygons, self.key, self.twin):
            u0, v0, u1, v1 = rects[key]
            for li in poly.loop_indices:
                vi = me.loops[li].vertex_index
                s, t = self.st[vi]
                uv.data[li].uv = PARK if (twin and baking) else (u0 + s * (u1 - u0), v0 + t * (v1 - v0))
                lc.data[li].uv = self.local[vi]
        for poly in me.polygons:
            poly.use_smooth = True
        me.set_sharp_from_angle(angle=math.radians(35))
        attr = me.attributes.new("kind", "FLOAT", "FACE")
        attr.data.foreach_set("value", [float(k) for k in self.kind])
        me.uv_layers.active = uv
        uv.active_render = True
        ob = bpy.data.objects.new(self.name, me)
        (coll or bpy.context.scene.collection).objects.link(ob)
        return ob

    def build_parts(self, rects, coll, pivots):
        """One object a part, named `<box>_<part>`, its origin on its hinge (`pivots`)."""
        out = {}
        for nm, pv in pivots.items():
            sub, remap = Faces(f"{self.name}_{nm}"), {}
            for i, poly in enumerate(self.polys):
                if self.part[i] != nm:
                    continue
                for v in poly:
                    if v not in remap:
                        remap[v] = len(sub.verts)
                        sub.verts.append(self.verts[v] - pv)
                        sub.st.append(self.st[v])
                        sub.local.append(self.local[v])
                sub.polys.append(tuple(remap[v] for v in poly))
                sub.key.append(self.key[i])
                sub.kind.append(self.kind[i])
                sub.twin.append(self.twin[i])
            if sub.polys:
                ob = sub.build(rects, False, coll)
                ob.location = pv
                out[nm] = ob
        return out


def sides(F, nm, w, d, h, bulge, kinds=(FRONT, END)):
    """The four outside walls; +Y and +X are twins of -Y and -X."""
    F.grid(f"{nm}.front", kinds[0], Vector((-w / 2, -d / 2, 0)), X, Z, w, h, bow=bulge)
    F.grid(f"{nm}.front", kinds[0], Vector((w / 2, d / 2, 0)), -X, Z, w, h, True, bow=bulge)
    F.grid(f"{nm}.end", kinds[1], Vector((-w / 2, d / 2, 0)), -Y, Z, d, h, bow=bulge)
    F.grid(f"{nm}.end", kinds[1], Vector((w / 2, -d / 2, 0)), Y, Z, d, h, True, bow=bulge)


def closed(F, nm, b):
    w, d, h = b["w"], b["d"], b["h"]
    sides(F, nm, w, d, h, b["bulge"])
    F.grid(f"{nm}.top", TOP, Vector((-w / 2, -d / 2, h)), X, Y, w, d, bow=-b["sag"])
    F.grid(f"{nm}.top", BOTTOM, Vector((-w / 2, d / 2, 0)), X, -Y, w, d, True, flat=True)
    if b["dent"]:
        F.dent(*b["dent"], w, d, h)


def flap(F, nm, out_key, kind, o, r, c, w, length, angle, twin, in_twin=None):
    """A flap hinged on the top edge from `o` along `r`, `angle` degrees open from lying shut
    over the box (towards `c`); outer face, inner face and its three cut edges."""
    t = K.BOARD
    in_twin = twin if in_twin is None else in_twin
    a = math.radians(angle)
    e = c * math.cos(a) + Z * math.sin(a)
    n = r.cross(e).normalized()
    F.grid(out_key, kind, o, r, e, w, length, twin)
    F.grid(f"{nm}.flapin", FLAP_IN, o + r * w - n * t, -r, e, w, length, in_twin)
    F.grid(f"{nm}.rim", RAW, o + e * length, r, -n, w, t, True)
    F.grid(f"{nm}.rim", RAW, o, e, -n, length, t, True)
    F.grid(f"{nm}.rim", RAW, o + r * w, -n, e, t, length, True)


def opened(F, nm, b):
    """A medium box with its tape slit and its four flaps standing up and out."""
    w, d, h, t = b["w"], b["d"], b["h"], K.BOARD
    bulge = b["bulge"]
    sides(F, nm, w, d, h, bulge)
    iw, idp, ih = w - 2 * t, d - 2 * t, h - t
    F.grid(f"{nm}.inner", INNER, Vector((w / 2 - t, -d / 2 + t, t)), -X, Z, iw, ih, bow=-bulge)
    F.grid(f"{nm}.inner", INNER, Vector((-w / 2 + t, d / 2 - t, t)), X, Z, iw, ih, True, bow=-bulge)
    F.grid(f"{nm}.innerend", INNER, Vector((-w / 2 + t, -d / 2 + t, t)), Y, Z, idp, ih, bow=-bulge)
    F.grid(f"{nm}.innerend", INNER, Vector((w / 2 - t, d / 2 - t, t)), -Y, Z, idp, ih, True, bow=-bulge)
    F.grid(f"{nm}.floor", INNER, Vector((-w / 2 + t, -d / 2 + t, t)), X, Y, iw, idp)
    F.grid(f"{nm}.floor", BOTTOM, Vector((-w / 2, d / 2, 0)), X, -Y, w, d, True, flat=True)
    F.grid(f"{nm}.rim", RAW, Vector((-w / 2, -d / 2, h)), X, Y, w, t)
    F.grid(f"{nm}.rim", RAW, Vector((w / 2, d / 2, h)), -X, -Y, w, t, True)
    F.grid(f"{nm}.rim", RAW, Vector((-w / 2, d / 2 - t, h)), -Y, X, idp, t, True)
    F.grid(f"{nm}.rim", RAW, Vector((w / 2, -d / 2 + t, h)), Y, -X, idp, t, True)
    front, back, left, right = b["open"]
    length = d / 2  # a regular slotted box: every flap is half its width
    flap(F, nm, f"{nm}.flap", FLAP_TAPED, Vector((-w / 2, -d / 2, h)), X, Y, w, length, front, False)
    flap(F, nm, f"{nm}.flap", FLAP_TAPED, Vector((w / 2, d / 2, h)), -X, -Y, w, length, back, True)
    flap(F, nm, f"{nm}.endflap", FLAP_OUT, Vector((-w / 2, d / 2, h)), -Y, X, d, length, left, False)
    flap(F, nm, f"{nm}.endflap", FLAP_OUT, Vector((w / 2, -d / 2, h)), Y, -X, d, length, right, True)


def faces(name):
    b = K.BOXES[name]
    F = Faces(name)
    (opened if b.get("open") else closed)(F, name, b)
    return F


def pack(all_faces):
    """Shelf-packs every face that owns atlas space at the highest density that fits. Returns
    ({key: (u0, v0, u1, v1)}, texels per stud)."""
    rects = {}
    for F in all_faces:
        rects.update(F.rects)
    order = sorted(rects, key=lambda k: -rects[k][1])
    size, pad, top = K.TEX, K.PAD, K.TEX - 8  # keep the top rows for the parked texel

    def place(s):
        out, x, y, row = {}, pad, pad, 0.0
        for k in order:
            w, h = rects[k][0] * s, rects[k][1] * s
            if x + w + pad > size:
                x, y, row = pad, y + row + pad, 0.0
            if y + h + pad > top or w + 2 * pad > size:
                return None
            out[k] = (x / size, y / size, (x + w) / size, (y + h) / size)
            x += math.ceil(w) + pad
            row = max(row, math.ceil(h))
        return out

    lo, hi = 10.0, 400.0
    for _ in range(40):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if place(mid) else (lo, mid)
    return place(lo), lo


def build_all(baking, coll=None):
    """The five scenery boxes ({name: object}); the atlas is packed with the marked box's faces
    too, so every box keeps its texels whichever is built (build_marked)."""
    all_faces = [faces(n) for n in K.ORDER]
    rects, density = pack(all_faces + [marked_faces(baking)])
    objs = {}
    for F in all_faces:
        b = K.BOXES[F.name]
        ob = F.build(rects, baking, coll)
        ob["W"], ob["D"], ob["H"] = b["w"], b["d"], b["h"]
        objs[F.name] = ob
    return objs, all_faces, density


def marked_faces(baking):
    """The marked box in one mesh, each face tagged with its part, shut as it's found. Its inside,
    flap insides and cut edges wear the Open box's texels (the same size). For the bake the end
    flaps stand open (shut, they lie under the long flaps and would bake black) and the tape floats
    clear of the flaps (or their shadow would bake into its sticky side); the seam isn't baked."""
    b, t, tw = K.MARKED, K.BOARD, K.TAPE / 2
    w, d, h, bulge = b["w"], b["d"], b["h"], b["bulge"]
    F = Faces("Marked")
    sides(F, "Marked", w, d, h, bulge)
    # the walls' cut tops sit a hair under the shut flaps, or the two would fight for the same pixels
    iw, idp, ih, top = w - 2 * t, d - 2 * t, h - t - K.UNDER, h - K.UNDER
    F.grid("Open.inner", INNER, Vector((w / 2 - t, -d / 2 + t, t)), -X, Z, iw, ih, True, bow=-bulge)
    F.grid("Open.inner", INNER, Vector((-w / 2 + t, d / 2 - t, t)), X, Z, iw, ih, True, bow=-bulge)
    F.grid("Open.innerend", INNER, Vector((-w / 2 + t, -d / 2 + t, t)), Y, Z, idp, ih, True, bow=-bulge)
    F.grid("Open.innerend", INNER, Vector((w / 2 - t, d / 2 - t, t)), -Y, Z, idp, ih, True, bow=-bulge)
    F.grid("Open.floor", INNER, Vector((-w / 2 + t, -d / 2 + t, t)), X, Y, iw, idp, True)
    F.grid("Open.floor", BOTTOM, Vector((-w / 2, d / 2, 0)), X, -Y, w, d, True, flat=True)
    F.grid("Open.rim", RAW, Vector((-w / 2, -d / 2, top)), X, Y, w, t, True)
    F.grid("Open.rim", RAW, Vector((w / 2, d / 2, top)), -X, -Y, w, t, True)
    F.grid("Open.rim", RAW, Vector((-w / 2, d / 2 - t, top)), -Y, X, idp, t, True)
    F.grid("Open.rim", RAW, Vector((w / 2, -d / 2 + t, top)), Y, -X, idp, t, True)
    opened = {p: ks[-1][1] for p, ch, ks in K.OPEN["tracks"] if ch == "turn"}
    low = h - t - K.UNDER
    for part, key, kind, o, r, c, twin in (
            ("FlapFront", "Marked.flap", FLAP_TAPED, (-w / 2, -d / 2, h), X, Y, False),
            ("FlapBack", "Marked.flap", FLAP_TAPED, (w / 2, d / 2, h), -X, -Y, True),
            ("FlapLeft", "Marked.endflap", FLAP_OUT, (-w / 2, d / 2, low), -Y, X, False),
            ("FlapRight", "Marked.endflap", FLAP_OUT, (w / 2, -d / 2, low), Y, -X, True)):
        F.cur = part
        angle = opened[part] if baking and kind == FLAP_OUT else 0.0
        side = w if r in (X, -X) else d
        flap(F, "Open", key, kind, Vector(o), r, c, side, d / 2, angle, twin, in_twin=True)
    lift = 1.0 if baking else 0.0
    top = h + K.TAPE_UP + lift
    for part, x0, twin in (("TapeLeft", -w / 2, False), ("TapeRight", 0.0, True)):
        F.cur = part
        F.grid("Marked.tape", TAPE, Vector((x0, -tw, top)), X, Y, w / 2, K.TAPE, twin, flat=True)
        F.grid("Marked.tapeunder", TAPE_UNDER, Vector((x0, tw, top - K.TAPE_THICK)), X, -Y,
               w / 2, K.TAPE, twin, flat=True)
    if not baking:
        F.cur = "Seam"
        x0, length = -w / 2 + K.SEAM_INSET, w - 2 * K.SEAM_INSET
        for y0 in (tw + K.SEAM_GAP, -(tw + K.SEAM_GAP + K.SEAM_W)):
            F.grid("Marked.tape", RAW, Vector((x0, y0, h + 0.0015)), X, Y, length, K.SEAM_W, True,
                   flat=True)
    return F


def build_marked(coll=None, baking=False):
    """The marked box: baking, one object; otherwise ({part: object}, each object's origin on its
    hinge, shut), placed at the origin."""
    rects, _ = pack([faces(n) for n in K.ORDER] + [marked_faces(baking)])
    F = marked_faces(baking)
    if baking:
        return F.build(rects, True, coll)
    return F.build_parts(rects, coll, {n: Vector(p) for n, p, _ in K.MARKED_PARTS})


# --- the label sheet -------------------------------------------------------------------------

def text(body, path, cx, cy, maxw, maxh, mat):
    cu = bpy.data.curves.new("label", "FONT")
    cu.body = body
    cu.font = bpy.data.fonts.load(path, check_existing=True)
    cu.align_x, cu.align_y = "CENTER", "CENTER"
    cu.space_line = 0.9
    ob = bpy.data.objects.new("label", cu)
    bpy.context.scene.collection.objects.link(ob)
    ob.data.materials.append(mat)
    bpy.context.view_layer.update()
    lo = Vector([min(c[i] for c in ob.bound_box) for i in range(3)])
    hi = Vector([max(c[i] for c in ob.bound_box) for i in range(3)])
    s = min(maxw / (hi.x - lo.x), maxh / (hi.y - lo.y))
    ob.scale = (s, s, 1.0)
    ob.location = (cx - s * (lo.x + hi.x) / 2, cy - s * (lo.y + hi.y) / 2, 0.0)


def shape(points, mat):
    m = geo.Mesh("mark")
    geo.add_faces(m, [(x, y, 0.0) for x, y in points], [list(range(len(points)))])
    ob = m.build(bpy.context.scene.collection, sharp_angle=None)
    ob.data.materials.append(mat)
    return ob


def arrow(cx, y0, height, mat):
    k = height / 0.35
    pts = [(-0.035, 0), (0.035, 0), (0.035, 0.2), (0.09, 0.2), (0, 0.35), (-0.09, 0.2), (-0.035, 0.2)]
    shape([(cx + x * k, y0 + y * k) for x, y in pts], mat)


def ring(cx, cy, r0, r1, mat, segs=72):
    m = geo.Mesh("ring")
    verts, polys = [], []
    for i in range(segs):
        a = 2 * math.pi * i / segs
        verts += [(cx + r0 * math.cos(a), cy + r0 * math.sin(a), 0), (cx + r1 * math.cos(a), cy + r1 * math.sin(a), 0)]
        j = (i + 1) % segs
        polys.append([2 * i, 2 * i + 1, 2 * j + 1, 2 * j])
    geo.add_faces(m, verts, polys)
    ob = m.build(bpy.context.scene.collection, sharp_angle=None)
    ob.data.materials.append(mat)


def stage_labels():
    """One cell per word or mark, white on black: 2 x 1 Blender units a cell, 256 x 128 texels."""
    reset()
    sc = bpy.context.scene
    cols, rows = K.SHEET
    ink = render.emissive("ink", (1.0, 1.0, 1.0), 1.0)
    for i, (_, body, style) in enumerate(K.CELLS):
        c, r = i % cols, i // cols
        x0, y0 = 2.0 * c, rows - (r + 1.0)
        cx, cy = x0 + 1.0, y0 + 0.5
        if style == "marker":
            text(body, K.MARKER, cx, cy, 1.8, 0.78, ink)
        elif style == "print":
            text(body, K.PRINT, cx, cy, 1.86, 0.84, ink)
        elif style == "up":
            text(body, K.PRINT, cx, y0 + 0.21, 1.86, 0.3, ink)
            arrow(cx - 0.36, y0 + 0.44, 0.48, ink)
            arrow(cx + 0.36, y0 + 0.44, 0.48, ink)
        elif style == "cert":
            ring(cx, cy, 0.4, 0.46, ink)
            text(body, K.PRINT, cx, cy, 0.58, 0.46, ink)
    cam = bpy.data.cameras.new("sheet")
    cam.type = "ORTHO"
    cam.ortho_scale = float(rows)
    ob = bpy.data.objects.new("sheet", cam)
    sc.collection.objects.link(ob)
    ob.location = (cols, rows / 2.0, 10.0)
    sc.camera = ob
    bake.gpu_cycles(16)
    sc.render.resolution_x = sc.render.resolution_y = K.TEX
    sc.render.resolution_percentage = 100
    sc.view_settings.view_transform = "Standard"
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "BW"
    sc.world = bpy.data.worlds.new("black")
    sc.world.use_nodes = True
    sc.world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.0
    os.makedirs(OUT, exist_ok=True)
    sc.render.filepath = LABELS
    bpy.ops.render.render(write_still=True)
    print("RENDERED", LABELS)


# --- the cardboard recipe -------------------------------------------------------------------

def cardboard(nb, b, sheet):
    """Kraft board, packing tape, the maker's print, marker labels, hand holes, wear and dust,
    in the box's own studs (object space) and each face's (the Local UVs)."""
    w, d, h, seed = b["w"], b["d"], b["h"], b["seed"]
    P = nb.node("ShaderNodeTexCoord").outputs["Object"]
    px, py, pz = nb.sep(P)
    _, _, nz = nb.sep(nb.geo().outputs["Normal"])
    lu, lv, _ = nb.sep(nb.node("ShaderNodeUVMap", uv_map="Local").outputs["UV"])
    kind = nb.node("ShaderNodeAttribute", attribute_type="GEOMETRY", attribute_name="kind").outputs["Fac"]

    def isk(*ks):
        m = None
        for k in ks:
            one = nb.band(kind, k - 0.3, k + 0.3, 0.1)
            m = one if m is None else nb.add(m, one, clamp=True)
        return m

    def vec(sx=1.0, sy=1.0, sz=1.0, s=0.0):
        v = nb.vop("MULTIPLY", P, (sx, sy, sz))
        return nb.vop("ADD", v, (seed * 7.13 + s * 3.1, seed * 3.71 + s * 5.3, seed * 5.27 + s * 1.7)), None

    inside, raw, side, top = isk(INNER, FLAP_IN), isk(RAW), isk(FRONT, END), isk(TOP)

    # the board: kraft, blotchy, fibre streaks running up the sides (the flutes stand upright)
    big = nb.noise(vec(s=1), 0.9, detail=4, rough=0.55)
    col = nb.mixc(nb.mr(big, 0.3, 0.7), hexc("#8E643B"), hexc("#B08656"))
    col = nb.mixc(inside, col, nb.mixc(nb.mr(big, 0.3, 0.7), hexc("#A07446"), hexc("#BD9465")))
    streak = nb.noise(vec(1.0, 1.0, 0.12, s=2), 14.0, detail=3)
    col = nb.tint(col, nb.mr(streak, 0.3, 0.7, 0.93, 1.05))
    fib = nb.ss(nb.noise(vec(s=3), 160.0, detail=1), 0.68, 0.76)
    col = nb.mixc(nb.mul(fib, 0.3), col, hexc("#6E4C2C"))
    rawc = nb.tint(hexc("#C8A273"), nb.mr(nb.noise(vec(s=4), 40.0), 0.3, 0.7, 0.8, 1.05))
    col = nb.mixc(raw, col, rawc)
    rough = nb.mr(big, 0.3, 0.7, 0.8, 0.9)
    height = nb.add(nb.mul(streak, 0.06), nb.mul(fib, -0.05))

    # worn edges fray lighter; corners and the inside of an open box gather shadow and grime
    edge = nb.edge(0.035, k=5.0)
    col = nb.mixc(nb.mul(edge, 0.32), col, hexc("#C9A577"))
    col = nb.tint(col, nb.mr(nb.ao(0.45, local=True), 0.0, 1.0, 0.42, 1.0))
    low = nb.ss(pz, 0.2, 0.0)
    grime = nb.mul(nb.mul(low, side), nb.mr(nb.noise(vec(s=5), 6.0, detail=5, distortion=0.4), 0.3, 0.7, 0.25, 0.75))
    col = nb.mixc(grime, col, hexc("#4E3A28"))
    rough = nb.mixf(grime, rough, 0.93)
    scuff = nb.mul(nb.ss(nb.noise(vec(1.0, 1.0, 0.25, s=6), 3.0, detail=6, rough=0.6), 0.66, 0.72),
                   nb.mul(side, 0.45))
    col = nb.mixc(scuff, col, hexc("#5C4B3D"))
    height = nb.add(height, nb.mul(scuff, -0.15))

    # a water mark: it stood in a puddle once
    if b["stain"] > 0:
        tide = nb.add(b["stain"], nb.mul(nb.sub(nb.noise(vec(s=7), 2.2, detail=4), 0.5), 0.14))
        dz = nb.sub(pz, tide)
        below = nb.mul(nb.ss(dz, 0.0, -0.03), side)
        line = nb.mul(nb.band(dz, -0.018, 0.0, 0.008), side)
        col = nb.mixc(nb.mul(below, 0.4), col, hexc("#6E4D30"))
        col = nb.mixc(nb.mul(line, 0.7), col, hexc("#4A321D"))
        rough = nb.mixf(below, rough, 0.76)

    # hand holes high on the ends: cut through, sometimes pushed in
    if b["hole"]:
        ends = isk(END, INNER)
        dy = nb.mx(nb.sub(nb.absf(py), 0.16), 0.0)
        dzh = nb.sub(pz, h - 0.4)
        dist = nb.sub(nb.pw(nb.add(nb.mul(dy, dy), nb.mul(dzh, dzh)), 0.5), 0.06)
        ends = nb.mul(ends, nb.ss(nb.absf(px), w / 2 - 0.1, w / 2 - 0.04))  # only on the X walls
        if b["hole"] == 2:
            hole = nb.mul(nb.ss(dist, 0.0, -0.004), ends)
            lip = nb.mul(nb.band(dist, 0.0, 0.014, 0.004), ends)
            col = nb.mixc(nb.mul(lip, 0.8), col, hexc("#C8A273"))
            col = nb.mixc(hole, col, hexc("#0D0906"))
            rough = nb.mixf(hole, rough, 1.0)
            height = nb.add(height, nb.mul(hole, -2.5))
        cut = nb.mul(nb.band(dist, -0.004, 0.004, 0.003), ends)
        col = nb.mixc(nb.mul(cut, 0.85), col, hexc("#3A2818"))
        height = nb.add(height, nb.mul(cut, -1.0))

    # packing tape along the top seam, lapping down both ends (top and bottom). On the opened box
    # it's slit: what's left laps the ends and edges the long flaps' tips.
    tw = K.TAPE / 2
    marked = b.get("marked")  # its tape is real parts, laid square on the seam
    off = 0.0 if marked else (seed * 0.37) % 0.03 - 0.015
    yy = nb.absf(nb.sub(py, nb.add(off, nb.mul(px, 0.0 if marked else 0.008))))
    strip = nb.ss(yy, tw + 0.003, tw - 0.003)
    rag = nb.mul(nb.fract(nb.mul(py, 23.0)), 0.025)
    lap_top = nb.ss(nb.add(nb.sub(pz, h - K.LAP), rag), 0.0, 0.004)
    lap_low = nb.ss(nb.sub(nb.sub(K.LAP, rag), pz), 0.0, 0.004)
    on = nb.mul(isk(END), nb.add(lap_top, lap_low, clamp=True))
    if b.get("open"):
        tip = nb.mul(isk(FLAP_TAPED), nb.ss(lv, d / 2 - tw - 0.004, d / 2 - tw + 0.004))
        tape = nb.add(nb.mul(on, strip), tip, clamp=True)
    else:
        seam = nb.mul(top, nb.ss(yy, 0.006, 0.0015))
        col = nb.mixc(nb.mul(seam, 0.8), col, hexc("#2E2015"))
        tape = nb.mul(strip, nb.add(top, on, clamp=True))
    if marked:
        tape = nb.add(tape, isk(TAPE, TAPE_UNDER), clamp=True)
    wr = nb.noise(vec(9.0, 1.0, 9.0, s=8), 3.0, detail=3)
    if b["tape"] == "brown":
        tcol = nb.tint(hexc("#8C5A2A"), nb.mr(wr, 0.3, 0.7, 0.82, 1.12))
        col = nb.mixc(nb.mul(tape, 0.93), col, tcol)
        rough = nb.mixf(tape, rough, nb.mr(wr, 0.3, 0.7, 0.2, 0.36))
    else:
        clear = nb.mixc(0.25, nb.tint(col, 0.86), hexc("#E0D2AC"))
        col = nb.mixc(tape, col, clear)
        rough = nb.mixf(tape, rough, nb.mr(wr, 0.3, 0.7, 0.14, 0.26))
    if marked:
        # the tape's sticky side, seen once it's torn up: paler, glossy, board fibres stuck to it
        under = isk(TAPE_UNDER)
        ucol = nb.tint(hexc("#B98A55"), nb.mr(wr, 0.3, 0.7, 0.9, 1.08))
        ucol = nb.mixc(nb.mul(fib, 0.6), ucol, hexc("#D8BE96"))
        col = nb.mixc(under, col, ucol)
        rough = nb.mixf(under, rough, 0.3)
    lip = nb.mul(nb.band(yy, tw - 0.007, tw + 0.001, 0.002), nb.mul(tape, 1.0))
    col = nb.mixc(nb.mul(lip, 0.35), col, hexc("#D8C8A8"))
    height = nb.add(height, nb.add(nb.mul(tape, 0.35), nb.mul(nb.mul(tape, wr), 0.18)))

    # the maker's print and the owner's marker, from the label sheet
    cols, rows = K.SHEET
    for i, m in enumerate(b["marks"]):
        idx = K.CELL[m["cell"]]
        c, r = idx % cols, idx // cols
        face = isk(FRONT) if m["face"] == "front" else isk(END)
        du, dv = nb.sub(lu, m["cu"]), nb.sub(lv, m["cv"])
        ca, sa = math.cos(math.radians(m["turn"])), math.sin(math.radians(m["turn"]))
        uu = nb.add(nb.div(nb.add(nb.mul(du, ca), nb.mul(dv, sa)), m["w"]), 0.5)
        vv = nb.add(nb.div(nb.sub(nb.mul(dv, ca), nb.mul(du, sa)), m["h"]), 0.5)
        within = nb.mul(nb.band(uu, 0.0, 1.0, 0.001), nb.band(vv, 0.0, 1.0, 0.001))
        img = nb.node("ShaderNodeTexImage", image=sheet, extension="CLIP", interpolation="Linear")
        x = nb.div(nb.add(nb.clamp(uu), c), cols)
        y = nb.div(nb.add(nb.clamp(vv), rows - 1 - r), rows)
        nb.put(img.inputs["Vector"], nb.comb(x, y, 0.0))
        mask = nb.mul(nb.mul(nb.gray(img.outputs["Color"]), within), face)
        if m["ink"] == K.MARKER_INK:
            a = nb.mul(nb.ss(mask, 0.3, 0.62), 0.95)
            rough = nb.mixf(a, rough, 0.5)
        else:
            mott = nb.mr(nb.noise(vec(s=10 + i), 26.0, detail=3), 0.25, 0.75, 0.5, 1.0)
            a = nb.mul(nb.mul(nb.ss(mask, 0.25, 0.7), mott), 0.88)
        col = nb.mixc(a, col, hexc(m["ink"]))

    # dust settles on whatever faces up, thinner where hands and other boxes rub the edges
    up = nb.ss(nz, 0.6, 0.95)
    dn = nb.noise(vec(s=11), 1.8, detail=6, rough=0.6, distortion=0.6)
    film = nb.mr(dn, 0.2, 0.8, 0.3, 0.75)
    dust = nb.mul(nb.mul(up, film), nb.mul(b["dust"], nb.inv(nb.mul(edge, 0.7))))
    speck = nb.mul(nb.mul(up, nb.ss(nb.noise(vec(s=12), 70.0, detail=2), 0.55, 0.7)), 0.3 * b["dust"])
    dust = nb.mul(nb.add(dust, speck, clamp=True), nb.inv(nb.mul(tape, 0.55)))  # tape sheds it
    col = nb.mixc(nb.mul(dust, 0.5), col, hexc("#9D958A"))
    rough = nb.mixf(dust, rough, 0.95)
    height = nb.add(height, nb.mul(dust, 0.1))
    return Channels(col, 1.0, rough, 0.0, height, bump_dist=0.004, bump_strength=0.8)


def rig(name, b, sheet):
    """A bake rig whose normals also round the box's edges (the Bevel node), so they catch light."""
    r = bake.Rig(f"bk_{name}", lambda nb: cardboard(nb, b, sheet))
    bump = r.bsdf.inputs["Normal"].links[0].from_node
    bev = r.nb.node("ShaderNodeBevel", samples=8)
    r.nb.put(bev.inputs[0], 0.025)
    r.nb.links.new(bev.outputs[0], bump.inputs["Normal"])
    return r


def stage_textures():
    reset()
    objs, _, density = build_all(baking=True)
    print(f"atlas: {density:.0f} texels a stud")
    for i, ob in enumerate(objs.values()):
        ob.location.x = i * 4.0
    sheet = bake.load(LABELS, True)
    bake.SIZES[SET] = (K.TEX, K.TEX)
    items = [(ob, rig(name, K.BOXES[name], sheet)) for name, ob in objs.items()]
    mk = build_marked(baking=True)
    mk.location.x = len(objs) * 4.0
    items.append((mk, rig("Marked", K.MARKED, sheet)))
    bake.bake_set(SET, items, TEX, samples=32)


# --- export ---------------------------------------------------------------------------------

def material(for_export):
    """The baked maps. No metalness map: cardboard has none, and Roblox reads none as 0."""
    key = f"{SET}{'_export' if for_export else ''}"
    if key in bpy.data.materials:
        return bpy.data.materials[key]
    mat = bpy.data.materials.new(SET if for_export else key)
    nb = NB(mat)
    p = lambda k: os.path.join(TEX, f"{SET}_{k}.png")  # noqa: E731
    col = nb.node("ShaderNodeTexImage", image=bake.load(p("Color"), False))
    rough = nb.node("ShaderNodeTexImage", image=bake.load(p("Roughness"), True))
    nrm = nb.node("ShaderNodeTexImage", image=bake.load(p("Normal"), True))
    nm = nb.node("ShaderNodeNormalMap")
    nb.put(nm.inputs["Color"], nrm.outputs["Color"])
    bsdf = nb.node("ShaderNodeBsdfPrincipled")
    out = nb.node("ShaderNodeOutputMaterial")
    nb.put(bsdf.inputs["Base Color"], col.outputs["Color"])
    nb.put(bsdf.inputs["Roughness"], rough.outputs["Color"])
    nb.put(bsdf.inputs["Normal"], nm.outputs["Normal"])
    nb.links.new(bsdf.outputs[0], out.inputs["Surface"])
    return mat


def stage_export():
    reset()
    objs, all_faces, density = build_all(baking=False)
    mat = material(True)
    rows = {}
    for i, (F, ob) in enumerate(zip(all_faces, objs.values())):
        b = K.BOXES[F.name]
        ob.data.uv_layers.remove(ob.data.uv_layers["Local"])
        ob.data.materials.append(mat)
        ob.location.x = i * 4.0
        rows[F.name] = dict(size=(b["w"], b["h"], b["d"]), tris=F.tris(), open=bool(b.get("open")))
    parts = build_marked()
    seam = render.simple("Seam", (*[c / 255 for c in K.CUE["rgb"]], 1.0))
    for nm, ob in parts.items():
        ob.data.uv_layers.remove(ob.data.uv_layers["Local"])
        ob.data.materials.append(seam if nm == "Seam" else mat)
        ob.location.x += len(objs) * 4.0
    os.makedirs(OUT, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    for ob in list(objs.values()) + list(parts.values()):
        ob.select_set(True)
    bpy.context.view_layer.objects.active = objs["Medium"]
    fbx = os.path.join(OUT, "Boxes.fbx")
    bpy.ops.export_scene.fbx(
        filepath=fbx, use_selection=True, object_types={"MESH"},
        apply_scale_options="FBX_SCALE_UNITS", axis_forward="Z", axis_up="Y",
        use_mesh_modifiers=True, mesh_smooth_type="OFF", use_tspace=False,
        add_leaf_bones=False, bake_anim=False, path_mode="COPY", embed_textures=True)
    print("FBX", fbx, {n: r["tris"] for n, r in rows.items()}, f"{density:.0f} texels a stud")
    K.write_luau(os.path.join(K.ROOT, "src", "shared", "Boxes", "Specs.luau"), rows,
                 marked_rows(parts))


def to_roblox(v):
    """Blender's (x, y, z) to Roblox's, through the FBX's axes (as the finds kit's)."""
    return (-v[0], v[2], v[1])


def marked_rows(parts):
    """The marked box's numbers for the Specs module, in Roblox axes from the box's pivot."""
    b, rows, tris = K.MARKED, [], 0
    axes = {n: a for n, _, a in K.MARKED_PARTS}
    for nm, hinge, _ in K.MARKED_PARTS:
        me = parts[nm].data
        lo = [min(v.co[i] for v in me.vertices) for i in range(3)]
        hi = [max(v.co[i] for v in me.vertices) for i in range(3)]
        n = sum(len(p.vertices) - 2 for p in me.polygons)
        tris += n
        size = [abs(c) for c in to_roblox([h - l for h, l in zip(hi, lo)])]
        rows.append(dict(name=f"Marked_{nm}", pivot=to_roblox(hinge), size=size, tris=n,
                         axis=to_roblox(axes[nm]) if axes[nm] else None))
    tracks = [(p, ch, ease.keys(ks)) for p, ch, ks in K.OPEN["tracks"]]
    return dict(size=(b["w"], b["h"], b["d"]), tris=tris, parts=rows, tracks=tracks,
                cue_rgb=K.CUE["rgb"], light_rgb=ease.kelvin(K.CUE["light_kelvin"]))


# --- look sheets ----------------------------------------------------------------------------

def place(objs, name, x, y, z=0.0, turn=0.0, copy=False):
    ob = objs[name]
    if copy:
        ob = ob.copy()
        bpy.context.scene.collection.objects.link(ob)
    ob.location = (x, y, z)
    ob.rotation_euler = (0.0, 0.0, math.radians(turn))
    return ob


def unit_room(coll):
    """A unit's inside for the shots: its concrete floor and R-panel walls, the doorway at y=0."""
    part = bake.textured("Partition", UNIT_TEX)
    conc = bake.textured("Concrete", UNIT_TEX)
    m = geo.Mesh("room_floor")
    geo.box(m, (-6, -6, -0.2), (6, 12, 0), geo.map_floor(8.0))
    m.build(coll).data.materials.append(conc)
    for nm, lo, hi in (("back", (-6, 12, 0), (6, 12.2, 10)), ("left", (-6.2, 0, 0), (-6, 12, 10)),
                       ("right", (6, 0, 0), (6.2, 12, 10))):
        m = geo.Mesh(f"room_{nm}")
        geo.box(m, lo, hi, geo.map_wall(10.0))
        m.build(coll).data.materials.append(part)


def light(name, kind, loc, target, energy, colour, size=1.0):
    ld = bpy.data.lights.new(name, kind)
    ld.energy = energy
    ld.color = colour
    if kind == "AREA":
        ld.size = size
    else:
        ld.shadow_soft_size = size
    ob = bpy.data.objects.new(name, ld)
    bpy.context.scene.collection.objects.link(ob)
    ob.location = loc
    ob.rotation_euler = (Vector(target) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
    return ob


def stage_renders():
    reset()
    render.setup(96, (1600, 900))
    objs, _, _ = build_all(baking=False)
    mat = material(False)
    for ob in objs.values():
        ob.data.materials.append(mat)
    os.makedirs(SHEETS, exist_ok=True)

    # 1. the line-up, in the studio
    studio = render.studio_rig()
    for o in studio:
        o.hide_render = False
    xs = {"Small": -4.6, "Medium": -2.5, "Large": -0.1, "Wardrobe": 2.7, "Open": 5.6}
    turns = {"Small": -18, "Medium": -24, "Large": -30, "Wardrobe": -34, "Open": -26}
    for n, x in xs.items():
        place(objs, n, x, 0.0, 0.0, turns[n])
    cam = render.camera((0.6, -12.5, 4.2), (0.6, 0.0, 1.5), lens=40)
    render.shoot(cam, os.path.join(SHEETS, "boxes-lineup.png"), exposure=-0.2)
    cam = render.camera((-3.2, -3.4, 2.4), (-2.5, 0.0, 0.9), lens=40)
    render.shoot(cam, os.path.join(SHEETS, "boxes-close.png"), exposure=-0.2)
    for o in studio:
        o.hide_render = True

    # 2. stacked at the back of an open unit, lit from the hall through the doorway
    render.world((0.004, 0.005, 0.007), 1.0)
    unit_room(bpy.context.scene.collection)
    place(objs, "Wardrobe", -4.4, 10.6, 0.0, 6)
    place(objs, "Large", -1.9, 10.9, 0.0, -3)
    place(objs, "Medium", -1.85, 10.85, 2.4, 9)
    place(objs, "Small", -1.8, 10.9, 4.0, -7)
    place(objs, "Medium", 0.3, 10.9, 0.0, -2, copy=True)
    place(objs, "Large", 2.4, 10.8, 0.0, 4, copy=True)
    place(objs, "Small", 0.4, 10.8, 1.6, 21, copy=True)
    place(objs, "Open", 0.9, 7.6, 0.0, 28)
    place(objs, "Small", 4.4, 10.9, 0.0, 85, copy=True)
    place(objs, "Medium", -3.6, 7.9, 0.0, 64, copy=True)
    hall = light("hall", "AREA", (0.0, -3.0, 11.0), (0.0, 6.0, 0.0), 900.0, (0.9, 0.94, 1.0), size=6.0)
    cam = render.camera((1.2, -4.5, 4.6), (-0.6, 9.0, 1.8), lens=26)
    render.shoot(cam, os.path.join(SHEETS, "boxes-unit.png"), exposure=0.3)
    hall.hide_render = True
    render.flashlight(cam, True, (-1.5, 10.5, 1.8))
    render.shoot(cam, os.path.join(SHEETS, "boxes-unit-dark.png"), exposure=0.3)


def pose(parts, t):
    """The marked box `t` seconds into its Open motion (0: shut), the keys sampled as the game will."""
    axes = {n: a for n, _, a in K.MARKED_PARTS}
    for ob in parts.values():
        ob.rotation_mode = "AXIS_ANGLE"
        ob.rotation_axis_angle = (0.0, 0.0, 0.0, 1.0)
        ob.scale = (1.0, 1.0, 1.0)
    for part, ch, ks in K.OPEN["tracks"]:
        v = ease.sample(ease.keys(ks), t)
        if ch == "turn":
            parts[part].rotation_axis_angle = (math.radians(v), *axes[part])
        elif ch == "scale":
            parts[part].scale = (v, v, v)


def stage_marked():
    """The marked box's sheets: art/sheets/boxes-marked-*.png, and its opening as a filmstrip and
    an MP4 (out/marked-open.mp4), all in an M unit among somebody's stuff."""
    import shutil
    import subprocess
    reset()
    render.setup(96, (1600, 900))
    objs, _, _ = build_all(baking=False)
    mat = material(False)
    for ob in objs.values():
        ob.data.materials.append(mat)
    parts = build_marked()
    root = bpy.data.objects.new("Marked", None)
    bpy.context.scene.collection.objects.link(root)
    for nm, ob in parts.items():
        ob.parent = root
        if nm != "Seam":
            ob.data.materials.append(mat)
    glow = render.emissive("SeamGlow", (*[c / 255 for c in K.CUE["rgb"]], 1.0), 3.0)
    parts["Seam"].data.materials.append(glow)
    os.makedirs(SHEETS, exist_ok=True)

    render.world((0.004, 0.005, 0.007), 1.0)
    unit_room(bpy.context.scene.collection)
    place(objs, "Wardrobe", -4.4, 10.6, 0.0, 6)  # somebody's stuff, against the back wall
    place(objs, "Large", -1.9, 10.9, 0.0, -3)
    place(objs, "Medium", -1.85, 10.85, 2.4, 9)
    place(objs, "Small", 3.6, 10.9, 0.0, 12)
    place(objs, "Open", 4.2, 8.2, 0.0, 40)
    root.location, root.rotation_euler = (0.6, 6.4, 0.0), (0.0, 0.0, math.radians(-18))
    hall = light("hall", "AREA", (0.0, -3.0, 11.0), (0.0, 6.0, 0.0), 900.0, (0.9, 0.94, 1.0), size=6.0)
    # inside the top, the cue's warm light, as the game's optional PointLight
    lt = ease.kelvin(K.CUE["light_kelvin"])
    cue = light("cue", "POINT", (0.0, 0.0, K.MARKED["h"] + 0.05), (0.0, 0.0, 0.0), 1.2,
                tuple(c / 255 for c in lt), size=0.1)
    cue.parent = root
    seam, sheet = parts["Seam"], lambda n: os.path.join(SHEETS, f"boxes-marked-{n}.png")  # noqa: E731

    def cued(on):
        seam.hide_render = not on
        cue.hide_render = not on

    pose(parts, 0.0)
    cam = render.camera((1.2, -4.5, 4.6), (0.2, 7.0, 0.8), lens=26)  # a player at the doorway
    cued(False)
    render.shoot(cam, sheet("unit"), exposure=0.3)
    cued(True)
    render.shoot(cam, sheet("unit-cue"), exposure=0.3)
    hall.hide_render = True
    render.flashlight(cam, True, (0.6, 6.4, 0.8))
    cued(False)
    render.shoot(cam, sheet("dark"), exposure=0.3)
    cued(True)
    render.shoot(cam, sheet("dark-cue"), exposure=0.3)
    render.flashlight(cam, False, (0.6, 6.4, 0.8))
    hall.hide_render = False

    close = render.camera((-0.4, 3.2, 3.3), (0.6, 6.4, 1.2), lens=35)  # kneeling to open it
    render.shoot(close, sheet("close-cue"), exposure=0.1)
    cued(False)
    pose(parts, K.OPEN["duration"])
    render.shoot(close, sheet("open"), exposure=0.1)

    # the opening: frames at 30 a second, a filmstrip of ten and an MP4
    sc = bpy.context.scene
    sc.render.resolution_x, sc.render.resolution_y = 480, 360
    sc.cycles.samples = 24
    tmp = os.path.join(OUT, "frames")
    shutil.rmtree(tmp, ignore_errors=True)
    os.makedirs(tmp)
    n = int(round((K.OPEN["duration"] + 0.25) * 30)) + 1
    frames = []
    for i in range(n):
        t = i / 30.0 - 0.1  # a beat shut first, lit as a box with something in it
        cued(t < 0.12)
        pose(parts, max(t, 0.0))
        f = os.path.join(tmp, f"open-{i:03d}.png")
        render.shoot(close, f)
        frames.append(f)
    ff = lambda *a: subprocess.run(["ffmpeg", "-y", "-loglevel", "error", *a], check=True)  # noqa: E731
    ff("-framerate", "30", "-i", os.path.join(tmp, "open-%03d.png"), "-c:v", "libx264",
       "-pix_fmt", "yuv420p", os.path.join(OUT, "marked-open.mp4"))
    pick = [frames[min(round(i * (n - 1) / 9), n - 1)] for i in range(10)]
    args = []
    for f in pick:
        args += ["-i", f]
    lay = "|".join(f"{(i % 5) * 480}_{(i // 5) * 360}" for i in range(10))
    ff(*args, "-filter_complex", f"xstack=inputs=10:layout={lay}", sheet("open-strip"))
    shutil.rmtree(tmp, ignore_errors=True)
    print("RENDERED", sheet("open-strip"))


STAGES = {"labels": stage_labels, "textures": stage_textures, "export": stage_export,
          "renders": stage_renders, "marked": stage_marked}

if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--stage", choices=list(STAGES), required=True)
    STAGES[ap.parse_args(argv).stage]()
    print("DONE")
