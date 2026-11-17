"""The finds kit: build a find's parts high and low, unwrap, bake, export, preview, write Luau.

How to use it is in art/finds/CRAFT.md, "The kit". A set's build.py describes its finds (Find,
Part, a look, lights, motions) and calls `main(SET, FINDS)`; scripts/art.sh runs it:

    scripts/art.sh set lights                       every stage, every find in the set
    scripts/art.sh set lights renders DeskLamp      one stage, one find
"""

import argparse
import math
import os
import shutil
import subprocess
import sys

KIT = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(KIT, "..", "..", ".."))
sys.path.append(os.path.join(ROOT, "art", "unit"))  # after the set's own folder (its spec.py)
sys.path.append(KIT)

import bpy  # noqa: E402
import numpy as np  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402

import bake as ub  # noqa: E402  (the unit's PNG writing, pixels, Cycles on the GPU)
import ease  # noqa: E402
import render  # noqa: E402
from look import Look  # noqa: E402
from nodes import NB, hexc  # noqa: E402

SHEETS = os.path.join(ROOT, "art", "sheets")

# --- texture sizing: how sharp a find is held -------------------------------------------------
TARGET = 300      # texels a stud wanted (the bedroom set has 99); a find held 2 studs from the
                  # camera on a phone shows about 150 screen pixels a stud, so 300 stays crisp
SIZES = (256, 512, 1024)   # a texture set is the smallest of these that reaches TARGET
BIG = 2048        # allowed only for a find marked big (Roblox may shrink it; judge in Studio)
PAD = 6           # texels of gutter round each UV island, filled from the island's own edge
AO_IN_COLOUR = 0.45   # how much of the baked occlusion darkens the colour (Roblox has no AO map)
CAGE = 0.008      # studs: how far outside the game mesh the bake's rays start
REACH = 0.02      # studs: how far they look for the detailed mesh
GOLD = (1.0, 0.766, 0.336)   # gold's own colour (linear), the Gold variant's base
# the held sheet: where a find sits in your hands from your eye, as the torch does in play
# (src/shared/Flashlight/Torch.luau, Hold: 0.62 right, 0.58 down, 1.25 ahead), nearer the middle
# and your eye as you'd hold up a find to look at it; and how far it's turned to show its front
# three quarters
HOLD = (0.3, -0.34, 1.05)
HOLD_TURN = -28.0


class Bone:
    """A bone that bends its part in one place (F-05a: the butter stick's dent). The game mesh's
    vertices within `reach` studs of `at` (the find's frame at rest) follow it, all the way at
    `at` and easing to nothing at `reach`; the rest stay with the part. `weight(co)` (a point in
    the find's frame, studs) gives the share instead, 0 to 1. Its `move` track slides it along
    `axis` (studs), carrying those vertices with it: a dent pressed in, a cheek puffed out; its
    `turn` track tips them about `hinge` through `at` (degrees). A bone that only slides leaves
    the mesh's normals as they were (Roblox skins them, never recomputes them), so a dent's sides
    need bones that turn to catch the light (the butter stick's rim). In Roblox it is a Bone in
    the part's MeshPart, played by its Transform (docs/STUDIO.md "Bones")."""

    def __init__(self, name, at, reach=1.0, axis=(0.0, 0.0, -1.0), weight=None, hinge=None):
        self.name, self.at, self.reach = name, Vector(at), reach
        self.axis, self.weight = Vector(axis).normalized(), weight
        self.hinge = Vector(hinge).normalized() if hinge else None

    def share(self, co):
        if self.weight:
            return max(0.0, min(1.0, self.weight(co)))
        u = max(0.0, 1.0 - (co - self.at).length / self.reach)
        return u * u * (3.0 - 2.0 * u)


class Part:
    """One piece of a find. `build(hi)` returns a shapes.Shape in the find's frame at rest; the
    part turns or slides about `pivot` along `axis` (Blender frame), under `parent`. A `clear`
    part is see-through where its look's alpha says (glass, a flame): its material carries the
    colour map's alpha, so it imports in AlphaMode Transparency (docs/STUDIO.md). An `alone`
    part is baked with nothing else in the scene: it is hidden where it's built and only ever
    seen somewhere else (the blob lamp's blobs, all built in one spot inside the wax). `bones`
    bend the part in places (Bone): its game mesh is skinned to them. An `inside` part is a
    wall seen from within (the glitter goo ball's gel): its builder draws it facing in, and as
    Roblox draws only a face's front, through a clear part it shows the far side's inside while
    its near side lets you see what's in front of it. It casts no shadow (what's inside stays
    lit), neither shades nor is shaded by the other parts in the bake, and the previews cull
    its back faces as Roblox does."""

    def __init__(self, name, build, pivot=(0.0, 0.0, 0.0), parent=None, axis=None, clear=False,
                 alone=False, bones=(), inside=False):
        self.name, self.build, self.pivot, self.parent = name, build, Vector(pivot), parent
        self.axis = Vector(axis).normalized() if axis else None
        self.clear, self.alone, self.bones = clear, alone, list(bones)
        self.inside = inside


class Find:
    """A find: its parts (the first is the root, its pivot the find's), its look, its lights and
    its motions. `glow` says which parts carry the emissive mask and how they light."""

    def __init__(self, name, parts, look, lights=(), motions=None, glow=None, big=False,
                 dust=0.6, seed=0.0, notes="", texels=None, lit=None, drive=None, cage=None,
                 tint=None):
        self.name, self.parts, self.look, self.lights = name, parts, look, list(lights)
        self.motions = motions or {}
        self.glow = glow or {}
        # how it stands when it's on, beyond its glow part lit: {(part, channel): value} (the
        # tea light's flame, scaled to nothing as it's found, at full size)
        self.lit = lit or {}
        self.big, self.dust, self.seed, self.notes = big, dust, seed, notes
        # texels a stud wanted, when a small find's fine detail (the night-light's ribs) needs
        # more than TARGET to stay sharp held up close
        self.texels = texels
        # a find that drives (the RC car): its numbers for the game's wiring, written into the
        # Luau as `Drive` (src/shared/Finds/Art.luau says what each is)
        self.drive = drive
        # how far outside the game mesh the bake's rays start (studs): shorter than CAGE for a
        # find of small pieces packed close (the gel bead ball's beads), whose rays from CAGE out
        # start inside the next piece and bake its surface onto this one; REACH scales with it
        self.cage = cage or CAGE
        # a find whose colour changes where it was pressed (the colour-change goo ball, S2):
        # dict(part, base, warm), two '#RRGGBB'. Its look's alpha says where (the prints); the
        # game tints that part's SurfaceAppearance (AlphaMode TintMask, docs/STUDIO.md "Colour
        # where pressed") from Rest to Warm by the part's `tint` channel (0 to 1). A tint can only
        # darken, so the bake lightens the masked texels by as much as Rest takes off again.
        self.tint = tint or {}
        self.by = {p.name: p for p in parts}
        self.clear = any(p.clear for p in parts)
        self.alone = any(p.alone for p in parts)

    def out(self, set_dir, *rest):
        return os.path.join(set_dir, "out", *rest)


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def tris(ob):
    return sum(len(p.vertices) - 2 for p in ob.data.polygons)


# --- geometry ----------------------------------------------------------------------------------

