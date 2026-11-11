"""Build the wrap a kept player stands in, in Blender, headless (art/keptwrap/README.md).

    blender -b --factory-startup -P art/keptwrap/build.py -- --stage textures|export|renders

Stages:
    textures  the KeptWrap texture set, baked from its recipe into out/textures; its colour map
              carries the film's alpha (how see-through it is), for SurfaceAppearance's
              AlphaMode Transparency
    export    out/KeptWrap.fbx (one MeshPart) and src/shared/KeptWrap/Specs.luau
    renders   the look sheets, art/sheets/keptwrap-*.png

It borrows the finds' recipe kit (Look, Coat) and the boxes' unit room for the sheets, as the
bubble wrap does. Its UVs are laid by hand: one cylinder round the body, its seam down the back,
so every stage lays them alike and nothing is saved between stages.
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
import numpy as np  # noqa: E402
from mathutils import Vector  # noqa: E402

import bake  # noqa: E402
import geo  # noqa: E402
import render  # noqa: E402
import spec as K  # noqa: E402
from nodes import NB, hexc  # noqa: E402

OUT = os.path.join(HERE, "out")
TEX = os.path.join(OUT, "textures")
SHEETS = os.path.join(K.ROOT, "art", "sheets")
FBX = os.path.join(OUT, f"{K.SET}.fbx")
SPECS = os.path.join(K.ROOT, "src", "shared", "KeptWrap", "Specs.luau")
PAD = 8  # texels round the atlas's edge


def finds_kit():
    """The finds' build, as a library, pointed at this folder (its spec is already this one)."""
    s = importlib.util.spec_from_file_location("finds_build", os.path.join(FINDS, "build.py"))
    mod = importlib.util.module_from_spec(s)
    s.loader.exec_module(mod)
    assert mod.K is K, "the finds' build must see the wrap's spec"
    mod.OUT, mod.TEX, mod.UVS, mod.FBX = OUT, TEX, os.path.join(OUT, "uvs.npz"), FBX
    return mod


kit = finds_kit()


# --- geometry --------------------------------------------------------------------------------

def pchip(xs, ys):
    """A smooth curve through (xs, ys) that never overshoots between them (Fritsch-Carlson), so
    the cocoon swells and narrows only where the stations say."""
    n = len(xs)
    h = [xs[i + 1] - xs[i] for i in range(n - 1)]
    d = [(ys[i + 1] - ys[i]) / h[i] for i in range(n - 1)]
    m = [d[0]] + [0.0] * (n - 2) + [d[-1]]
    for i in range(1, n - 1):
        if d[i - 1] * d[i] > 0:
            w1, w2 = 2 * h[i] + h[i - 1], h[i] + 2 * h[i - 1]
            m[i] = (w1 + w2) / (w1 / d[i - 1] + w2 / d[i])

    def f(x):
        i = max(0, min(n - 2, next((k for k in range(n - 1) if x <= xs[k + 1]), n - 2)))
        t = (x - xs[i]) / h[i]
        t2, t3 = t * t, t * t * t
        return ((2 * t3 - 3 * t2 + 1) * ys[i] + (t3 - 2 * t2 + t) * h[i] * m[i]
                + (-2 * t3 + 3 * t2) * ys[i + 1] + (t3 - t2) * h[i] * m[i + 1])
    return f


def section(z):
    """The cocoon's section at height z: (half-width, half-depth, its middle's y, round)."""
    zs = [s[0] for s in K.STATIONS]
    return tuple(pchip(zs, [s[k] for s in K.STATIONS])(z) for k in (1, 2, 3, 4))


def lump(a, z):
    """The film's small wander off a perfect skin, studs: a few slow waves round and up."""
    return K.LUMP * (0.5 * math.sin(3 * a + 1.7 * z) + 0.3 * math.sin(5 * a - 2.3 * z + 1.0)
                     + 0.2 * math.sin(2 * a + 4.1 * z + 2.0))


def ring_point(z, a):
    """The point at height z, angle a round from the back (+Y), towards its left (+X)."""
    hx, hy, cy, n = section(z)
    s, c = math.sin(a), math.cos(a)
    e = 2.0 / n
    x = hx * math.copysign(abs(s) ** e, s)
    y = hy * math.copysign(abs(c) ** e, c)
    r = math.hypot(x, y)
    k = 1.0 + lump(a, z) / r if r > 1e-4 else 1.0
    return Vector((x * k, cy + y * k, z))


