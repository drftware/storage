"""Bake the procedural recipes into Roblox SurfaceAppearance maps, and load them back.

Five texture sets, shared by every unit size:
    DoorKit    1024x1024  atlas: slats, bottom bar, latch, padlock, drum, head plates, plate
    TrimSheet  1024x1024  eight strips that tile along U (trim, diamond, channel, pipe, ...)
    Partition   512x1024  R-panel walls: tiles every 4 studs across, full 10-stud height
    Facade      512x1024  corridor panels, the same way; paint is MeshPart.Color (Overlay)
    Concrete   1024x1024  floor, tiles every 8 studs both ways

Each set writes <Set>_Color.png (RGBA where the set takes a tint, else RGB), _Normal.png
(OpenGL, tangent space), _Roughness.png and _Metalness.png (8-bit grey).
"""

import math
import os
import struct
import zlib

import bmesh
import bpy
import numpy as np

import geo
import materials as M
import parts
from nodes import NB

SIZES = {"DoorKit": (1024, 1024), "TrimSheet": (1024, 1024), "Partition": (512, 1024),
         "Facade": (512, 1024), "Concrete": (1024, 1024)}
TINTED = {"DoorKit", "Facade"}  # ColorMap alpha = overlay (0 shows MeshPart.Color)


# --- png --------------------------------------------------------------------------------

def write_png(path, arr):
    """arr: uint8 HxW (grey), HxWx3 or HxWx4, top row first."""
    arr = np.ascontiguousarray(arr)
    h, w = arr.shape[:2]
    ch = 1 if arr.ndim == 2 else arr.shape[2]
    ctype = {1: 0, 3: 2, 4: 6}[ch]
    raw = b"".join(b"\x00" + arr[y].tobytes() for y in range(h))

    def chunk(t, d):
        c = struct.pack(">I", len(d)) + t + d
        return c + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, ctype, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(png)


def to_srgb(x):
    x = np.clip(x, 0.0, 1.0)
    return np.where(x <= 0.0031308, x * 12.92, 1.055 * np.power(x, 1 / 2.4) - 0.055)


def q8(x):
    return (np.clip(x, 0.0, 1.0) * 255.0 + 0.5).astype(np.uint8)


def pixels(img):
    w, h = img.size
    a = np.empty(w * h * 4, dtype=np.float32)
    img.pixels.foreach_get(a)
    return a.reshape(h, w, 4)[::-1]  # Blender stores bottom row first


# --- atlas --------------------------------------------------------------------------------

def unwrap_atlas(objs, rect):
    """Smart-project every face flagged `unwrap` across objs, packed together into rect."""
    objs = [o for o in objs if any(v.value for v in o.data.attributes["unwrap"].data)]
    if not objs:
        return
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.mode_set(mode="EDIT")
    for o in objs:
        bm = bmesh.from_edit_mesh(o.data)
        lay = bm.faces.layers.int.get("unwrap")
        for f in bm.faces:
            f.select_set(bool(f[lay]))
        bmesh.update_edit_mesh(o.data)
    bpy.ops.uv.smart_project(angle_limit=math.radians(52), island_margin=0.006,
                             area_weight=0.0, correct_aspect=True, scale_to_bounds=False)
    x0, y0, x1, y1 = rect
    for o in objs:
        bm = bmesh.from_edit_mesh(o.data)
        lay = bm.faces.layers.int.get("unwrap")
        uvl = bm.loops.layers.uv.active
        for f in bm.faces:
            if f[lay]:
                for lp in f.loops:
                    u, v = lp[uvl].uv
                    lp[uvl].uv = (x0 + u * (x1 - x0), y0 + v * (y1 - y0))
        bmesh.update_edit_mesh(o.data)
    bpy.ops.object.mode_set(mode="OBJECT")


# --- bake rig ------------------------------------------------------------------------------

