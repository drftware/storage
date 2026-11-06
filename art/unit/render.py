"""Look sheets: the unit in a corridor of its neighbours, after hours.

Everything here is render-only dressing (hallway, light fixtures, boxes, a kept figure); the
unit itself is exactly what ships, wearing the baked textures. The door's tint emulates
Roblox's Overlay: an object's `tint` shows wherever the ColorMap's alpha is 0.
"""

import math
import os

import bpy
from mathutils import Matrix, Vector

import bake
import parts
from nodes import NB, hexc

FONT = "/Applications/RobloxStudio.app/Contents/Resources/content/fonts/Oswald-Bold.ttf"
DOOR_TINTS = {"oxblood": "#7E2A22", "teal": "#2F6466", "mustard": "#B0832C", "navy": "#34507F"}
WALL_TINT = "#CFCAC0"
HALL = 8.0  # corridor width, facade to facade


class View:
    """A posable copy of the unit: part objects plus its slat chain."""

    def __init__(self, spec, objs, chain, root=None):
        self.spec, self.objs, self.chain, self.root = spec, objs, chain, root

    def pose(self, rise, locked=False):
        s = self.spec
        frames, st = s.curtain.slats(rise)
        for i, ob in enumerate(self.chain):
            mz, my, dz, dy = frames[i]
            Y, Z = s.to_blender(mz, my)
            ob.location = (0.0, Y, Z)
            ob.rotation_euler = (math.atan2(dz, dy), 0.0, 0.0)
        bar = Vector((0.0, s.curtain_y, s.bottom_closed + rise))
        L = parts.latch_layout(s)
        self.objs["BottomBar"].location = bar
        self.objs["LatchBolt"].location = bar + Vector((0.0 if locked else -L["throw"], 0, 0))
        self.objs["Padlock"].location = bar
        self.objs["Padlock"].hide_render = not locked
        self.objs["Drum"].rotation_euler = (-s.curtain.drum_angle(st), 0.0, 0.0)

    def tint(self, door=None, wall=None):
        for ob in self.chain:
            if door:
                ob["tint"] = (*hexc(door), 1.0)
        for n, ob in self.objs.items():
            ob["tint"] = (*hexc(wall or WALL_TINT), 1.0) if n == "Facade" else (1.0, 1.0, 1.0, 1.0)


def hero_view(unit, tex):
    """Dress the built unit: textures on, templates hidden, a chain of slats."""
    s = unit.spec
    for name, ob in unit.objs.items():
        tset = __import__("build").TEXSET[name]
        ob.data.materials.clear()
        if tset:
            ob.data.materials.append(bake.textured(tset, tex))
    unit.objs["DoorOrigin"].hide_render = True
    if "CurtainClosed" in unit.objs:  # renders pose the real chain
        unit.objs["CurtainClosed"].hide_render = True
    chain = []
    coll = unit.coll
    for i in range(s.slat_count):
        v = s.slat_variant(i, 7)
        ob = bpy.data.objects.new(f"chain_{i:02d}", unit.objs[f"Slat_{v}"].data)
        coll.objects.link(ob)
        chain.append(ob)
    for v in "ABC":
        unit.objs[f"Slat_{v}"].hide_render = True
    view = View(s, dict(unit.objs), chain)
    plate_text(view, "214")
    return view


def plate_text(view, text, parent=None):
    cu = bpy.data.curves.new(f"num_{text}", "FONT")
    cu.body = text
    if os.path.exists(FONT):
        cu.font = bpy.data.fonts.load(FONT, check_existing=True)
    cu.size = 0.5
    cu.align_x = "CENTER"
    cu.align_y = "CENTER"
    ob = bpy.data.objects.new(f"num_{text}", cu)
    ob.location = (0.0, -0.032, 9.2)
    ob.rotation_euler = (math.radians(90), 0, 0)
    m = bpy.data.materials.get("plate_ink") or bpy.data.materials.new("plate_ink")
    nb = NB(m)
    b = nb.node("ShaderNodeBsdfPrincipled")
    nb.put(b.inputs["Base Color"], hexc("#E4E1D8"))
    nb.put(b.inputs["Roughness"], 0.5)
    o = nb.node("ShaderNodeOutputMaterial")
    nb.links.new(b.outputs[0], o.inputs[0])
    cu.materials.append(m)
    (parent.users_collection[0] if parent else bpy.context.scene.collection).objects.link(ob)
    if parent:
        ob.parent = parent
    view.objs[f"num_{text}"] = ob
    return ob