def build(find, hi, coll):
    """Every part as an object, origin on its pivot. The game mesh (low) gets weighted normals:
    hard edges stay crisp, big faces flat, rounds smooth."""
    objs = {}
    for p in find.parts:
        name = f"{find.name}_{p.name}" + ("_hi" if hi else "")
        ob = p.build(hi).to_object(name, coll, origin=p.pivot)
        ob.data.set_sharp_from_angle(angle=math.radians(50 if not hi else 70))
        if not hi:
            mod = ob.modifiers.new("wn", "WEIGHTED_NORMAL")
            mod.keep_sharp = True
            mod.weight = 50
            dg = bpy.context.evaluated_depsgraph_get()
            me = bpy.data.meshes.new_from_object(ob.evaluated_get(dg))
            ob.modifiers.clear()
            old = ob.data
            ob.data = me
            bpy.data.meshes.remove(old)
            me.name = name
        objs[p.name] = ob
    return objs


def uv_density(objs, size):
    area = uv = 0.0
    for o in objs:
        me = o.data
        lay = me.uv_layers.active.data
        for p in me.polygons:
            area += p.area
            pts = [lay[i].uv for i in p.loop_indices]
            uv += abs(sum(pts[i].x * pts[i - 1].y - pts[i - 1].x * pts[i].y
                          for i in range(len(pts)))) / 2
    return size * math.sqrt(uv / area)


def _pack(objs, size):
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.select_all(action="SELECT")
    bpy.ops.uv.pack_islands(rotate=True, margin_method="FRACTION", margin=PAD / size,
                            shape_method="CONCAVE")
    bpy.ops.object.mode_set(mode="OBJECT")


def unwrap(find, objs):
    """Pack every part's islands into one square, and size the texture set
    to the smallest that reaches TARGET texels a stud. Returns (size, texels a stud)."""
    obs = list(objs.values())
    bpy.ops.object.select_all(action="DESELECT")
    for o in obs:
        o.select_set(True)
        if not o.data.uv_layers:
            o.data.uv_layers.new(name="UVMap")
    bpy.context.view_layer.objects.active = obs[0]
    # the shapes unwrapped themselves at true size (shapes.py); packing scales them all alike
    size = 1024
    _pack(obs, size)
    sizes = SIZES + ((BIG,) if find.big else ())
    target = find.texels or TARGET
    want = next((s for s in sizes if uv_density(obs, s) >= target), sizes[-1])
    if want != size:
        size = want
        _pack(obs, size)
    d = uv_density(obs, size)
    clash = clashes(obs)
    assert not clash, f"{find.name}: faces share texels: {clash}"
    return size, d


def clashes(objs, n=512):
    """Texels (at n x n) claimed by two parts, or by two faces of one part beyond the odd texel
    on a shared edge."""
    owner = np.full((n, n), -1, dtype=np.int32)
    face = np.full((n, n), -1, dtype=np.int64)
    out = {}
    ys, xs = np.mgrid[0:n, 0:n]
    cx, cy = xs + 0.5, ys + 0.5
    for oi, o in enumerate(objs):
        me = o.data
        me.calc_loop_triangles()
        uv = np.empty(len(me.loops) * 2, dtype=np.float32)
        me.uv_layers.active.data.foreach_get("uv", uv)
        uv = uv.reshape(-1, 2) * n
        for t in me.loop_triangles:
            a, b, c = uv[list(t.loops)]
            x0, y0 = np.maximum(np.floor(np.minimum(np.minimum(a, b), c)).astype(int), 0)
            x1, y1 = np.minimum(np.ceil(np.maximum(np.maximum(a, b), c)).astype(int), n)
            if x1 <= x0 or y1 <= y0:
                continue
            px, py = cx[y0:y1, x0:x1], cy[y0:y1, x0:x1]

            def side(u, v):
                return (v[0] - u[0]) * (py - u[1]) - (v[1] - u[1]) * (px - u[0])
            s1, s2, s3 = side(a, b), side(b, c), side(c, a)
            inside = ((s1 >= 0) & (s2 >= 0) & (s3 >= 0)) | ((s1 <= 0) & (s2 <= 0) & (s3 <= 0))
            box, fbox = owner[y0:y1, x0:x1], face[y0:y1, x0:x1]
            hit = inside & (box >= 0) & (box != oi)
            for other in np.unique(box[hit]):
                k = f"{objs[other].name}/{o.name}"
                out[k] = out.get(k, 0) + int((box[hit] == other).sum())
            own = inside & (box == oi) & (fbox != t.polygon_index)
            if own.any():
                out[o.name] = out.get(o.name, 0) + int(own.sum())
            box[inside] = oi
            fbox[inside] = t.polygon_index
    slack = {o.name: len(o.data.polygons) for o in objs}
    return {k: v for k, v in out.items() if v > slack.get(k, 0)}


def save_low(find, objs, set_dir):
    """The unwrapped game meshes, kept so export and renders wear the bake's exact UVs."""
    path = find.out(set_dir, f"{find.name}.blend")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.data.libraries.write(path, {o.data for o in objs.values()}, fake_user=True)


def load_low(find, set_dir, coll):
    path = find.out(set_dir, f"{find.name}.blend")
    with bpy.data.libraries.load(path) as (src, dst):
        dst.meshes = [m for m in src.meshes if m.startswith(find.name + "_")]
    objs = {}
    for p in find.parts:
        me = bpy.data.meshes[f"{find.name}_{p.name}"]
        ob = bpy.data.objects.new(me.name, me)
        coll.objects.link(ob)
        ob.location = p.pivot
        objs[p.name] = ob
        if p.bones:
            skin(find, p, ob, coll)
    return objs


def skin(find, p, ob, coll):
    """A boned part's armature, `<Find>_<Part>_Rig`: a root bone on its pivot holding what no
    bone bends, and each Bone from its `at` pointing along its `axis` (so a pose bone's Y is its
    move), its vertices weighted by `share`. The rig rides on the part (its child at the pivot),
    so the part's own motion carries it; export hangs the part under it instead (stage_export)."""
    arm = bpy.data.armatures.new(f"{ob.name}_Rig")
    rig = bpy.data.objects.new(arm.name, arm)
    coll.objects.link(rig)
    rig.location = p.pivot
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode="EDIT")
    root = arm.edit_bones.new(f"{ob.name}Root")
    root.head, root.tail = (0.0, 0.0, 0.0), (0.0, 0.0, 0.05)
    for b in p.bones:
        eb = arm.edit_bones.new(f"{find.name}_{b.name}")
        eb.head = b.at - p.pivot
        eb.tail = eb.head + b.axis * 0.05
        eb.parent = root
    bpy.ops.object.mode_set(mode="OBJECT")
    held = ob.vertex_groups.new(name=f"{ob.name}Root")  # the edit bone is gone
    groups = [ob.vertex_groups.new(name=f"{find.name}_{b.name}") for b in p.bones]
    for v in ob.data.vertices:
        co = v.co + p.pivot
        ws = [b.share(co) for b in p.bones]
        total = sum(ws)
        if total > 1.0:
            ws = [w / total for w in ws]
        for g, w in zip(groups, ws):
            if w > 1e-4:
                g.add([v.index], w, "REPLACE")
        held.add([v.index], max(0.0, 1.0 - sum(ws)), "REPLACE")
    mod = ob.modifiers.new("bones", "ARMATURE")
    mod.object = rig
    rig.parent = ob
    rig.matrix_parent_inverse = Matrix()
    rig.location = (0.0, 0.0, 0.0)