class Rig:
    """A bake material: recipe channels, a BSDF for the normal pass, an emitter for the rest."""

    def __init__(self, name, recipe):
        self.mat = bpy.data.materials.new(name)
        nb = NB(self.mat)
        self.nb = nb
        ch = recipe(nb)
        self.sock = {}
        for k in ("col", "ova", "rough", "metal"):
            v = getattr(ch, k)
            self.sock[k] = v if isinstance(v, bpy.types.NodeSocket) else nb.val(float(v))
        self.bsdf = nb.node("ShaderNodeBsdfPrincipled")
        nb.put(self.bsdf.inputs["Base Color"], self.sock["col"])
        nb.put(self.bsdf.inputs["Roughness"], self.sock["rough"])
        nb.put(self.bsdf.inputs["Metallic"], self.sock["metal"])
        h = ch.height if isinstance(ch.height, bpy.types.NodeSocket) else nb.val(float(ch.height))
        nb.put(self.bsdf.inputs["Normal"], nb.bump(h, ch.bump_strength, ch.bump_dist))
        self.emit = nb.node("ShaderNodeEmission")
        self.out = nb.node("ShaderNodeOutputMaterial")
        self.img = nb.node("ShaderNodeTexImage")
        nb.nt.nodes.active = self.img

    def channel(self, k):
        links = self.nb.links
        if k == "normal":
            links.new(self.bsdf.outputs[0], self.out.inputs["Surface"])
        else:
            links.new(self.sock[k], self.emit.inputs["Color"])
            links.new(self.emit.outputs[0], self.out.inputs["Surface"])

    def target(self, img):
        self.img.image = img
        self.nb.nt.nodes.active = self.img


def gpu_cycles(samples):
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    prefs = bpy.context.preferences.addons["cycles"].preferences
    prefs.compute_device_type = "METAL"
    prefs.get_devices()
    for d in prefs.devices:
        d.use = d.type == "METAL"
    sc.cycles.device = "GPU"
    sc.cycles.samples = samples
    sc.cycles.use_denoising = False
    sc.render.bake.margin = 8
    sc.render.bake.margin_type = "EXTEND"
    sc.render.bake.use_clear = False


def bake_set(set_name, items, out_dir, samples=16):
    """items: [(object, Rig)]. Writes the four PNGs. Returns their paths."""
    w, h = SIZES[set_name]
    gpu_cycles(samples)
    for ob, rig in items:
        ob.data.materials.clear()
        ob.data.materials.append(rig.mat)
    bpy.ops.object.select_all(action="DESELECT")
    for ob, _ in items:
        ob.hide_render = False
        ob.select_set(True)
    bpy.context.view_layer.objects.active = items[0][0]
    res = {}
    rigs = {id(r): r for _, r in items}.values()
    for k in ("col", "ova", "rough", "metal", "normal"):
        if k == "ova" and set_name not in TINTED:
            continue
        img = bpy.data.images.new(f"{set_name}_{k}", w, h, alpha=True, float_buffer=True)
        img.colorspace_settings.name = "Non-Color"
        img.generated_color = (0.5, 0.5, 1.0, 1.0) if k == "normal" else (0, 0, 0, 1)
        for r in rigs:
            r.channel(k)
            r.target(img)
        if k == "normal":
            bpy.ops.object.bake(type="NORMAL", normal_space="TANGENT", margin=8, use_clear=False)
        else:
            bpy.ops.object.bake(type="EMIT", margin=8, use_clear=False)
        res[k] = pixels(img)
    os.makedirs(out_dir, exist_ok=True)
    col = q8(to_srgb(res["col"][..., :3]))
    if set_name in TINTED:
        a = q8(res["ova"][..., 0])
        write_png(os.path.join(out_dir, f"{set_name}_Color.png"), np.dstack([col, a]))
    else:
        write_png(os.path.join(out_dir, f"{set_name}_Color.png"), col)
    write_png(os.path.join(out_dir, f"{set_name}_Normal.png"), q8(res["normal"][..., :3]))
    write_png(os.path.join(out_dir, f"{set_name}_Roughness.png"), q8(res["rough"][..., 0]))
    write_png(os.path.join(out_dir, f"{set_name}_Metalness.png"), q8(res["metal"][..., 0]))
    print("BAKED", set_name)


def plane(name, w, h, uv_rect=(0, 0, 1, 1)):
    m = geo.Mesh(name)
    u0, v0, u1, v1 = uv_rect
    geo.add_faces(m, [(0, 0, 0), (w, 0, 0), (w, h, 0), (0, h, 0)], [[0, 1, 2, 3]],
                  lambda vs, n: [(u0, v0), (u1, v0), (u1, v1), (u0, v1)])
    return m.build(bpy.context.scene.collection, sharp_angle=None)