def clone(view, name, matrix, number):
    """A neighbour: linked copies of every part under an empty at `matrix`."""
    coll = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(coll)
    root = bpy.data.objects.new(name, None)
    coll.objects.link(root)
    root.matrix_world = matrix
    objs = {}
    for n, ob in view.objs.items():
        if n.startswith("num_"):
            continue
        c = ob.copy()
        coll.objects.link(c)
        c.parent = root
        objs[n] = c
    chain = []
    for ob in view.chain:
        c = ob.copy()
        coll.objects.link(c)
        c.parent = root
        chain.append(c)
    v = View(view.spec, objs, chain, root)
    plate_text(v, number, parent=root)
    return v


# --- the corridor ---------------------------------------------------------------------------

def emissive(name, color, strength):
    m = bpy.data.materials.new(name)
    nb = NB(m)
    e = nb.node("ShaderNodeEmission")
    nb.put(e.inputs["Color"], color)
    nb.put(e.inputs["Strength"], strength)
    o = nb.node("ShaderNodeOutputMaterial")
    nb.links.new(e.outputs[0], o.inputs[0])
    return m


def simple(name, color, rough=0.6, metal=0.0):
    m = bpy.data.materials.new(name)
    nb = NB(m)
    b = nb.node("ShaderNodeBsdfPrincipled")
    nb.put(b.inputs["Base Color"], color)
    nb.put(b.inputs["Roughness"], rough)
    nb.put(b.inputs["Metallic"], metal)
    o = nb.node("ShaderNodeOutputMaterial")
    nb.links.new(b.outputs[0], o.inputs[0])
    return m


def box_obj(name, lo, hi, mat, coll):
    import geo
    m = geo.Mesh(name)
    geo.box(m, lo, hi, geo.map_floor(8.0))
    ob = m.build(coll)
    ob.data.materials.append(mat)
    return ob


def corridor(view, tex, coll, length=60.0):
    """Hall floor, opposite wall line, ceiling, joists, fixtures, exit sign, haze."""
    import geo
    W = view.spec.width
    conc = bake.textured("Concrete", tex)
    m = geo.Mesh("hall_floor")
    geo.add_faces(m, [(-length, -HALL, 0), (length, -HALL, 0), (length, 0, 0), (-length, 0, 0)],
                  [[0, 1, 2, 3]], geo.map_floor(8.0))
    fl = m.build(coll)
    fl.data.materials.append(conc)
    ceil = simple("ceiling", hexc("#1C1D1F"), 0.9)
    box_obj("ceiling", (-length, -HALL - 14, 13.0), (length, 14, 13.4), ceil, coll)
    steel = simple("joist", hexc("#2A2B2E"), 0.5, 0.8)
    x = -length
    while x < length:
        box_obj("joist", (x - 0.15, -HALL - 14, 12.4), (x + 0.15, 14, 13.0), steel, coll)
        x += 6.0
    # hall light fixtures: dark housings, cold diffusers; the hero's is on, a far one dim
    housing = simple("housing", hexc("#3A3C40"), 0.45, 0.7)
    lights = []
    for i, (fx, power) in enumerate(((0.0, 900.0), (-24.0, 160.0), (24.0, 0.0), (48.0, 220.0))):
        box_obj(f"fix_{i}", (fx - 2.0, -HALL / 2 - 0.3, 12.15), (fx + 2.0, -HALL / 2 + 0.3, 12.4),
                housing, coll)
        for k in (-1.5, 0.0, 1.5):
            box_obj(f"chain_{i}", (fx + k - 0.02, -HALL / 2 - 0.02, 12.4), (fx + k + 0.02, -HALL / 2 + 0.02, 13.0), steel, coll)
        dif = emissive(f"diffuser_{i}", hexc("#E6F2EE"), 6.0 if power > 300 else (1.2 if power else 0.02))
        box_obj(f"dif_{i}", (fx - 1.9, -HALL / 2 - 0.22, 12.1), (fx + 1.9, -HALL / 2 + 0.22, 12.16),
                dif, coll)
        if power:
            ld = bpy.data.lights.new(f"hall_{i}", "AREA")
            ld.shape = "RECTANGLE"
            ld.size, ld.size_y = 3.8, 0.44
            ld.energy = power * 0.8
            ld.spread = math.radians(105)
            ld.color = (0.86, 0.95, 0.93)
            lo = bpy.data.objects.new(f"hall_{i}", ld)
            lo.location = (fx, -HALL / 2, 12.08)
            coll.objects.link(lo)
            lights.append(lo)
    # the stairwell's exit sign at the far end
    sign = emissive("exit", hexc("#FF2A1A"), 14.0)
    box_obj("exit_sign", (length - 0.6, -HALL / 2 - 0.9, 9.6), (length - 0.4, -HALL / 2 + 0.9, 10.3),
            sign, coll)
    rl = bpy.data.lights.new("exit_glow", "POINT")
    rl.energy = 60.0
    rl.color = (1.0, 0.15, 0.08)
    rl.shadow_soft_size = 0.6
    ro = bpy.data.objects.new("exit_glow", rl)
    ro.location = (length - 1.2, -HALL / 2, 9.9)
    coll.objects.link(ro)
    # haze
    vol = bpy.data.materials.new("haze")
    nb = NB(vol)
    pv = nb.node("ShaderNodeVolumePrincipled")
    nb.put(pv.inputs["Density"], 0.006)
    nb.put(pv.inputs["Anisotropy"], 0.45)
    nb.put(pv.inputs["Color"], hexc("#C9D2D4"))
    o = nb.node("ShaderNodeOutputMaterial")
    nb.links.new(pv.outputs[0], o.inputs["Volume"])
    box_obj("haze", (-length, -HALL - 0.2, 0.0), (length, 0.2, 13.0), vol, coll)
    return lights