# --- the bake: detailed mesh onto the game mesh --------------------------------------------

class Rig:
    """The detailed mesh's material: the look's channels, a BSDF for the normal pass, an emitter
    for everything else."""

    def __init__(self, find):
        self.mat = bpy.data.materials.new(f"rig_{find.name}")
        nb = self.nb = NB(self.mat)
        s = find.look(Look(nb, find.seed), find)
        val = lambda v: v if isinstance(v, bpy.types.NodeSocket) else nb.val(float(v))  # noqa
        self.sock = {"col": s.col if isinstance(s.col, bpy.types.NodeSocket) else nb.rgb(s.col),
                     "rough": val(s.rough), "metal": val(s.metal), "glow": val(s.glow),
                     "alpha": val(s.alpha),
                     "ao": nb.ao(0.12, local=False), "cover": nb.val(1.0)}
        self.bsdf = nb.node("ShaderNodeBsdfPrincipled")
        nb.put(self.bsdf.inputs["Base Color"], self.sock["col"])
        nb.put(self.bsdf.inputs["Normal"], nb.bump(val(s.height), s.bump, s.bump_dist))
        self.emit = nb.node("ShaderNodeEmission")
        self.out = nb.node("ShaderNodeOutputMaterial")

    def channel(self, k):
        links = self.nb.links
        if k == "normal":
            links.new(self.bsdf.outputs[0], self.out.inputs["Surface"])
        else:
            links.new(self.sock[k], self.emit.inputs["Color"])
            links.new(self.emit.outputs[0], self.out.inputs["Surface"])


def dilate(a, covered, steps):
    a, cov = a.copy(), covered.copy()
    for _ in range(steps):
        acc, cnt = np.zeros_like(a), np.zeros(cov.shape, dtype=np.float32)
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (1, -1), (-1, 1), (-1, -1)):
            c = np.roll(np.roll(cov, dy, 0), dx, 1)
            acc += np.roll(np.roll(a, dy, 0), dx, 1) * c[..., None]
            cnt += c
        grow = (~cov) & (cnt > 0)
        a[grow] = acc[grow] / cnt[grow][:, None]
        cov |= grow
    return a


def tex(find, set_dir, k):
    return find.out(set_dir, "textures", f"{find.name}_{k}.png")


def stage_textures(find, set_dir):
    reset()
    coll = bpy.context.scene.collection
    hi = build(find, True, coll)
    lo = build(find, False, coll)
    size, dens = unwrap(find, lo)
    save_low(find, lo, set_dir)
    ub.gpu_cycles(48)
    sc = bpy.context.scene
    sc.render.bake.margin = 0
    sc.render.bake.use_selected_to_active = True
    sc.render.bake.cage_extrusion = find.cage
    sc.render.bake.max_ray_distance = REACH * find.cage / CAGE
    rig = Rig(find)
    for o in hi.values():
        o.data.materials.append(rig.mat)
    target = bpy.data.materials.new("target")
    tnb = NB(target)
    img_node = tnb.node("ShaderNodeTexImage")
    tnb.nt.nodes.active = img_node
    for o in lo.values():
        o.data.materials.append(target)
        # the game mesh sits on the detailed one: hide it from every ray but the bake's own
        for v in ("visible_camera", "visible_diffuse", "visible_glossy", "visible_transmission",
                  "visible_volume_scatter", "visible_shadow"):
            setattr(o, v, False)
    res = {}
    chans = (("col", "rough", "metal", "glow", "ao", "normal", "cover")
             + (("alpha",) if find.clear or find.tint else ()))
    for k in chans:
        img = bpy.data.images.new(f"{find.name}_{k}", size, size, alpha=True, float_buffer=True)
        img.colorspace_settings.name = "Non-Color"
        img.generated_color = (0.5, 0.5, 1.0, 1.0) if k == "normal" else (0, 0, 0, 1)
        img_node.image = img
        rig.channel(k)
        sc.cycles.samples = 64 if k == "ao" else 8
        for p in find.parts:
            if find.clear or find.alone:
                # light goes through glass: a solid part's occlusion leaves the clear parts out
                # (the candle in its jar isn't in a cave), a clear part's counts only itself.
                # Every channel, not just "ao": the look's own grime is an occlusion node baked
                # into the colour, and a shade hugging the moon greyed the half it covered.
                # An `alone` part neither shades nor is shaded by the others
                for q in find.parts:
                    h = (((q.name != p.name) if p.clear else q.clear) if find.clear else False)
                    apart = p.alone or q.alone or p.inside or q.inside
                    hi[q.name].hide_render = h or (apart and q.name != p.name)
            bpy.ops.object.select_all(action="DESELECT")
            hi[p.name].select_set(True)
            lo[p.name].select_set(True)
            bpy.context.view_layer.objects.active = lo[p.name]
            bpy.ops.object.bake(type="NORMAL" if k == "normal" else "EMIT", normal_space="TANGENT",
                                margin=0, use_clear=False, use_selected_to_active=True,
                                cage_extrusion=find.cage,
                                max_ray_distance=REACH * find.cage / CAGE)
        res[k] = ub.pixels(img)
    for o in hi.values():
        o.hide_render = False
    covered = res.pop("cover")[..., 0] > 0.5
    for k in res:
        res[k] = dilate(res[k], covered, PAD + 2)
    col = res["col"][..., :3] * (1.0 - AO_IN_COLOUR * (1.0 - res["ao"][..., :1]))
    rough, metal, glow = res["rough"][..., 0], res["metal"][..., 0], res["glow"][..., 0]
    os.makedirs(os.path.dirname(tex(find, set_dir, "x")), exist_ok=True)
    # a clear part's alpha rides in the colour map (what AlphaMode Transparency reads); every
    # other texel is solid. A tinted find's alpha is its mask (AlphaMode TintMask): its texels
    # are lightened by what the Rest tint takes off, exactly, wherever the mask is partly on
    plain = col
    alpha = np.clip(res["alpha"][..., :1], 0, 1) if find.clear or find.tint else None
    if find.tint:
        rest = np.array(tints(find)[0], dtype=np.float32)
        col = col / (1.0 - alpha + alpha * rest)
    rgba = lambda c: c if alpha is None else np.concatenate([c, alpha], axis=2)  # noqa: E731
    ub.write_png(tex(find, set_dir, "Color"), ub.q8(rgba(ub.to_srgb(np.clip(col, 0, 1)))))
    ub.write_png(tex(find, set_dir, "Normal"), ub.q8(res["normal"][..., :3]))
    ub.write_png(tex(find, set_dir, "Roughness"), ub.q8(np.clip(rough, 0, 1)))
    ub.write_png(tex(find, set_dir, "Metalness"), ub.q8(np.clip(metal, 0, 1)))
    if glow.max() > 0.01:
        ub.write_png(tex(find, set_dir, "Emissive"), ub.q8(np.clip(glow, 0, 1)))
    ub.write_png(find.out(set_dir, f"{find.name}_cover.png"), ub.q8(covered.astype(np.float32)))
    # Gold: solid gold that keeps the find's detail: its light and dark (wear, grime, dust) shade
    # the gold, the polish follows its roughness, and whatever lights up stays as it was.
    lum = plain @ np.array([0.2126, 0.7152, 0.0722], dtype=np.float32)
    ref = max(float(np.percentile(lum[covered], 90)), 1e-3)
    shade = np.clip(0.5 + 0.5 * lum / ref, 0.35, 1.05)[..., None]
    # anything that glows at all stays itself (the bulb's glass, the night-light's whole shade),
    # not just its brightest middle, or a dim edge turns half gold in blotches
    lit = np.clip(glow * 20.0, 0, 1)[..., None]
    if alpha is not None and find.clear:
        # and glass stays glass: a gold jar you can't see the candle through isn't a jar
        lit = np.maximum(lit, np.clip((1.0 - alpha) * 20.0, 0, 1))
    gcol = np.array(GOLD, dtype=np.float32) * shade * (1 - lit) + plain * lit
    if not find.clear:
        rgba = lambda c: c  # noqa: E731  (a tinted find's Gold has no mask: a Gold doesn't warm)
    grough = (0.14 + 0.4 * rough) * (1 - lit[..., 0]) + rough * lit[..., 0]
    gmetal = 1.0 - lit[..., 0] * (1 - metal)
    ub.write_png(tex(find, set_dir, "GoldColor"), ub.q8(rgba(ub.to_srgb(np.clip(gcol, 0, 1)))))
    ub.write_png(tex(find, set_dir, "GoldRoughness"), ub.q8(np.clip(grough, 0, 1)))
    ub.write_png(tex(find, set_dir, "GoldMetalness"), ub.q8(np.clip(gmetal, 0, 1)))
    print(f"BAKED {find.name}: {size}x{size}, {dens:.0f} texels a stud, "
          f"{covered.mean():.0%} islands, {sum(tris(o) for o in lo.values())} triangles")


