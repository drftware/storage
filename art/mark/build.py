"""Build the faint mark, in Blender, headless (art/mark/README.md).

    blender -b --factory-startup -P art/mark/build.py -- --stage textures|export|renders

Stages:
    textures  out/textures/FaintMark_Color.png (the chalk, its alpha the strokes) and
              FaintMark_Roughness.png, drawn straight from spec.py with numpy: the mark is flat,
              so there is nothing to bake
    export    out/FaintMark.fbx: one plane, its colour map's alpha wired into the BSDF's, so it
              imports in AlphaMode Transparency (docs/STUDIO.md "SurfaceAppearance")
    renders   the look sheet, art/sheets/mark.png: the mark on a strip of grey steel, flat in a
              studio light, then from three steps in a torch's beam

No Specs module: the game reads only the part itself (FloorBuilder places it, FaintMarkView fades it).
"""

import argparse
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
UNIT = os.path.join(HERE, "..", "unit")
sys.path.insert(0, UNIT)
sys.path.insert(0, HERE)  # first: this folder's spec.py

import bpy  # noqa: E402
import numpy as np  # noqa: E402
from mathutils import Vector  # noqa: E402

import bake  # noqa: E402
import geo  # noqa: E402
import render  # noqa: E402
import spec as K  # noqa: E402
from nodes import NB  # noqa: E402

OUT = os.path.join(HERE, "out")
TEX = os.path.join(OUT, "textures")
SHEETS = os.path.join(K.ROOT, "art", "sheets")
FBX = os.path.join(OUT, f"{K.SET}.fbx")


def tex_path(kind):
    return os.path.join(TEX, f"{K.SET}_{kind}.png")


# --- textures --------------------------------------------------------------------------------

def value_noise(n, cells, rng):
    """n x n smooth noise in 0..1, `cells` lattice cells across (bilinear, smoothstepped)."""
    grid = rng.random((cells + 1, cells + 1))
    t = np.linspace(0, cells, n, endpoint=False)
    i = t.astype(int)
    f = t - i
    f = f * f * (3 - 2 * f)
    a = grid[i][:, i]
    b = grid[i][:, i + 1]
    c = grid[i + 1][:, i]
    d = grid[i + 1][:, i + 1]
    fx, fy = f[None, :], f[:, None]
    return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy


def smoothstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3 - 2 * t)


def stamp(cover, cx, cy, r, weight):
    """A soft disk of radius r (texels) at (cx, cy), kept as the max of what's there."""
    n = cover.shape[0]
    x0, x1 = max(0, int(cx - r - 2)), min(n, int(cx + r + 3))
    y0, y1 = max(0, int(cy - r - 2)), min(n, int(cy + r + 3))
    if x0 >= x1 or y0 >= y1:
        return
    ys, xs = np.mgrid[y0:y1, x0:x1]
    d = np.hypot(xs + 0.5 - cx, ys + 0.5 - cy)
    disk = smoothstep(r + 1.2, r - 1.2, d) * weight
    cover[y0:y1, x0:x1] = np.maximum(cover[y0:y1, x0:x1], disk)