# --- props (render only) ----------------------------------------------------------------------

def cardboard():
    if "cardboard" in bpy.data.materials:
        return bpy.data.materials["cardboard"]
    m = bpy.data.materials.new("cardboard")
    nb = NB(m)
    tc = nb.node("ShaderNodeTexCoord")
    obj = tc.outputs["Object"]
    n = nb.noise((obj, None), 6.0, detail=6)
    n2 = nb.noise((obj, None), 0.8, detail=3)
    col = nb.mixc(nb.mr(n, 0.3, 0.7), hexc("#8A6238"), hexc("#A9804F"))
    col = nb.tint(col, nb.mr(n2, 0.3, 0.7, 0.75, 1.05))
    x, y, z = nb.sep(tc.outputs["Generated"])
    tape = nb.mul(nb.band(x, 0.45, 0.55, 0.004), nb.ss(z, 0.86, 0.9))
    col = nb.mixc(tape, col, hexc("#B49A6A"))
    b = nb.node("ShaderNodeBsdfPrincipled")
    nb.put(b.inputs["Base Color"], col)
    nb.put(b.inputs["Roughness"], nb.mixf(tape, 0.85, 0.3))
    nb.put(b.inputs["Normal"], nb.bump(n, 0.3, 0.01))
    o = nb.node("ShaderNodeOutputMaterial")
    nb.links.new(b.outputs[0], o.inputs[0])
    return m


def box_prop(coll, center, size, rot=0.0):
    import geo
    m = geo.Mesh("box")
    sx, sy, sz = size
    geo.box(m, (-sx / 2, -sy / 2, -sz / 2), (sx / 2, sy / 2, sz / 2), None, bevel=0.03)
    ob = m.build(coll)
    # normalise object space so the tape sits on top: z in [-0.5, 0.5]
    ob.location = (center[0], center[1], center[2] + sz / 2)
    ob.rotation_euler = (0, 0, rot)
    ob.data.materials.append(cardboard())
    return ob