def wrap_geo():
    """Rings up from the floor, a pole over the twist; UVs a cylinder, its seam down the back:
    U round the body from the back, V the length up its surface."""
    top = K.STATIONS[-1][0]
    nz = max(2, round(top / K.STEP))
    zs = [top * j / nz for j in range(nz + 1)]
    segs = K.SEGS
    rings = [[ring_point(z, 2 * math.pi * i / segs) for i in range(segs)] for z in zs]
    pole = Vector((0.0, K.STATIONS[-1][3], top + 0.02))
    # V by the mean length up the surface, so the bands' texels are even from feet to crown
    s = [0.0]
    for a, b in zip(rings, rings[1:]):
        s.append(s[-1] + sum((pb - pa).length for pa, pb in zip(a, b)) / segs)
    s.append(s[-1] + sum((pole - p).length for p in rings[-1]) / segs)
    span = (K.TEX - 2 * PAD) / K.TEX

    def uv(i, j):
        return (PAD / K.TEX + span * i / segs, PAD / K.TEX + span * s[j] / s[-1])

    m = geo.Mesh(K.SET)
    idx = [[m.vert(p) for p in ring] for ring in rings]
    tip = m.vert(pole)
    for j in range(nz):
        for i in range(segs):
            i2 = (i + 1) % segs
            m.face((idx[j][i], idx[j][i2], idx[j + 1][i2], idx[j + 1][i]),
                   [uv(i, j), uv(i + 1, j), uv(i + 1, j + 1), uv(i, j + 1)], True)
    for i in range(segs):
        m.face((idx[nz][i], idx[nz][(i + 1) % segs], tip),
               [uv(i, nz), uv(i + 1, nz), uv(i + 0.5, nz + 1)], True)
    return m


def build_wrap(coll=None):
    ob = geo.Mesh.build(wrap_geo(), coll, sharp_angle=None)
    me = ob.data
    for p in me.polygons:
        p.use_smooth = True
    # outward: rings run anticlockwise seen from above (back, then its left), so faces point out
    me.flip_normals() if _inward(me) else None
    me.update()
    print(f"atlas: {kit.density([ob]):.0f} texels a stud, {kit.tris(ob)} triangles")
    return ob


def _inward(me):
    """Whether the faces point into the cocoon (their normals towards its axis)."""
    me.calc_loop_triangles()
    inward = 0
    for p in me.polygons:
        c = p.center
        out = Vector((c.x, c.y, 0.0))
        inward += 1 if p.normal.dot(out) < 0 else 0
    return inward > len(me.polygons) / 2


def box(ob):
    vs = [ob.matrix_world @ v.co for v in ob.data.vertices]
    return (Vector([min(v[i] for v in vs) for i in range(3)]),
            Vector([max(v[i] for v in vs) for i in range(3)]))


# --- the recipe ------------------------------------------------------------------------------