def bake_all(unit, out_dir, only=None):
    """unit: build.Unit at rest (door shut, locked). Bakes every set into out_dir."""
    s = unit.spec
    o = unit.objs
    # object parameters the recipes read
    o["Slat_C"]["grime"], o["Slat_A"]["grime"], o["Slat_B"]["grime"] = 1.0, 0.22, 0.28
    o["BottomBar"]["barz"] = s.gap
    want = (lambda k: only is None or k in only)

    if want("DoorKit"):
        slat = Rig("bk_slat", M.slat)
        items = [(o["Slat_A"], slat), (o["Slat_B"], slat), (o["Slat_C"], slat),
                 (o["BottomBar"], Rig("bk_bar", M.bottom_bar)),
                 (o["LatchBolt"], Rig("bk_bolt", M.latch_bolt)),
                 (o["Padlock"], Rig("bk_lock", lambda nb: M.padlock(nb, s))),
                 (o["Hardware"], Rig("bk_hw", lambda nb: M.hardware(nb, s))),
                 (o["Drum"], Rig("bk_drum", M.drum)),
                 (o["NumberPlate"], Rig("bk_plate", M.plate))]
        bake_set("DoorKit", items, out_dir, samples=48)
    for name, recipe, (w, h) in (("Partition", M.partition, (4, 10)),
                                 ("Facade", M.facade, (4, 10)),
                                 ("Concrete", M.concrete, (8, 8))):
        if want(name):
            p = plane(f"bake_{name}", w, h)
            bake_set(name, [(p, Rig(f"bk_{name}", recipe))], out_dir, samples=12)
            bpy.data.objects.remove(p)
    if want("TrimSheet"):
        items = []
        for strip in geo.STRIPS:
            v0, v1 = geo.strip_rect(strip)
            p = plane(f"bake_strip_{strip}", 4, 0.5, (0, v0, 1, v1))
            items.append((p, Rig(f"bk_{strip}", lambda nb, strip=strip: M.strip(nb, strip))))
        bake_set("TrimSheet", items, out_dir, samples=12)
        for p, _ in items:
            bpy.data.objects.remove(p)


# --- textured materials (renders, export) ---------------------------------------------------

def load(path, data):
    img = bpy.data.images.load(path, check_existing=True)
    img.colorspace_settings.name = "Non-Color" if data else "sRGB"
    if not data:
        img.alpha_mode = "CHANNEL_PACKED"
    return img


def textured(set_name, tex_dir, for_export=False):
    """A material from the baked maps. Renders emulate Roblox's Overlay: the object's `tint`
    property shows wherever the ColorMap's alpha is 0. Export keeps the plain wiring Roblox's
    importer reads (image straight into each Principled input)."""
    key = f"{set_name}{'_export' if for_export else ''}"
    if key in bpy.data.materials:
        return bpy.data.materials[key]
    mat = bpy.data.materials.new(key)
    nb = NB(mat)
    p = lambda k: os.path.join(tex_dir, f"{set_name}_{k}.png")  # noqa: E731
    col = nb.node("ShaderNodeTexImage", image=load(p("Color"), False))
    rough = nb.node("ShaderNodeTexImage", image=load(p("Roughness"), True))
    metal = nb.node("ShaderNodeTexImage", image=load(p("Metalness"), True))
    nrm = nb.node("ShaderNodeTexImage", image=load(p("Normal"), True))
    nm = nb.node("ShaderNodeNormalMap")
    nb.put(nm.inputs["Color"], nrm.outputs["Color"])
    bsdf = nb.node("ShaderNodeBsdfPrincipled")
    out = nb.node("ShaderNodeOutputMaterial")
    if for_export or set_name not in TINTED:
        nb.put(bsdf.inputs["Base Color"], col.outputs["Color"])
    else:
        tint = nb.objattr("tint", "Color")
        nb.put(bsdf.inputs["Base Color"], nb.mixc(col.outputs["Alpha"], tint, col.outputs["Color"]))
    nb.put(bsdf.inputs["Roughness"], rough.outputs["Color"])
    nb.put(bsdf.inputs["Metallic"], metal.outputs["Color"])
    nb.put(bsdf.inputs["Normal"], nm.outputs["Normal"])
    nb.links.new(bsdf.outputs[0], out.inputs["Surface"])
    return mat