# --- materials for export and previews ----------------------------------------------------

def tints(find):
    """A tinted find's Rest and Warm tints (linear RGB): each its colour over the brighter of
    the two, channel by channel, so both are 1 or less and the masked texels, painted that
    brighter colour, show the base colour under Rest and the warm one under Warm."""
    base, warm = hexc(find.tint["base"]), hexc(find.tint["warm"])
    top = [max(a, b, 1e-4) for a, b in zip(base, warm)]
    return (tuple(a / m for a, m in zip(base, top)), tuple(b / m for b, m in zip(warm, top)))


def material(find, set_dir, preview=False, gold=False, clear=False, inside=False):
    """The baked maps on a Principled BSDF (what Roblox's importer reads). A preview material
    also glows: the emissive map, times the part's `glow` (0 to 1), times the find's light. A
    clear one takes its alpha from the colour map's (Roblox then imports AlphaMode
    Transparency). An inside part's preview shows only its faces' fronts, as Roblox does."""
    inside = inside and preview
    key = (f"{find.name}{'_gold' if gold else ''}{'_pv' if preview else ''}"
           f"{'_clear' if clear else ''}{'_in' if inside else ''}")
    if key in bpy.data.materials:
        return bpy.data.materials[key]
    mat = bpy.data.materials.new(key)
    nb = NB(mat)
    g = "Gold" if gold else ""
    img = lambda k, nc: nb.node("ShaderNodeTexImage", image=ub.load(tex(find, set_dir, k), nc))  # noqa
    col, rough, metal = img(g + "Color", False), img(g + "Roughness", True), img(g + "Metalness", True)
    nrm = img("Normal", True)
    nm = nb.node("ShaderNodeNormalMap")
    nb.put(nm.inputs["Color"], nrm.outputs["Color"])
    bsdf = nb.node("ShaderNodeBsdfPrincipled")
    out = nb.node("ShaderNodeOutputMaterial")
    nb.put(bsdf.inputs["Base Color"], col.outputs["Color"])
    nb.put(bsdf.inputs["Roughness"], rough.outputs["Color"])
    nb.put(bsdf.inputs["Metallic"], metal.outputs["Color"])
    nb.put(bsdf.inputs["Normal"], nm.outputs["Normal"])
    if clear:
        nb.links.new(col.outputs["Alpha"], bsdf.inputs["Alpha"])
    elif find.tint and not gold:
        if preview:
            # what TintMask does in Roblox: the colour times the tint, as far as the mask says,
            # the tint from Rest to Warm by the part's `tint`
            rest, warm = tints(find)
            t = nb.mixc(nb.objattr("tint"), nb.rgb(rest), nb.rgb(warm))
            k = nb.mixc(col.outputs["Alpha"], nb.rgb((1.0, 1.0, 1.0)), t)
            nb.put(bsdf.inputs["Base Color"], nb.mixc(1.0, col.outputs["Color"], k, "MULTIPLY"))
        else:
            # the mask must reach Roblox in the colour map: linked, the importer keeps it
            nb.links.new(col.outputs["Alpha"], bsdf.inputs["Alpha"])
    if preview and os.path.exists(tex(find, set_dir, "Emissive")):
        em = img("Emissive", True)
        tint = find.glow.get("tint", (255, 200, 140))
        on = nb.mul(em.outputs["Color"], nb.objattr("glow"))
        nb.put(bsdf.inputs["Emission Color"],
               nb.mixc(1.0, col.outputs["Color"], nb.rgb(tuple(c / 255 for c in tint)), "MULTIPLY"))
        nb.put(bsdf.inputs["Emission Strength"], nb.mul(on, find.glow.get("preview", 12.0)))
    if inside:
        cull = nb.node("ShaderNodeMixShader")
        nb.links.new(nb.node("ShaderNodeNewGeometry").outputs["Backfacing"], cull.inputs[0])
        nb.links.new(bsdf.outputs[0], cull.inputs[1])
        nb.links.new(nb.node("ShaderNodeBsdfTransparent").outputs[0], cull.inputs[2])
        nb.links.new(cull.outputs[0], out.inputs["Surface"])
    else:
        nb.links.new(bsdf.outputs[0], out.inputs["Surface"])
    return mat


# --- export ---------------------------------------------------------------------------------

def to_roblox(v):
    """Blender's (x, y, z) to Roblox's, through the FBX's axes: x = -x, y = z, z = y."""
    return (-v[0], v[2], v[1])


def extent(v):
    """A size in Roblox's axes: the axes swapped like a point's, never negative."""
    return (abs(v[0]), abs(v[2]), abs(v[1]))


def bounds(obs):
    vs = [ob.matrix_world @ v.co for ob in obs for v in ob.data.vertices]
    lo = Vector([min(v[i] for v in vs) for i in range(3)])
    hi = Vector([max(v[i] for v in vs) for i in range(3)])
    return lo, hi


def wear(find, set_dir, objs, **kw):
    """Each part in the find's material, its clear parts in the clear one."""
    for p in find.parts:
        ob = objs[p.name]
        ob.data.materials.clear()
        ob.data.materials.append(material(find, set_dir, clear=p.clear, inside=p.inside, **kw))
        ob.visible_shadow = not p.inside