def wrap_look(nb):
    """Clear stretch film wound up a standing body in a spiral of overlapping bands: one layer
    cloudy, two where they overlap, a thin bright cord along every band's edge (the film necks as
    it's pulled), fine streaks along each band where it's stretched, wrinkles where it bridged a
    hollow, and the film gathered and twisted shut over the crown."""
    L = kit.Look(nb, K.SEED)
    x, y, z = L.x, L.y, L.z
    a = nb.math("ARCTAN2", x, y)                 # round the body from the back, -pi..pi
    turn = nb.div(nb.add(a, math.pi), 2 * math.pi)  # 0..1 round the body
    step = K.BAND * (1.0 - K.LAP)
    # each band starts `step` above the last and climbs PITCH a turn
    q = nb.fract(nb.div(nb.sub(z, nb.mul(turn, K.PITCH)), step))
    two = K.BAND / step - 1.0                    # the lower part of every band lies over the last
    lapped = nb.ss(q, two + 0.015, two - 0.015)  # 1 where two layers overlap
    film = nb.tint(hexc("#DCE6E8"), nb.mr(L.noise(2.2, 1, detail=3), 0.3, 0.7, 0.9, 1.04))
    C = kit.Coat(L, film, 0.1, 0.0)
    alpha = nb.mixf(lapped, K.ALPHA["one"], K.ALPHA["two"])
    # the cloud: thicker and thinner patches where it was pulled harder
    alpha = nb.add(alpha, nb.mr(L.noise(1.4, 2, detail=3), 0.3, 0.7, -0.07, 0.07))
    C.paint(nb.mul(lapped, 0.6), hexc("#E6EEEF"))

    # the edge cords: the outer band's lower edge, bright and proud; the band under it showing
    # its upper edge through one layer, fainter
    ew = K.EDGE_W / step
    outer = nb.mul(nb.ss(q, ew * 1.6, ew * 0.4), nb.ss(q, 0.0, ew * 0.2))
    outer = nb.add(outer, nb.ss(q, 1.0 - ew * 0.3, 1.0), clamp=True)
    inner = nb.band(q, two - ew * 0.5, two + ew * 0.5, ew * 0.5)
    wob = nb.mr(L.noise(9.0, 3, detail=2), 0.3, 0.7, 0.6, 1.0)
    C.paint(nb.mul(outer, wob), hexc("#F4F8F8"), 0.22, height=0.9)
    C.paint(nb.mul(inner, 0.5), hexc("#EAF0F1"), height=0.25)
    alpha = nb.mixf(nb.mul(outer, wob), alpha, K.ALPHA["edge"])
    alpha = nb.mixf(nb.mul(inner, 0.5), alpha, K.ALPHA["edge"] * 0.7)

    # streaks along the band, where the film was stretched round the body
    streak = nb.band(L.noise(5.0, 4, stretch=(0.18, 0.18, 4.0), detail=3), 0.47, 0.53, 0.02)
    C.paint(nb.mul(streak, 0.6), hexc("#EEF3F4"), 0.16, height=0.3)
    alpha = nb.add(alpha, nb.mul(streak, K.ALPHA["crease"] * 0.5))

    # wrinkles where the film bridged a hollow: the cone from the hands to the thighs, the neck,
    # the crown; running up and down the body there, not along the band
    hollow = nb.add(nb.add(nb.band(z, 1.2, 1.75, 0.12), nb.band(z, 3.9, 4.35, 0.1)),
                    nb.ss(z, 5.0, 5.3), clamp=True)
    wr = nb.band(L.noise(4.0, 5, stretch=(3.0, 3.0, 0.3), detail=4, distortion=0.4),
                 0.46, 0.54, 0.03)
    C.paint(nb.mul(nb.mul(wr, hollow), 0.8), hexc("#F0F4F5"), 0.2, height=0.5)
    alpha = nb.add(alpha, nb.mul(nb.mul(wr, hollow), K.ALPHA["crease"]))

    # the twist over the crown: film bunched and turned, milky, creases spiralling to the tip
    twist = nb.ss(z, 5.22, 5.42)
    spiral = nb.fract(nb.add(nb.mul(turn, 7.0), nb.mul(z, 9.0)))
    rope = nb.mul(twist, nb.band(spiral, 0.35, 0.65, 0.18))
    C.paint(twist, hexc("#E3EAEB"), 0.2)
    C.paint(rope, hexc("#F6F9F9"), height=0.6)
    alpha = nb.mixf(twist, alpha, K.ALPHA["twist"])

    C.finish(ao=0.15, ao_low=0.75, dust=K.DUST)
    ch = C.channels(dist=0.006, strength=0.8)
    ch.ova = nb.math("ADD", alpha, 0.0, clamp=True)
    return ch


# --- the bake ----------------------------------------------------------------------------------

def bake_wrap(ob, samples=32):
    """The finds' bake, with the alpha baked too and written into the colour map's alpha."""
    bake.gpu_cycles(samples)
    sc = bpy.context.scene
    sc.render.bake.margin = 0
    r = bake.Rig("bk_wrap", wrap_look)
    ob.data.materials.clear()
    ob.data.materials.append(r.mat)
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    res = {}
    for k in ("cover", "col", "ova", "rough", "metal", "normal"):
        img = bpy.data.images.new(f"{K.SET}_{k}", K.TEX, K.TEX, alpha=True, float_buffer=True)
        img.colorspace_settings.name = "Non-Color"
        img.generated_color = (0.5, 0.5, 1.0, 1.0) if k == "normal" else (0, 0, 0, 1)
        if k == "cover":
            r.nb.links.new(r.nb.val(1.0), r.emit.inputs["Color"])
            r.nb.links.new(r.emit.outputs[0], r.out.inputs["Surface"])
        else:
            r.channel(k)
        r.target(img)
        kind = "NORMAL" if k == "normal" else "EMIT"
        bpy.ops.object.bake(type=kind, normal_space="TANGENT", margin=0, use_clear=False)
        res[k] = bake.pixels(img)
    covered = res.pop("cover")[..., 0] > 0.5
    os.makedirs(OUT, exist_ok=True)
    bake.write_png(os.path.join(OUT, "cover.png"), bake.q8(covered.astype(np.float32)))
    for k in res:
        res[k] = kit.dilate(res[k], covered, PAD)
    os.makedirs(TEX, exist_ok=True)
    out = lambda k: os.path.join(TEX, f"{K.SET}_{k}.png")  # noqa: E731
    rgba = np.concatenate([bake.q8(bake.to_srgb(res["col"][..., :3])),
                           bake.q8(res["ova"][..., :1])], axis=2)
    bake.write_png(out("Color"), rgba)
    bake.write_png(out("Normal"), bake.q8(res["normal"][..., :3]))
    bake.write_png(out("Roughness"), bake.q8(res["rough"][..., 0]))
    bake.write_png(out("Metalness"), bake.q8(res["metal"][..., 0]))
    a = res["ova"][..., 0][covered]
    print("BAKED", K.SET, f"{covered.mean():.0%} of the atlas is islands; alpha "
          f"{a.min():.2f}..{a.max():.2f}, mean {a.mean():.2f}")