def stage_textures():
    rng = np.random.default_rng(K.SEED)
    n = K.TEX
    cover = np.zeros((n, n))
    # the ring: one hasty stroke round and on past its start, wobbling, dragging thin at its end
    steps = 1400
    wob = value_noise(64, 6, rng)[0]  # a row of smooth noise for the hand's wander
    press = value_noise(64, 9, rng)[1]  # and for how hard the chalk pressed along the stroke
    idx = np.arange(len(wob))
    tilt = math.radians(K.RING_TILT)
    for k in range(steps):
        t = k / (steps - 1)
        a = math.radians(K.RING_START) + t * K.RING_TURNS * 2 * math.pi
        along = t * (len(wob) - 1)
        r = K.RING_R * (1 + K.RING_DRIFT * (0.5 - t))
        r += K.RING_WOBBLE * (0.6 * (np.interp(along, idx, wob) * 2 - 1)
                              + 0.4 * math.sin(2 * a + 0.7))
        ex, ey = r * K.RING_SQUASH * math.cos(a), r * math.sin(a)
        x = 0.5 + ex * math.cos(tilt) - ey * math.sin(tilt)
        y = 0.5 - (ex * math.sin(tilt) + ey * math.cos(tilt))  # rows run down the image
        swell = 1 + K.STROKE_VARY * (np.interp(along, idx, press) * 2 - 1)
        width = K.STROKE * swell * (1 - (1 - K.STROKE_END) * smoothstep(0.6, 1.0, np.array(t)).item())
        width *= min(1.0, 0.5 + t * 14)  # the chalk lands, then bites
        weight = 0.75 + 0.25 * np.interp(along, idx, press)
        stamp(cover, x * n, y * n, width * n, weight)
    # the dot: jabbed twice, a small smudge
    for _ in range(18):
        ox, oy = rng.normal(0, 0.01, 2)
        stamp(cover, (0.5 + K.DOT[0] + ox) * n, (0.5 - K.DOT[1] + oy) * n,
              K.DOT_R * n * rng.uniform(0.5, 0.85), rng.uniform(0.8, 1.0))
    # the steel's grain: chalk catches its high points only, in fine specks and in streaks that
    # run along the stroke (round the ring), the way a stick of chalk drags
    ys, xs = np.mgrid[0:n, 0:n]
    u, v = (xs + 0.5) / n - 0.5, 0.5 - (ys + 0.5) / n
    theta = (np.arctan2(v, u) / (2 * math.pi)) % 1.0
    rho = np.hypot(u, v)
    rows, cols = 200, 36  # cells across the radius (1.3 texels each) and round the ring
    streak_grid = rng.random((rows + 1, cols))
    sa, sr = theta * cols, np.clip(rho * n / 1.3, 0, rows - 0.001)
    i0, j0 = sr.astype(int), sa.astype(int) % cols
    fr, fa = sr - i0, sa - np.floor(sa)
    fr, fa = fr * fr * (3 - 2 * fr), fa * fa * (3 - 2 * fa)
    j1 = (j0 + 1) % cols
    streak = ((streak_grid[i0, j0] * (1 - fa) + streak_grid[i0, j1] * fa) * (1 - fr)
              + (streak_grid[i0 + 1, j0] * (1 - fa) + streak_grid[i0 + 1, j1] * fa) * fr)
    fine = value_noise(n, n // 3, rng)
    caught = smoothstep(1 - K.GRAIN - 0.14, 1 - K.GRAIN + 0.14, 0.45 * fine + 0.55 * streak)
    alpha = np.clip(cover * (0.25 + 0.75 * caught), 0, 1)
    # a little colour through the dust: thin chalk shows the steel's grey through it
    shade = 0.82 + 0.18 * caught
    rgb = np.stack([np.full((n, n), c) for c in K.CHALK], axis=-1) * shade[..., None]
    os.makedirs(TEX, exist_ok=True)
    rgba = np.concatenate([bake.q8(rgb), bake.q8(alpha)[..., None]], axis=-1)
    # the alpha's edge texels carry the chalk's colour, so the mipmaps never fringe dark
    bake.write_png(tex_path("Color"), rgba)
    bake.write_png(tex_path("Roughness"), np.full((16, 16), bake.q8(np.array(K.ROUGHNESS)).item(),
                                                  dtype=np.uint8))
    print("BAKED", K.SET, f"{(alpha > 0.1).mean():.1%} of the texture is chalk")


# --- export -----------------------------------------------------------------------------------

def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def material():
    mat = bpy.data.materials.new(K.SET)
    nb = NB(mat)
    col = nb.node("ShaderNodeTexImage", image=bake.load(tex_path("Color"), False))
    rough = nb.node("ShaderNodeTexImage", image=bake.load(tex_path("Roughness"), True))
    bsdf = nb.node("ShaderNodeBsdfPrincipled")
    out = nb.node("ShaderNodeOutputMaterial")
    nb.put(bsdf.inputs["Base Color"], col.outputs["Color"])
    nb.put(bsdf.inputs["Alpha"], col.outputs["Alpha"])
    nb.put(bsdf.inputs["Roughness"], rough.outputs["Color"])
    bsdf.inputs["Metallic"].default_value = 0.0
    nb.links.new(bsdf.outputs[0], out.inputs["Surface"])
    return mat


def plane():
    """The mark's plane in XZ, its drawn face toward -Y, UVs upright as you face it."""
    h = K.SIDE / 2
    m = geo.Mesh(K.SET)
    geo.add_faces(m, [(-h, 0, -h), (h, 0, -h), (h, 0, h), (-h, 0, h)], [[0, 1, 2, 3]],
                  lambda vs, n: [((v.x + h) / K.SIDE, (v.z + h) / K.SIDE) for v in vs])
    ob = m.build(bpy.context.scene.collection, sharp_angle=None)
    ob.data.materials.append(material())
    return ob


def stage_export():
    reset()
    ob = plane()
    os.makedirs(OUT, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.export_scene.fbx(
        filepath=FBX, use_selection=True, object_types={"MESH"},
        apply_scale_options="FBX_SCALE_UNITS", axis_forward="Z", axis_up="Y",
        use_mesh_modifiers=True, mesh_smooth_type="OFF", use_tspace=False,
        add_leaf_bones=False, bake_anim=False, path_mode="COPY", embed_textures=True)
    n = ob.data.polygons[0].normal
    print("FBX", FBX, {K.SET: len(ob.data.polygons) * 2}, "face normal", tuple(round(c, 3) for c in n))


# --- renders ----------------------------------------------------------------------------------

def stage_renders():
    reset()
    render.setup(64, (900, 450))
    ob = plane()
    ob.location = (0, -0.06, 4.4)
    steel = render.simple("steel", (0.32, 0.33, 0.34), 0.55, 0.6)
    render.box_obj("jamb", Vector((-0.225, -0.05, 0)), Vector((0.225, 0.4, 8.45)), steel,
                   bpy.context.scene.collection)
    facade = render.simple("facade", (0.18, 0.2, 0.22), 0.7, 0.3)
    render.box_obj("facade", Vector((0.225, 0, 0)), Vector((2.0, 0.25, 10)), facade,
                   bpy.context.scene.collection)
    render.box_obj("facade2", Vector((-2.0, 0, 0)), Vector((-0.225, 0.25, 10)), facade,
                   bpy.context.scene.collection)
    sc = bpy.context.scene
    path = os.path.join(SHEETS, "mark.png")
    # left: the mark flat on, a soft light; right: three steps off in a torch's beam, the hall dark
    shots = []
    for name, loc, light in (("flat", (0.0, -1.3, 4.4), "studio"),
                             ("beam", (-1.6, -7.2, 4.8), "torch")):
        cam = render.camera(loc, (0, 0, 4.4), lens=50.0 if name == "flat" else 32.0, name=name)
        render.world((0.01, 0.012, 0.016), 1.0)
        if light == "studio":
            ld = bpy.data.lights.new("soft", "AREA")
            ld.size, ld.energy = 3.0, 60.0
            lo = bpy.data.objects.new("soft", ld)
            lo.location = (0.6, -2.5, 5.2)
            lo.rotation_euler = (Vector((0, 0, 4.4)) - lo.location).to_track_quat("-Z", "Y").to_euler()
            sc.collection.objects.link(lo)
            render.flashlight(cam, False, (0, 0, 4.4))
        else:
            bpy.data.objects["soft"].hide_render = True
            render.flashlight(cam, True, (0, 0, 4.4))
        sc.render.resolution_x, sc.render.resolution_y = (450, 450)
        out = os.path.join(OUT, f"sheet-{name}.png")
        render.shoot(cam, out, exposure=0.0)
        shots.append(out)
    # side by side
    imgs = [bake.pixels(bpy.data.images.load(p)) for p in shots]
    both = np.concatenate(imgs, axis=1)
    os.makedirs(SHEETS, exist_ok=True)
    bake.write_png(path, bake.q8(both[..., :3]))  # the renders' bytes, already in sRGB
    print("RENDERED", path)


STAGES = {"textures": stage_textures, "export": stage_export, "renders": stage_renders}

if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--stage", choices=list(STAGES), required=True)
    STAGES[ap.parse_args(argv).stage]()
    print("DONE")