def stage_export(find, set_dir):
    reset()
    objs = load_low(find, set_dir, bpy.context.scene.collection)
    wear(find, set_dir, objs)
    bpy.ops.object.select_all(action="DESELECT")
    for p in find.parts:
        ob = objs[p.name]
        ob.select_set(True)
        if p.bones:
            # Roblox's importer wants the skinned mesh under its armature (the bone test's way,
            # docs/STUDIO.md "Bones"): the rig takes the part's place, the part rides it
            rig = ob.children[0]
            rig.parent = None
            rig.matrix_world = Matrix.Translation(p.pivot)
            ob.parent = rig
            ob.matrix_parent_inverse = rig.matrix_world.inverted()
            rig.select_set(True)
    bpy.context.view_layer.objects.active = objs[find.parts[0].name]
    path = find.out(set_dir, f"{find.name}.fbx")
    boned = any(p.bones for p in find.parts)
    bpy.ops.export_scene.fbx(
        filepath=path, use_selection=True,
        object_types={"MESH", "ARMATURE"} if boned else {"MESH"}, use_armature_deform_only=True,
        apply_scale_options="FBX_SCALE_UNITS", axis_forward="Z", axis_up="Y",
        use_mesh_modifiers=True, mesh_smooth_type="OFF", use_tspace=False,
        add_leaf_bones=False, bake_anim=False, path_mode="COPY", embed_textures=True)
    print("FBX", path, {n: tris(o) for n, o in objs.items()})
    return objs


def row(find, objs, size):
    """What the game reads about one find (written into the set's Luau)."""
    lo, hi = bounds(list(objs.values()))
    root = find.parts[0].pivot
    parts = []
    for p in find.parts:
        plo, phi = bounds([objs[p.name]])
        parts.append(dict(name=p.name, parent=p.parent, pivot=to_roblox(p.pivot - root),
                          axis=to_roblox(p.axis) if p.axis else None, clear=p.clear,
                          inside=p.inside, size=extent(phi - plo), tris=tris(objs[p.name])))
    bones = [dict(name=b.name, part=p.name, at=to_roblox(b.at - root), axis=to_roblox(b.axis),
                  hinge=to_roblox(b.hinge) if b.hinge else None)
             for p in find.parts for b in p.bones]
    return dict(size=extent(hi - lo), centre=to_roblox((lo + hi) / 2 - root),
                tris=sum(tris(o) for o in objs.values()), tex=size, parts=parts, bones=bones)


# --- motion -----------------------------------------------------------------------------------

# The travel channels (pose) and what each becomes in Roblox's axes for the Luau: its name there
# and the sign its values take (Blender X is Roblox's -X, Y its Z, Z its Y; a turn about Blender
# X is the same turn the other way about Roblox X).
TRAVEL = ("x", "y", "z", "yaw", "pitch", "roll")
TO_ROBLOX_CH = {"x": ("x", -1.0), "y": ("z", 1.0), "z": ("y", 1.0), "yaw": ("yaw", 1.0),
                "pitch": ("pitch", -1.0), "roll": ("roll", 1.0)}

def tracks(find, action):
    m = find.motions[action]
    return m["duration"], [(part, ch, ease.keys(ks)) for part, ch, ks in m["tracks"]]


def pose(find, objs, values, lights=None):
    """Stand every part where `values` {(part, channel): v} put it: a turn (degrees) or a move
    (studs) about the part's own pivot and axis, a `scale` (times its size) and a `stretch`
    (times as tall along the find's up, 1/sqrt as wide: squash and stretch keeping its volume)
    about its pivot, all carried by its parent's motion."""
    delta = {}
    for p in find.parts:
        D = delta[p.parent] if p.parent else Matrix()
        sc = max(values.get((p.name, "scale"), 1.0), 1e-4)
        st = max(values.get((p.name, "stretch"), 1.0), 1e-4)
        S = Matrix.Diagonal((sc / math.sqrt(st), sc / math.sqrt(st), sc * st, 1.0))
        L = Matrix.Translation(p.pivot) @ S @ Matrix.Translation(-p.pivot)
        if p.axis is not None:
            turn = values.get((p.name, "turn"), 0.0)
            move = values.get((p.name, "move"), 0.0)
            L = (Matrix.Translation(p.pivot) @ Matrix.Rotation(math.radians(turn), 4, p.axis) @ S
                 @ Matrix.Translation(-p.pivot) @ Matrix.Translation(p.axis * move))
        # a part that travels over the floor and leans (the RC car driving off, its chassis on
        # its springs, the tin bird hopping): x, y and z in studs along the find's X, Y and Z,
        # then yaw, pitch and roll in degrees about the find's Z, X and Y through its pivot, all
        # in its parent's frame
        tv = [values.get((p.name, ch), 0.0) for ch in TRAVEL]
        if any(tv):
            L = (Matrix.Translation((tv[0], tv[1], tv[2])) @ Matrix.Translation(p.pivot)
                 @ Matrix.Rotation(math.radians(tv[3]), 4, "Z")
                 @ Matrix.Rotation(math.radians(tv[4]), 4, "X")
                 @ Matrix.Rotation(math.radians(tv[5]), 4, "Y") @ Matrix.Translation(-p.pivot) @ L)
        delta[p.name] = D @ L
        objs[p.name].matrix_world = delta[p.name] @ Matrix.Translation(p.pivot)
        objs[p.name]["glow"] = values.get((p.name, "glow"), objs[p.name].get("glow", 0.0))
        objs[p.name]["tint"] = values.get((p.name, "tint"), objs[p.name].get("tint", 0.0))
        if p.bones:
            rig = objs[p.name].children[0]
            for b in p.bones:
                pb = rig.pose.bones[f"{find.name}_{b.name}"]
                pb.location = (0.0, values.get((b.name, "move"), 0.0), 0.0)
                if b.hinge is not None:
                    pb.rotation_mode = "AXIS_ANGLE"
                    h = pb.bone.matrix_local.to_3x3().inverted() @ b.hinge
                    pb.rotation_axis_angle = (math.radians(values.get((b.name, "turn"), 0.0)), *h)
    for lt, ob in (lights or {}).items():
        spec = find.lights[lt]
        D = delta[spec["part"]]
        at = D @ Vector(spec["at"])
        ob.location = at
        face = (D.to_3x3() @ Vector(spec.get("face", (0, 0, -1)))).normalized()
        ob.rotation_euler = face.to_track_quat("-Z", "Y").to_euler()
        # a light may follow its own part's glow (each firefly's) instead of the find's
        g = objs[spec.get("glow_part") or find.glow.get("part", find.parts[0].name)].get("glow", 0.0)
        ob.data.energy = spec["preview_watts"] * g
        ob.hide_render = g <= 0.001
    bpy.context.view_layer.update()


def values_at(trs, t):
    return {(part, ch): ease.sample(ks, t) for part, ch, ks in trs}


def warmest(find):
    """A tinted find's pose halfway through the time its first tinting motion holds the tint
    at its height ({(part, channel): value}), or None for a find with no tint."""
    for action in find.motions if find.tint else ():
        _, trs = tracks(find, action)
        for _, ch, ks in trs:
            if ch == "tint":
                top = max(k[1] for k in ks)
                at = [k[0] for k in ks if k[1] >= top - 1e-6]
                return values_at(trs, (at[0] + at[-1]) / 2)
    return None


# --- previews ----------------------------------------------------------------------------------