def stage_textures():
    kit.reset()
    bake_wrap(build_wrap())


# --- export ---------------------------------------------------------------------------------

def material():
    """The baked maps; the colour map's alpha into the BSDF's, so renders show the film clear."""
    if K.SET in bpy.data.materials:
        return bpy.data.materials[K.SET]
    mat = bpy.data.materials.new(K.SET)
    nb = NB(mat)
    p = lambda k: os.path.join(TEX, f"{K.SET}_{k}.png")  # noqa: E731
    col = nb.node("ShaderNodeTexImage", image=bake.load(p("Color"), False))
    rough = nb.node("ShaderNodeTexImage", image=bake.load(p("Roughness"), True))
    metal = nb.node("ShaderNodeTexImage", image=bake.load(p("Metalness"), True))
    nrm = nb.node("ShaderNodeTexImage", image=bake.load(p("Normal"), True))
    nm = nb.node("ShaderNodeNormalMap")
    nb.put(nm.inputs["Color"], nrm.outputs["Color"])
    bsdf = nb.node("ShaderNodeBsdfPrincipled")
    out = nb.node("ShaderNodeOutputMaterial")
    nb.put(bsdf.inputs["Base Color"], col.outputs["Color"])
    nb.put(bsdf.inputs["Alpha"], col.outputs["Alpha"])
    nb.put(bsdf.inputs["Roughness"], rough.outputs["Color"])
    nb.put(bsdf.inputs["Metallic"], metal.outputs["Color"])
    nb.put(bsdf.inputs["Normal"], nm.outputs["Normal"])
    nb.links.new(bsdf.outputs[0], out.inputs["Surface"])
    return mat