def kept_figure(coll, loc, rot=0.0, height=5.4):
    """A person under shrink-wrap: a dark body inside a milky, creased wrap."""
    def blob(name, scale, mat):
        mb = bpy.data.metaballs.new(name)
        mb.resolution = 0.09
        mb.render_resolution = 0.05
        h = height
        up = Matrix.Rotation(math.radians(90), 4, "Y").to_quaternion()  # capsule X axis -> Z
        for (x, y, z, r, half) in (
                (0.0, -0.06, h * 0.9, 0.48, 0.0),       # head, bowed a little
                (0.0, -0.02, h * 0.81, 0.42, 0.0),      # neck, swallowed by the wrap
                (0.0, 0.0, h * 0.66, 0.68, h * 0.11),   # chest
                (0.5, 0.05, h * 0.6, 0.3, h * 0.15),    # arms bound to the sides
                (-0.5, 0.05, h * 0.6, 0.3, h * 0.15),
                (0.0, 0.0, h * 0.49, 0.62, h * 0.05),   # hips
                (0.16, 0.0, h * 0.27, 0.36, h * 0.18),  # legs wrapped together
                (-0.16, 0.0, h * 0.27, 0.36, h * 0.18),
                (0.17, -0.12, h * 0.05, 0.3, 0.0),      # feet
                (-0.17, -0.12, h * 0.05, 0.3, 0.0)):
            e = mb.elements.new(type="CAPSULE" if half else "BALL")
            e.co = (x, y, z)
            e.radius = r * scale
            if half:
                e.size_x = half
                e.rotation = up
            e.stiffness = 2.6 if name == "kept_wrap" else 3.2
        ob = bpy.data.objects.new(name, mb)
        coll.objects.link(ob)
        ob.location = loc
        ob.rotation_euler = (0, 0, rot)
        mb.materials.append(mat)
        return ob
    body = simple("kept_body", hexc("#1F1B18"), 0.75)
    wrap = bpy.data.materials.new("wrap")
    nb = NB(wrap)
    tc = nb.node("ShaderNodeTexCoord")
    crease = nb.noise((nb.vop("MULTIPLY", tc.outputs["Object"], (1.0, 1.0, 0.25)), None), 9.0,
                      detail=6, rough=0.6, distortion=1.5)
    b = nb.node("ShaderNodeBsdfPrincipled")
    nb.put(b.inputs["Base Color"], hexc("#E2E8E6"))
    nb.put(b.inputs["Roughness"], 0.14)
    nb.put(b.inputs["Transmission Weight"], 0.62)
    nb.put(b.inputs["IOR"], 1.45)
    nb.put(b.inputs["Coat Weight"], 1.0)
    nb.put(b.inputs["Coat Roughness"], 0.05)
    nb.put(b.inputs["Normal"], nb.bump(crease, 0.9, 0.06))
    mix = nb.node("ShaderNodeMixShader")
    tr = nb.node("ShaderNodeBsdfTranslucent")
    nb.put(tr.inputs["Color"], hexc("#7E8784"))
    nb.put(mix.inputs[0], 0.35)
    nb.links.new(b.outputs[0], mix.inputs[1])
    nb.links.new(tr.outputs[0], mix.inputs[2])
    o = nb.node("ShaderNodeOutputMaterial")
    nb.links.new(mix.outputs[0], o.inputs[0])
    a = blob("kept_body", 0.86, body)
    b = blob("kept_wrap", 1.04, wrap)
    return (a, b)


def unit_contents(coll, s):
    """Boxes, and someone the building kept, standing at the back."""
    D = s.depth
    for c, sz, r in (((-4.3, D - 1.2, 0), (1.8, 1.8, 1.6), 0.05), ((-4.3, D - 1.2, 1.6), (1.6, 1.6, 1.4), -0.1),
                     ((-2.2, D - 1.0, 0), (1.5, 1.4, 1.3), 0.12), ((-4.4, D - 3.4, 0), (1.4, 1.6, 1.2), -0.04),
                     ((3.9, D - 1.6, 0), (2.0, 1.6, 1.8), 0.0), ((4.1, D - 1.4, 1.8), (1.5, 1.3, 1.1), 0.3),
                     ((-3.6, 3.4, 0), (1.2, 1.1, 0.9), 0.5)):
        box_prop(coll, c, sz, r)
    return kept_figure(coll, (0.9, D - 1.6, 0.0), rot=math.radians(8))


# --- camera, render -----------------------------------------------------------------------------