def place(find, objs, M, coll, values=None, lights=True):
    """A posed copy of the find at M (a fresh copy each call; the first call uses `objs`)."""
    for ob in objs.values():
        if ob.name not in coll.objects:
            coll.objects.link(ob)
    lts = {}
    if lights:
        for i, spec in enumerate(find.lights):
            ld = bpy.data.lights.new(f"{find.name}_light{i}", spec.get("preview_kind", "SPOT"))
            # a light that isn't a hot filament (a glow stick's green) gives its own `rgb`
            ld.color = tuple(c / 255 for c in spec.get("rgb") or ease.kelvin(spec["kelvin"]))
            ld.shadow_soft_size = spec.get("preview_size", 0.05)
            # a Roblox light without shadows shines through everything, the find included (the
            # night-light's bulb inside its shade): the preview does the same
            ld.use_shadow = spec.get("shadows", True)
            if ld.type == "SPOT":
                ld.spot_size = math.radians(spec.get("angle", 90))
                ld.spot_blend = spec.get("preview_blend", 0.6)
            lo = bpy.data.objects.new(ld.name, ld)
            coll.objects.link(lo)
            lts[i] = lo
    pose(find, objs, values or {}, lts)
    for ob in list(objs.values()) + list(lts.values()):
        ob.matrix_world = M @ ob.matrix_world
    return lts


def frame_find(find, objs):
    lo, hi = bounds(list(objs.values()))
    return (lo + hi) / 2, (hi - lo)


def studio(coll):
    rig = render.studio_rig()
    for o in rig:
        o.hide_render = False
    return rig


def unit_room(coll):
    """A medium unit (10 x 10 studs, 9 high) seen from its open door: concrete floor, ribbed grey
    walls, a dim warm bulb in the middle, boxes at the back. Its door faces -Y at y = 0."""
    floor = render.simple("u_floor", hexc("#5E5A54"), 0.85)
    wall = render.simple("u_wall", hexc("#77797A"), 0.5, 0.6)
    render.box_obj("u_floor", (-5.0, 0.0, -0.1), (5.0, 10.0, 0.0), floor, coll)
    render.box_obj("u_back", (-5.0, 10.0, 0.0), (5.0, 10.2, 9.0), wall, coll)
    render.box_obj("u_left", (-5.2, 0.0, 0.0), (-5.0, 10.2, 9.0), wall, coll)
    render.box_obj("u_right", (5.0, 0.0, 0.0), (5.2, 10.2, 9.0), wall, coll)
    render.box_obj("u_top", (-5.2, 0.0, 9.0), (5.2, 10.2, 9.2), wall, coll)
    render.box_obj("u_lintel", (-5.2, -0.2, 7.6), (5.2, 0.0, 9.2), wall, coll)
    for c, s, r in (((-3.6, 8.6, 0.0), (2.2, 2.0, 1.7), 6), ((-3.5, 8.7, 1.7), (1.8, 1.6, 1.4), -4),
                    ((3.4, 8.8, 0.0), (2.4, 2.0, 2.0), -3), ((1.2, 9.0, 0.0), (1.6, 1.5, 1.2), 9)):
        render.box_prop(coll, c, s, r)
    bl = bpy.data.lights.new("u_bulb", "POINT")
    bl.energy, bl.color, bl.shadow_soft_size = 650.0, (1.0, 0.78, 0.52), 0.15
    bo = bpy.data.objects.new("u_bulb", bl)
    coll.objects.link(bo)
    bo.location = (0.0, 5.0, 8.2)
    render.world((0.004, 0.005, 0.007), 1.0)


def ffmpeg(*args):
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", *args], check=True)


def shoot(cam, path, res, samples):
    sc = bpy.context.scene
    sc.render.resolution_x, sc.render.resolution_y = res
    sc.cycles.samples = samples
    render.shoot(cam, path)