def stage_export():
    kit.reset()
    ob = build_wrap()
    ob.data.materials.append(material())
    os.makedirs(OUT, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.export_scene.fbx(
        filepath=FBX, use_selection=True, object_types={"MESH"},
        apply_scale_options="FBX_SCALE_UNITS", axis_forward="Z", axis_up="Y",
        use_mesh_modifiers=True, mesh_smooth_type="OFF", use_tspace=False,
        add_leaf_bones=False, bake_anim=False, path_mode="COPY", embed_textures=True)
    lo, hi = box(ob)
    size = (hi.x - lo.x, hi.z - lo.z, hi.y - lo.y)
    c = (lo + hi) / 2
    centre = K.to_roblox((c.x, c.y, c.z - K.ROOT_Z))  # from the root, not the floor
    tris = kit.tris(ob)
    print("FBX", FBX, {K.SET: tris})
    os.makedirs(os.path.dirname(SPECS), exist_ok=True)
    K.write_luau(SPECS, size, centre, tris)
    # what in the body the wrap fails to hold, by part (box corners outside the film)
    poke = {}
    for name, b in body_boxes().items():
        n = sum(1 for p in corners(b) if not inside(p))
        if n:
            poke[name] = n
    print("atlas: body box corners outside the film", poke or "none")


# --- the body under it (the look sheets and the fit check) -----------------------------------

def body_boxes():
    """The R15 body's parts as Blender boxes ((x0, y0, z0), (x1, y1, z1)), the right side
    mirrored from the left."""
    out = {}
    for name, (x0, x1, y0, y1, z0, z1) in K.BODY_PARTS.items():
        # Roblox root space to Blender: x = -X, y = Z, z = Y + ROOT_Z
        b = ((-x1, z0, y0 + K.ROOT_Z), (-x0, z1, y1 + K.ROOT_Z))
        out[name] = b
        if name.startswith("Left"):
            out["Right" + name[4:]] = ((-b[1][0], b[0][1], b[0][2]), (-b[0][0], b[1][1], b[1][2]))
    return out


def corners(b):
    (x0, y0, z0), (x1, y1, z1) = b
    # a part's box corners pulled in a little: its mesh is rounder than its box
    ix, iy, iz = (x1 - x0) * 0.12, (y1 - y0) * 0.12, (z1 - z0) * 0.05
    return [(x, y, z) for x in (x0 + ix, x1 - ix) for y in (y0 + iy, y1 - iy)
            for z in (z0 + iz, z1 - iz)]


def inside(p):
    x, y, z = p
    if z < 0.0 or z > K.STATIONS[-1][0]:
        return False
    hx, hy, cy, n = section(z)
    return abs(x / hx) ** n + abs((y - cy) / hy) ** n <= 1.0


def body(coll):
    """A blocky stand-in for a player: rounded boxes in plain clothes."""
    cols = {"Head": "#C99C76", "Hand": "#C99C76", "Torso": "#3F5F80", "Arm": "#3F5F80",
            "Leg": "#2E323C", "Foot": "#1E1F22"}
    obs = []
    for name, (lo, hi) in body_boxes().items():
        key = next(k for k in cols if k in name)
        m = geo.Mesh(f"body_{name}")
        geo.box(m, lo, hi, None, bevel=min(0.18, min(hi[i] - lo[i] for i in range(3)) * 0.3),
                segments=3)
        ob = m.build(coll, sharp_angle=None)
        for p in ob.data.polygons:
            p.use_smooth = True
        ob.data.materials.append(render.simple(f"body_{key}", hexc(cols[key]), 0.75))
        obs.append(ob)
    return obs


# --- look sheets ----------------------------------------------------------------------------

def stage_renders():
    kit.reset()
    render.setup(128, (1600, 900))
    sc = bpy.context.scene
    sc.cycles.transparent_max_bounces = 16
    coll = sc.collection
    wrap = build_wrap(coll)
    wrap.data.materials.append(material())
    people = body(coll)
    os.makedirs(SHEETS, exist_ok=True)

    # 1. in the studio: front three-quarter, the whole figure; then close on the chest and head
    studio = render.studio_rig()
    for o in studio:
        o.hide_render = False
    cam = render.camera((-5.6, -11.8, 3.4), (0.0, 0.0, 2.75), lens=35)
    render.shoot(cam, os.path.join(SHEETS, "keptwrap-studio.png"), exposure=-0.3)
    cam = render.camera((-1.2, -3.4, 4.9), (0.0, 0.0, 4.2), lens=40)
    render.shoot(cam, os.path.join(SHEETS, "keptwrap-close.png"), exposure=-0.3)
    for o in studio:
        o.hide_render = True

    # 2. the moment: a friend lifts the door and there you are, standing past the unit's middle
    #    facing the door (Kept.Back 0.62 of its 12-stud depth), lit only by their torch
    bk = kit.boxes_kit()
    bmat = bk.material(False)
    boxes, _, _ = bk.build_all(baking=False)
    for b in boxes.values():
        b.data.materials.append(bmat)
    render.world((0.002, 0.0025, 0.004), 1.0)
    bk.unit_room(coll)
    bk.place(boxes, "Wardrobe", -4.4, 10.6, 0.0, 6)
    bk.place(boxes, "Large", 3.6, 10.8, 0.0, 4)
    bk.place(boxes, "Small", -3.9, 7.0, 0.0, 64)
    for ob in [wrap] + people:
        ob.location = (0.3, 7.4, 0.0)
    cam = render.camera((0.6, -2.0, 4.6), (0.3, 7.4, 3.0), lens=14.6)
    render.flashlight(cam, True, (0.3, 7.4, 3.2))
    render.shoot(cam, os.path.join(SHEETS, "keptwrap-unit.png"), exposure=0.3)
    # 3. a step in, the torch on the face
    cam = render.camera((0.2, 3.4, 4.7), (0.3, 7.4, 4.3), lens=14.6)
    render.flashlight(cam, True, (0.3, 7.4, 4.4))
    render.shoot(cam, os.path.join(SHEETS, "keptwrap-face.png"), exposure=0.3)


STAGES = {"textures": stage_textures, "export": stage_export, "renders": stage_renders}

if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--stage", choices=list(STAGES), required=True)
    STAGES[ap.parse_args(argv).stage]()
    print("DONE")