def camera(loc, target, lens=24.0, name="cam"):
    cam = bpy.data.cameras.new(name)
    cam.lens = lens
    cam.clip_start = 0.05
    cam.clip_end = 500
    ob = bpy.data.objects.new(name, cam)
    bpy.context.scene.collection.objects.link(ob)
    ob.location = loc
    ob.rotation_euler = (Vector(target) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
    return ob


def setup(samples, res, exposure=0.0):
    sc = bpy.context.scene
    bake.gpu_cycles(samples)
    sc.cycles.use_denoising = True
    sc.cycles.denoiser = "OPENIMAGEDENOISE"
    sc.cycles.use_adaptive_sampling = True
    sc.cycles.adaptive_threshold = 0.02
    sc.cycles.max_bounces = 6
    sc.cycles.volume_bounces = 1
    sc.cycles.volume_step_rate = 4.0
    sc.cycles.caustics_reflective = False
    sc.cycles.caustics_refractive = False
    sc.cycles.blur_glossy = 1.0
    sc.render.resolution_x, sc.render.resolution_y = res
    sc.render.resolution_percentage = 100
    sc.view_settings.view_transform = "AgX"
    sc.view_settings.look = "AgX - Medium High Contrast"
    sc.view_settings.exposure = exposure
    sc.render.image_settings.file_format = "PNG"
    if not sc.world:
        sc.world = bpy.data.worlds.new("World")
    w = sc.world
    w.use_nodes = True
    bg = w.node_tree.nodes.get("Background") or w.node_tree.nodes.new("ShaderNodeBackground")
    bg.inputs["Color"].default_value = (0.012, 0.014, 0.02, 1)
    bg.inputs["Strength"].default_value = 1.0


def flashlight(cam, on, target):
    """The player's torch: a warm spot just off the camera."""
    ob = bpy.data.objects.get("torch")
    if ob is None:
        ld = bpy.data.lights.new("torch", "SPOT")
        ld.energy = 260.0
        ld.spot_size = math.radians(48)
        ld.spot_blend = 0.55
        ld.color = (1.0, 0.9, 0.76)
        ld.shadow_soft_size = 0.06
        ob = bpy.data.objects.new("torch", ld)
        bpy.context.scene.collection.objects.link(ob)
    ob.hide_render = not on
    bpy.context.view_layer.update()
    ob.location = cam.matrix_world @ Vector((0.35, -0.3, 0.0))
    ob.rotation_euler = (Vector(target) - ob.location).to_track_quat("-Z", "Y").to_euler()


def shoot(cam, path, exposure=None):
    sc = bpy.context.scene
    sc.camera = cam
    if exposure is not None:
        sc.view_settings.exposure = exposure
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)
    print("RENDERED", path)


# --- studio ---------------------------------------------------------------------------------------

def studio_rig():
    """Soft key, fill and rim on a dark grey sweep. Returns its objects (hidden by default)."""
    objs = []
    floor = simple("studio_floor", hexc("#3A3B3D"), 0.7)
    import geo
    m = geo.Mesh("studio_floor")
    geo.add_faces(m, [(-200, -200, -0.002), (200, -200, -0.002), (200, 200, -0.002), (-200, 200, -0.002)],
                  [[0, 1, 2, 3]], None)
    ob = m.build(bpy.context.scene.collection, sharp_angle=None)
    ob.data.materials.append(floor)
    objs.append(ob)
    for name, loc, size, power, col in (("key", (-14, -16, 18), 10.0, 9000.0, (1.0, 0.96, 0.9)),
                                        ("fill", (16, -10, 8), 8.0, 2200.0, (0.85, 0.9, 1.0)),
                                        ("rim", (8, 22, 16), 8.0, 6000.0, (0.9, 0.95, 1.0))):
        ld = bpy.data.lights.new(f"studio_{name}", "AREA")
        ld.size = size
        ld.energy = power
        ld.color = col
        lo = bpy.data.objects.new(f"studio_{name}", ld)
        lo.location = loc
        lo.rotation_euler = (Vector((4, 4, 3)) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
        bpy.context.scene.collection.objects.link(lo)
        objs.append(lo)
    for o in objs:
        o.hide_render = True
    return objs


def world(color, strength=1.0):
    w = bpy.context.scene.world
    bg = w.node_tree.nodes.get("Background")
    bg.inputs["Color"].default_value = (*color, 1.0)
    bg.inputs["Strength"].default_value = strength