def stage_renders(find, set_dir, quick=False):
    """The sheets CRAFT.md asks for: lineup with a person, front and back, held, the unit's
    doorway on a phone (off and on), off and on up close, a filmstrip and an MP4 per action,
    and Gold."""
    S = 48 if quick else 128
    name = find.name.lower()
    sheet = lambda k: os.path.join(SHEETS, f"{name}-{k}.png")  # noqa: E731
    os.makedirs(SHEETS, exist_ok=True)
    # each find its own frames folder, so two finds can render at once
    tmp = os.path.join(find.out(set_dir, "frames"), find.name)
    shutil.rmtree(tmp, ignore_errors=True)
    os.makedirs(tmp)

    def scene():
        reset()
        render.setup(S, (1600, 900))
        coll = bpy.context.scene.collection
        objs = load_low(find, set_dir, coll)
        wear(find, set_dir, objs, preview=True)
        return coll, objs

    def lit(vals):
        """The values for it switched on: its glow part lit, and whatever else `lit` says."""
        vals[(find.glow.get("part"), "glow")] = 1.0
        vals.update(find.lit)
        return vals

    rest = {}
    for part, ch, ks in [t for a in find.motions for t in tracks(find, a)[1]]:
        rest.setdefault((part, ch), ks[0][1])
    c, size = None, None

    # 1. the studio: lineup with a person (5.4 studs), front, back, held, Gold
    coll, objs = scene()
    studio(coll)
    place(find, objs, Matrix(), coll, rest, lights=False)
    c, size = frame_find(find, objs)
    h = max(size.z, 0.5)
    before = set(bpy.data.objects)
    render.kept_figure(coll, (-(size.x / 2 + 1.6), 0.6, 0.0), 0.0, 5.4)
    person = set(bpy.data.objects) - before
    # a find taller than about 4.2 studs (a big find on its stand) pulls the camera back to fit
    k = max(1.0, (c.z + size.z / 2) / 4.2)
    cam = render.camera((-1.2, -9.5 * k, 3.2 + (k - 1) * 1.6), (-1.2, 0.0, 2.4 + (k - 1) * 1.6),
                        lens=40)
    shoot(cam, sheet("lineup"), (1600, 900), S)
    for o in person:
        o.hide_render = True
    d = max(size.x, size.y, size.z)
    cam = render.camera(c + Vector((-0.9, -1.9, 0.55)) * d * 1.25, c, lens=45)
    shoot(cam, sheet("front"), (1600, 900), S)
    cam = render.camera(c + Vector((1.1, 1.7, 0.75)) * d * 1.25, c, lens=45)
    shoot(cam, sheet("back"), (1600, 900), S)
    # held: first person on a phone (844 x 390, Roblox's 70 degree view up and down), the find
    # in your hands where the torch is held (Torch.Hold: right, down, ahead of your eye), turned
    # three quarters to you, lifted to chest height so the floor is far below as it is in play;
    # a bigger find is held further out, at the end of your arms
    eye = Vector((0.0, 0.0, 4.6))
    fwd = Vector((0.0, math.cos(math.radians(10)), -math.sin(math.radians(10))))
    right, up = Vector((1.0, 0.0, 0.0)), fwd.cross(Vector((1.0, 0.0, 0.0))) * -1.0
    reach = max(HOLD[2], 0.6 + 0.9 * d)
    at = eye + right * HOLD[0] + up * HOLD[1] + fwd * reach
    M = (Matrix.Translation(at) @ Matrix.Rotation(math.radians(HOLD_TURN), 4, "Z")
         @ Matrix.Translation(-c))
    for ob in objs.values():
        ob.matrix_world = M @ ob.matrix_world
    cam = render.camera(eye, eye + fwd, lens=12)
    shoot(cam, sheet("held"), (844, 390), S)
    # a find whose colour changes in your hands (the colour-change goo ball) is held again in the
    # middle of its warmest moment, posed as its press stands then: what you see squeezing it
    warm = warmest(find)
    if warm:
        for vals in ({**rest, **warm}, rest):
            pose(find, objs, vals)
            for ob in objs.values():
                ob.matrix_world = M @ ob.matrix_world
            if vals is not rest:
                shoot(cam, sheet("held-warm"), (844, 390), S)
    for ob in objs.values():
        ob.matrix_world = M.inverted() @ ob.matrix_world
    for p in find.parts:
        objs[p.name].data.materials[0] = material(find, set_dir, preview=True, gold=True,
                                                  clear=p.clear, inside=p.inside)
    cam = render.camera(c + Vector((-0.9, -1.9, 0.55)) * d * 1.25, c, lens=45)
    shoot(cam, sheet("gold"), (1600, 900), S)

    # 2. off and on up close, in the dark, on a floor that shows the pool
    for state in ("off", "on"):
        coll, objs = scene()
        render.world((0.01, 0.011, 0.014), 1.0)
        fl = render.simple("floor", hexc("#4A4743"), 0.8)
        render.box_obj("floor", (-20, -20, -0.1), (20, 20, 0.0), fl, coll)
        vals = lit(dict(rest)) if state == "on" else dict(rest)
        place(find, objs, Matrix(), coll, vals)
        key = bpy.data.lights.new("moon", "AREA")
        key.energy, key.size, key.color = 320.0, 6.0, (0.75, 0.82, 1.0)
        ko = bpy.data.objects.new("moon", key)
        coll.objects.link(ko)
        ko.location = (6, -4, 8)
        ko.rotation_euler = (Vector((0, 0, 0)) - ko.location).to_track_quat("-Z", "Y").to_euler()
        cam = render.camera(c + Vector((-1.0, -2.6, 0.25)) * d * 0.8, c - Vector((0, 0, h * 0.2)),
                            lens=35)
        shoot(cam, os.path.join(tmp, f"close-{state}.png"), (960, 900), S)
    ffmpeg("-i", os.path.join(tmp, "close-off.png"), "-i", os.path.join(tmp, "close-on.png"),
           "-filter_complex", "hstack", sheet("offon"))

    # 3. the unit's doorway on a phone: deeper than the bulb, facing the door (D-036)
    for state in ("off", "on"):
        coll, objs = scene()
        unit_room(coll)
        vals = lit(dict(rest)) if state == "on" else dict(rest)
        place(find, objs, Matrix.Translation((0.8, 7.0, 0.0)) @ Matrix.Rotation(math.radians(-15), 4, "Z"),
              coll, vals)
        cam = render.camera((0.0, -1.0, 4.6), (0.3, 7.0, 0.9), lens=12)
        shoot(cam, os.path.join(tmp, f"unit-{state}.png"), (844, 390), S)
    ffmpeg("-i", os.path.join(tmp, "unit-off.png"), "-i", os.path.join(tmp, "unit-on.png"),
           "-filter_complex", "vstack", sheet("unit"))

    # 4. every action: 24 frames a second into an MP4, ten of them into a filmstrip
    # (ACTIONS=Light,Burn renders only those; ACTIONS= none, for redoing stills alone)
    only = os.environ.get("ACTIONS")
    for action in find.motions:
        if only is not None and action not in only.split(","):
            continue
        dur, trs = tracks(find, action)
        coll, objs = scene()
        render.world((0.01, 0.011, 0.014), 1.0)
        fl = render.simple("floor", hexc("#4A4743"), 0.8)
        render.box_obj("floor", (-20, -20, -0.1), (20, 20, 0.0), fl, coll)
        follow = find.motions[action].get("follow")
        if follow:
            # a find that travels (the RC car): the slab's saw-cut joints every 2 studs show it
            # moving while the camera rides along
            cut = render.simple("joint", hexc("#2E2C2A"), 0.9)
            for i in range(-10, 11):
                render.box_obj(f"jx{i}", (i * 2.0 - 0.012, -20, 0.0), (i * 2.0 + 0.012, 20, 0.0008),
                               cut, coll)
                render.box_obj(f"jy{i}", (-20, i * 2.0 - 0.012, 0.0), (20, i * 2.0 + 0.012, 0.0008),
                               cut, coll)
        amb = bpy.data.lights.new("amb", "AREA")
        amb.energy, amb.size = 520.0, 6.0
        ao_ = bpy.data.objects.new("amb", amb)
        coll.objects.link(ao_)
        ao_.location = (-5, -6, 7)
        ao_.rotation_euler = (Vector((0, 0, 0)) - ao_.location).to_track_quat("-Z", "Y").to_euler()
        # parts the action doesn't move stay as they're found (the tea light's flame, unlit)
        lts = place(find, objs, Matrix(), coll, {**rest, **values_at(trs, 0.0)})
        # the camera looks at the focus part's pivot, or a point (find frame) for a small find
        # whose action should show whole; `distance` scales how far back it stands
        focus = find.motions[action].get("focus", find.parts[-1].name)
        fc = Vector(focus) if isinstance(focus, tuple) else objs[focus].matrix_world.translation
        if follow and isinstance(focus, tuple):
            # a point beside a travelling part rides with it from where it starts (the RC car
            # rolling in to stop where it was found)
            fc = fc + objs[follow].matrix_world.translation - find.parts[0].pivot
        back = find.motions[action].get("distance", 0.6)
        # aimed a little under the focus part, in proportion (the lamp: 0.2 studs; a night-light
        # would otherwise look at the floor under it)
        # a motion may say where the camera stands (`view`, times d and `distance`) and how far
        # under the focus it aims (`drop`, times d): the lamp's key, seen from under its shade
        view = Vector(find.motions[action].get("view", (-1.1, -2.0, 0.15)))
        drop = find.motions[action].get("drop", 0.14)
        cam = render.camera(fc + view * d * back, fc - Vector((0, 0, drop * d)), lens=40)
        if "view" in find.motions[action]:
            # a camera moved round the find takes the stage light with it, a little to its left
            # and above, so the side it films is lit (the tin bird's key side was in shadow)
            hz = Vector((view.x, view.y, 0.0))
            hz = (Matrix.Rotation(math.radians(-30.0), 3, "Z") @ hz.normalized()) if hz.length > 1e-6 else Vector((0, -1, 0))
            ground = Vector((fc.x, fc.y, 0.0))
            ao_.location = ground + hz * 7.8 + Vector((0.0, 0.0, 7.0))
            ao_.rotation_euler = (ground - ao_.location).to_track_quat("-Z", "Y").to_euler()
        # a long slow loop (the blob lamp's Flow) may preview at fewer frames a second (`fps`)
        rate = find.motions[action].get("fps", 24)
        n = int(math.ceil(dur * rate)) + (6 if rate == 24 else 1)
        frames = []
        # `follow`: the camera keeps its place relative to that part as it travels (not its turn)
        ride = objs[follow].matrix_world.translation.copy() if follow else None
        cam_at = cam.location.copy()
        # the stage light rides along too, so a find that travels a long way (the mouse's run, the
        # bird's hops) stays lit in every frame instead of running off into the dark
        amb_at = ao_.location.copy()
        for i in range(n):
            pose(find, objs, {**rest, **values_at(trs, i / rate)}, lts)
            if follow:
                moved = objs[follow].matrix_world.translation - ride
                cam.location = cam_at + moved
                ao_.location = amb_at + Vector((moved.x, moved.y, 0.0))
                bpy.context.view_layer.update()
            f = os.path.join(tmp, f"{action}-{i:03d}.png")
            shoot(cam, f, (480, 360), 24 if quick else 48)
            frames.append(f)
        ffmpeg("-framerate", str(rate), "-i", os.path.join(tmp, f"{action}-%03d.png"),
               "-c:v", "libx264", "-pix_fmt", "yuv420p", "-vf", "scale=480:360",
               find.out(set_dir, f"{name}-{action.lower()}.mp4"))
        step = max(1, (n - 1) // 9)
        pick = [frames[min(i * step, n - 1)] for i in range(10)]
        args = []
        for f in pick:
            args += ["-i", f]
        lay = "|".join(f"{(i % 5) * 480}_{(i // 5) * 360}" for i in range(10))
        ffmpeg(*args, "-filter_complex", f"xstack=inputs=10:layout={lay}",
               sheet(f"{action.lower()}"))
    shutil.rmtree(tmp, ignore_errors=True)


# --- the generated Luau -----------------------------------------------------------------------

def _v3(v):
    return f"Vector3.new({v[0]:.3f}, {v[1]:.3f}, {v[2]:.3f})"


def write_luau(set_name, finds, rows, path):
    L = ["--!strict",
         f"-- Generated by the finds kit (art/finds/kit) from art/finds/{set_name.lower()}/build.py.",
         "-- Don't edit: change the build and rerun scripts/art.sh set "
         f"{set_name.lower()}. Studs, Roblox axes,",
         "-- relative to the find's pivot. What each field means: src/shared/Finds/Art.luau.",
         "-- Nothing reads this to deal a find until the set's templates are in the place.",
         "",
         "local Art = require(script.Parent.Parent.Art)",
         "",
         "local Set: { [string]: Art.Find } = {"]
    for f in finds:
        r = rows[f.name]
        L.append(f"\t{f.name} = {{")
        L.append(f"\t\tSize = {_v3(r['size'])},")
        L.append(f"\t\tCentre = {_v3(r['centre'])},")
        L.append(f"\t\tTriangles = {r['tris']},")
        L.append(f"\t\tTexture = {r['tex']},")
        L.append("\t\tParts = {")
        for p in r["parts"]:
            ax = f"Axis = {_v3(p['axis'])}, " if p["axis"] else ""
            par = f"Parent = \"{f.name}_{p['parent']}\", " if p["parent"] else ""
            ax += "Clear = true, " if p["clear"] else ""
            ax += "Inside = true, " if p["inside"] else ""
            L.append(f"\t\t\t{{ Name = \"{f.name}_{p['name']}\", {par}Pivot = {_v3(p['pivot'])}, {ax}"
                     f"Size = {_v3(p['size'])}, Triangles = {p['tris']} }},")
        L.append("\t\t},")
        if r["bones"]:
            L.append("\t\tBones = {")
            for b in r["bones"]:
                L.append(f"\t\t\t{{ Name = \"{f.name}_{b['name']}\", Part = \"{f.name}_{b['part']}\", "
                         f"At = {_v3(b['at'])}, Axis = {_v3(b['axis'])}"
                         + (f", Hinge = {_v3(b['hinge'])}" if b["hinge"] else "") + " },")
            L.append("\t\t},")
        g = f.glow
        if g:
            t = g.get("tint", (255, 200, 140))
            L.append(f"\t\tGlow = {{ Part = \"{f.name}_{g['part']}\", Strength = {g['strength']}, "
                     f"Tint = Color3.fromRGB({t[0]}, {t[1]}, {t[2]}) }},")
        if f.tint:
            c3 = lambda c: "Color3.new({:.4f}, {:.4f}, {:.4f})".format(  # noqa: E731
                *(float(v) for v in ub.to_srgb(np.array(c))))
            rest, warm = tints(f)
            L.append(f"\t\tTint = {{ Part = \"{f.name}_{f.tint['part']}\", Rest = {c3(rest)}, "
                     f"Warm = {c3(warm)} }},")
        L.append("\t\tLights = {")
        root = f.parts[0].pivot
        for lt in f.lights:
            col = lt.get("rgb") or ease.kelvin(lt["kelvin"])
            ang = f"Angle = {lt['angle']}, " if lt["kind"] == "Spot" else ""
            L.append(f"\t\t\t{{ Kind = \"{lt['kind']}\", Part = \"{f.name}_{lt['part']}\", "
                     f"At = {_v3(to_roblox(Vector(lt['at']) - root))}, "
                     f"Face = {_v3(to_roblox(Vector(lt.get('face', (0, 0, -1)))))}, "
                     f"Color = Color3.fromRGB({col[0]}, {col[1]}, {col[2]}), "
                     f"Brightness = {lt['brightness']}, Range = {lt['range']}, {ang}"
                     f"Shadows = {'true' if lt.get('shadows') else 'false'} }},")
        L.append("\t\t},")
        L.append("\t\tMotions = {")
        for action, m in f.motions.items():
            L.append(f"\t\t\t{action} = {{ Duration = {m['duration']}, Tracks = {{")
            for part, ch, ks in m["tracks"]:
                ch, sign = TO_ROBLOX_CH.get(ch, (ch, 1.0))
                keys = ", ".join(f"{{ {t:g}, {sign * v + 0.0:g}, \"{st}\", \"{d}\" }}"
                                 for t, v, st, d in ease.keys(ks))
                L.append(f"\t\t\t\t{{ Part = \"{f.name}_{part}\", Channel = \"{ch}\", Keys = {{ {keys} }} }},")
            L.append("\t\t\t} },")
        L.append("\t\t},")
        dv = f.drive
        if dv:
            L.append("\t\tDrive = {")
            L.append(f"\t\t\tBody = \"{f.name}_{dv['body']}\",")
            L.append(f"\t\t\tSprung = \"{f.name}_{dv['sprung']}\",")
            L.append("\t\t\tWheels = {")
            for part, radius, steer in dv["wheels"]:
                st = f", Steer = \"{f.name}_{steer}\"" if steer else ""
                L.append(f"\t\t\t\t{{ Part = \"{f.name}_{part}\", Radius = {radius:.4f}{st} }},")
            L.append("\t\t\t},")
            for key in ("Wheelbase", "Track", "SteerLock", "Travel", "TopSpeed", "Accel", "Brake",
                        "Roll", "Pitch"):
                L.append(f"\t\t\t{key} = {dv[key]:g},")
            L.append("\t\t},")
        L.append("\t},")
    L += ["}", "", "return Set", ""]
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as fh:
        fh.write("\n".join(L))
    print("SPEC", path)


# --- running a set -----------------------------------------------------------------------------

def main(set_name, set_dir, finds):
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--stage", choices=["textures", "export", "renders", "quick"], required=True)
    ap.add_argument("--find", default="")
    a = ap.parse_args(argv)
    chosen = [f for f in finds if not a.find or f.name == a.find]
    assert chosen, f"no find {a.find} in {set_name}"
    if a.stage == "textures":
        for f in chosen:
            stage_textures(f, set_dir)
    elif a.stage == "export":
        rows = {}
        for f in finds:  # the Luau lists the whole set, so every find is exported
            if not os.path.exists(f.out(set_dir, f"{f.name}.blend")):
                print(f"skip {f.name}: no bake yet")
                continue
            objs = stage_export(f, set_dir)
            size = ub.load(tex(f, set_dir, "Color"), False).size[0]
            rows[f.name] = row(f, objs, size)
        built = [f for f in finds if f.name in rows]
        write_luau(set_name, built, rows,
                   os.path.join(ROOT, "src", "shared", "Finds", "Sets", f"{set_name}.luau"))
    else:
        for f in chosen:
            stage_renders(f, set_dir, quick=a.stage == "quick")
