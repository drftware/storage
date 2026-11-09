"""Build the storage unit in Blender, headless.

    blender -b --factory-startup -P art/unit/build.py -- --size M [--stage geo|textures|export|renders|all]

Stages:
    geo       build the parts, pose the door, save out/<Size>/unit.blend, quick checks
    textures  bake the five texture sets to out/textures/ (shared by every size)
    export    FBX for Studio's 3D Importer + the game's spec module
    renders   the look sheets in art/sheets/
"""

import argparse
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import bpy  # noqa: E402
from mathutils import Vector  # noqa: E402

import parts  # noqa: E402
from spec import Spec  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
OUT = os.path.join(HERE, "out")
SHEETS = os.path.join(ROOT, "art", "sheets")

# part name -> texture set
TEXSET = {
    "Floor": "Concrete",
    "WallLeft": "Partition", "WallRight": "Partition", "WallBack": "Partition",
    "FacadeBack": "Partition",
    "Facade": "Facade",
    "Frame": "TrimSheet", "Top": "Partition",
    "Hardware": "DoorKit", "Drum": "DoorKit", "BottomBar": "DoorKit", "LatchBolt": "DoorKit",
    "Padlock": "DoorKit", "NumberPlate": "DoorKit",
    "Slat_A": "DoorKit", "Slat_B": "DoorKit", "Slat_C": "DoorKit",
    "CurtainClosed": "DoorKit",
    "DoorOrigin": None,
}


def args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    p = argparse.ArgumentParser()
    p.add_argument("--size", default="M")
    p.add_argument("--stage", default="geo")
    p.add_argument("--quick", action="store_true")
    p.add_argument("--only", default="")
    return p.parse_args(argv)


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.unit_settings.system = "NONE"
    return sc


def collection(name, parent=None):
    c = bpy.data.collections.get(name) or bpy.data.collections.new(name)
    if c.name not in (parent or bpy.context.scene.collection).children:
        (parent or bpy.context.scene.collection).children.link(c)
    return c


class Unit:
    """The built unit: its parts, and the posable door chain for renders."""

    @classmethod
    def from_scene(cls, spec):
        """Re-attach to a unit saved by the textures stage."""
        u = cls.__new__(cls)
        u.spec, u.coll = spec, bpy.data.collections["Unit"]
        u.objs = {n: bpy.data.objects[n] for n in TEXSET if n in bpy.data.objects}
        u.tris = {n: sum(len(p.vertices) - 2 for p in o.data.polygons) for n, o in u.objs.items()}
        u.rest_index = {v: next(i for i in range(spec.slat_count) if spec.slat_variant(i, 7) == v)
                        for v in ("C", "A", "B")}
        u.chain = []
        return u

    def __init__(self, spec, coll):
        self.spec = spec
        self.coll = coll
        self.objs = {}
        s = spec
        builders = {
            "Floor": parts.floor, "WallBack": parts.wall_back,
            "WallLeft": lambda s: parts.wall_side(s, -1),
            "WallRight": lambda s: parts.wall_side(s, 1),
            "FacadeBack": parts.facade_back, "Facade": parts.facade, "Frame": parts.frame,
            "Top": parts.top, "Hardware": parts.hardware, "Drum": parts.drum,
            "Slat_A": lambda s: parts.slat(s, "A"), "Slat_B": lambda s: parts.slat(s, "B"),
            "Slat_C": lambda s: parts.slat(s, "C"), "CurtainClosed": parts.curtain_closed,
            "BottomBar": parts.bottom_bar,
            "LatchBolt": parts.latch_bolt, "Padlock": parts.padlock,
            "NumberPlate": parts.number_plate, "DoorOrigin": parts.door_origin,
        }
        self.tris = {}
        for name, fn in builders.items():
            mesh = fn(s)
            self.tris[name] = mesh.tris()
            ob = mesh.build(coll)
            self.objs[name] = ob
        # the drum turns about its axis: put its origin there
        self._recentre(self.objs["Drum"], Vector(s.drum_center))
        # templates rest at the chain index of their first use; bar parts at the bar frame
        bar = Vector((0.0, s.curtain_y, s.bottom_closed))
        for n in ("BottomBar", "LatchBolt", "Padlock"):
            self.objs[n].location = bar
        self.rest_index = {}
        for v in ("C", "A", "B"):
            self.rest_index[v] = next(i for i in range(s.slat_count) if s.slat_variant(i, 7) == v)
        self.chain = []

    @staticmethod
    def _recentre(ob, c):
        me = ob.data
        for v in me.vertices:
            v.co -= c
        ob.location = c

    def make_chain(self):
        """Linked duplicates for every slat, for renders only (export keeps the templates)."""
        s = self.spec
        ch = collection("Chain", self.coll)
        for i in range(s.slat_count):
            v = s.slat_variant(i, 7)
            src = self.objs[f"Slat_{v}"]
            ob = bpy.data.objects.new(f"chain_{i:02d}", src.data)
            ch.objects.link(ob)
            self.chain.append(ob)
        for v in ("A", "B", "C"):
            self.objs[f"Slat_{v}"].hide_render = True
            self.objs[f"Slat_{v}"].hide_viewport = True
        return ch

    def pose(self, rise, locked=False):
        s = self.spec
        frames, st = s.curtain.slats(rise)
        targets = self.chain if self.chain else []
        for i, ob in enumerate(targets):
            mz, my, dz, dy = frames[i]
            Y, Z = s.to_blender(mz, my)
            ob.location = (0.0, Y, Z)
            ob.rotation_euler = (math.atan2(dz, dy), 0.0, 0.0)
        for v, i in self.rest_index.items():  # templates sit where their index is
            mz, my, dz, dy = frames[i]
            Y, Z = s.to_blender(mz, my)
            self.objs[f"Slat_{v}"].location = (0.0, Y, Z)
            self.objs[f"Slat_{v}"].rotation_euler = (math.atan2(dz, dy), 0.0, 0.0)
        bar = Vector((0.0, s.curtain_y, s.bottom_closed + rise))
        self.objs["BottomBar"].location = bar
        L = parts.latch_layout(s)
        self.objs["LatchBolt"].location = bar + Vector((0.0 if locked else -L["throw"], 0, 0))
        self.objs["Padlock"].location = bar
        self.objs["Padlock"].hide_render = not locked
        self.objs["Padlock"].hide_viewport = not locked
        self.objs["Drum"].rotation_euler = (-s.curtain.drum_angle(st), 0.0, 0.0)
        return st


def quick_materials(unit):
    """Flat stand-in shading for geometry checks."""
    cols = {"Concrete": (0.45, 0.44, 0.42), "Partition": (0.62, 0.64, 0.66),
            "Facade": (0.75, 0.72, 0.66), "TrimSheet": (0.16, 0.17, 0.19),
            "DoorKit": (0.55, 0.12, 0.10), None: (1, 0, 1)}
    mats = {}
    for k, c in cols.items():
        m = bpy.data.materials.new(f"quick_{k}")
        m.use_nodes = True
        b = m.node_tree.nodes["Principled BSDF"]
        b.inputs["Base Color"].default_value = (*c, 1)
        b.inputs["Roughness"].default_value = 0.5
        b.inputs["Metallic"].default_value = 0.6 if k in ("Partition", "TrimSheet") else 0.0
        m.use_backface_culling = True
        mats[k] = m
    for name, ob in unit.objs.items():
        ob.data.materials.clear()
        ob.data.materials.append(mats[TEXSET[name]])
    unit.objs["DoorOrigin"].hide_render = True


def camera(name, loc, target, lens=28.0):
    cam = bpy.data.cameras.new(name)
    cam.lens = lens
    cam.clip_start = 0.05
    cam.clip_end = 400
    ob = bpy.data.objects.new(name, cam)
    bpy.context.scene.collection.objects.link(ob)
    ob.location = loc
    d = Vector(target) - Vector(loc)
    ob.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    return ob


def quick_render(unit, path, cam, res=(960, 720), engine="BLENDER_EEVEE"):
    sc = bpy.context.scene
    sc.camera = cam
    sc.render.engine = engine
    sc.render.resolution_x, sc.render.resolution_y = res
    sc.render.filepath = path
    if not sc.world:
        sc.world = bpy.data.worlds.new("World")
    sc.world.color = (0.05, 0.05, 0.06)
    bpy.ops.render.render(write_still=True)


def stage_geo(spec, quick=False):
    sc = reset()
    coll = collection("Unit")
    unit = Unit(spec, coll)
    unit.make_chain()
    quick_materials(unit)
    # light
    for loc, e in (((-6, -9, 12), 1800.0), ((5, -4, 9), 900.0), ((0, 6, 9), 500.0)):
        ld = bpy.data.lights.new("L", "POINT")
        ld.energy = e
        ld.shadow_soft_size = 1.0
        lo = bpy.data.objects.new("L", ld)
        lo.location = loc
        sc.collection.objects.link(lo)
    tmp = os.path.join(OUT, spec.size, "checks")
    os.makedirs(tmp, exist_ok=True)
    shots = [
        ("front", (5.5, -14, 6.5), (0, 0, 4.2), 30, 0.0, True),
        ("peek", (5.5, -14, 6.5), (0, 0, 4.2), 30, spec.peek, False),
        ("open", (5.5, -14, 6.5), (0, 0, 4.2), 30, spec.travel, False),
        ("inside", (-3.5, 9.5, 5.2), (0.5, 0, 5.5), 24, 0.0, True),
        ("coil_open", (3.2, 3.8, 7.1), (0.6, 1.0, 8.9), 30, spec.travel, False),
        ("coil_half", (-3.2, 3.6, 7.1), (-1.0, 1.0, 8.9), 30, 4.0, False),
        ("top", (8, -8, 18), (0, 6, 6), 26, 0.0, True),
        ("latch", (3.0, -1.6, 0.9), (3.6, 0.4, 0.35), 40, 0.0, True),
    ]
    if quick:
        shots = shots[:1]
    for name, loc, tgt, lens, rise, locked in shots:
        unit.pose(rise, locked)
        cam = camera(f"cam_{name}", loc, tgt, lens)
        quick_render(unit, os.path.join(tmp, f"{name}.png"), cam)
    unit.pose(0.0, True)
    print("TRIS", unit.tris, "slats", spec.slat_count)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, spec.size, "unit_geo.blend"))
    return unit


def stage_textures(spec, only=None):
    """Build at rest, unwrap the DoorKit atlas, bake, save the scene the later stages open."""
    import bake
    reset()
    unit = Unit(spec, collection("Unit"))
    unit.pose(0.0, locked=True)
    dk = [unit.objs[n] for n in ("BottomBar", "LatchBolt", "Padlock", "Hardware", "Drum",
                                 "NumberPlate")]
    if spec.size == "M":
        bake.unwrap_atlas(dk, parts.ATLAS_RECT)
    else:  # the M's textures serve every size, so its small parts wear the M's atlas pack
        bake.copy_atlas(dk, os.path.join(OUT, "M", "unit.blend"))
    tex = os.path.join(OUT, "textures")
    if only != ["none"]:
        bake.bake_all(unit, tex, only)
    path = os.path.join(OUT, spec.size, "unit.blend")
    bpy.ops.wm.save_as_mainfile(filepath=path)
    print("SAVED", path)
    return unit


SHOTS = {
    # name: (camera, target, lens, hero rise, locked, exposure, torch, figure at)
    "hall": ((-10.5, -6.4, 4.7), (3.0, -0.4, 4.6), 20, 0.0, True, 0.3, False, "back"),
    "hero": ((-5.2, -7.5, 2.9), (0.9, 0.0, 5.1), 17, 0.0, True, 0.35, False, "back"),
    "peek": ((1.4, -3.4, 0.85), (-0.1, 3.0, 0.5), 22, None, False, 0.5, True, "door"),
    "open": ((3.2, -7.4, 4.3), (-0.3, 5.0, 3.5), 22, "open", False, 0.3, True, "back"),
    "inside": ((2.2, 10.6, 1.9), (-0.6, 0.5, 1.6), 22, 0.0, True, 1.2, False, "away"),
    "latch": ((3.15, -2.3, 1.15), (3.68, 0.38, 0.3), 50, 0.0, True, 0.6, False, "back"),
    "coil": ((-2.6, 4.6, 5.0), (0.4, 1.0, 8.6), 26, 3.2, False, 0.9, True, "away"),
    "tops": ((-9.0, -6.5, 12.6), (2.0, 5.0, 9.6), 20, 0.0, True, 1.5, False, "back"),
}
STUDIO = {
    # name: (camera, target, lens, rise, locked, hide)
    "studio": ((-11.5, -15.0, 9.0), (0.0, 3.0, 4.2), 32, 3.6, False, ()),
    "cutaway": ((10.5, 20.0, 9.5), (-0.5, 2.0, 4.6), 30, 2.2, False, ("WallBack", "WallRight")),
}
FIGURE = {"back": ((0.9, 10.4, 0.0), 8), "door": ((0.5, 2.2, 0.0), -6), "away": ((0.0, 60.0, -50.0), 0)}


def build_scene(spec):
    """The hero unit in its corridor, its neighbours, the dressing and a studio rig."""
    import render as R
    from mathutils import Matrix
    bpy.ops.wm.open_mainfile(filepath=os.path.join(OUT, spec.size, "unit.blend"))
    unit = Unit.from_scene(spec)
    tex = os.path.join(OUT, "textures")
    view = R.hero_view(unit, tex)
    view.tint(R.DOOR_TINTS["oxblood"])
    neighbours = []
    # a row of this size each side, wall to wall, about 36 studs back and 48 on (four M a side)
    W = spec.width
    ks = range(-round(36.0 / W), round(48.0 / W) + 1)
    for k in ks:
        if k != 0:
            neighbours.append(R.clone(view, f"n_{k * W:+.0f}", Matrix.Translation((k * W, 0, 0)),
                                      str(214 + 2 * k)))
    for k in ks:
        m = Matrix.Translation((k * W, -R.HALL, 0)) @ Matrix.Rotation(math.pi, 4, "Z")
        neighbours.append(R.clone(view, f"o_{k * W:+.0f}", m, str(215 + 2 * k)))
    for i, n in enumerate(neighbours):
        n.tint(R.DOOR_TINTS["oxblood"])
        n.pose(0.0, locked=(i % 3 == 1))
    dress = collection("Dressing")
    R.corridor(view, tex, dress)
    fig = R.unit_contents(dress, spec)
    fill = bpy.data.lights.new("inside_fill", "AREA")
    fill.size = 6.0
    fill.energy = 18.0
    fill.color = (0.55, 0.65, 0.85)
    fo = bpy.data.objects.new("inside_fill", fill)
    fo.location = (0.0, 7.0, 9.5)
    fo.hide_render = True
    bpy.context.scene.collection.objects.link(fo)
    rig = R.studio_rig()
    return view, neighbours, fig, rig


def set_studio(scene, on):
    """Studio: the unit alone on a sweep. Off: the corridor after hours."""
    import render as R
    view, neighbours, fig, rig = scene
    for ob in list(bpy.data.collections["Dressing"].all_objects):
        ob.hide_render = on
    for ob in fig:
        ob.hide_render = on
    for n in neighbours:
        for ob in list(n.root.users_collection[0].all_objects):
            ob.hide_render = on or ob.name.startswith(("Slat_", "DoorOrigin", "CurtainClosed"))
    for ob in rig:
        ob.hide_render = not on
    if on:
        R.world((0.035, 0.037, 0.042), 1.0)
    else:
        R.world((0.012, 0.014, 0.02), 1.0)


def sheet(spec, name):
    """A look sheet's path: the M's are the unit's sheets, other sizes carry theirs in the name."""
    return os.path.join(SHEETS, f"unit-{name}.png" if spec.size == "M" else f"unit-{spec.size}-{name}.png")


def stage_renders(spec, quick=False, only=None):
    import render as R
    scene = build_scene(spec)
    view, neighbours, fig, rig = scene
    R.setup(48 if quick else 160, (960, 540) if quick else (1920, 1080))
    os.makedirs(SHEETS, exist_ok=True)
    fo = bpy.data.objects["inside_fill"]
    set_studio(scene, False)
    for name, (loc, tgt, lens, rise, locked, ev, torch, at) in SHOTS.items():
        if only and name not in only:
            continue
        r = {None: spec.peek, "open": spec.travel}.get(rise, rise)
        view.pose(r, locked)
        p, rot = FIGURE[at]
        for ob in fig:
            ob.location = p
            ob.rotation_euler = (0, 0, math.radians(rot))
        fo.hide_render = name not in ("inside", "coil")
        for ob in list(bpy.data.objects):
            if ob.name.startswith(("ceiling", "joist")):
                ob.hide_render = name == "tops"
        cam = R.camera(loc, tgt, lens, f"cam_{name}")
        R.flashlight(cam, torch, tgt)
        R.shoot(cam, sheet(spec, name), ev)
    fo.hide_render = True
    for ob in list(bpy.data.objects):
        if ob.name.startswith(("ceiling", "joist")):
            ob.hide_render = False
    if bpy.data.objects.get("torch"):
        bpy.data.objects["torch"].hide_render = True

    if not only or any(k in only for k in ("studio", "cutaway", "palette")):
        set_studio(scene, True)
        for name, (loc, tgt, lens, rise, locked, hide) in STUDIO.items():
            if only and name not in only:
                continue
            view.pose(rise, locked)
            for n in hide:
                view.objs[n].hide_render = True
            cam = R.camera(loc, tgt, lens, f"cam_{name}")
            R.shoot(cam, sheet(spec, name), 0.0)
            for n in hide:
                view.objs[n].hide_render = False
        if not only or "palette" in only:
            row = [view] + [n for n in neighbours if n.root.name in ("n_+12", "n_+24", "n_+36")]
            for v, t in zip(row, ("oxblood", "teal", "mustard", "navy")):
                v.tint(R.DOOR_TINTS[t])
                v.pose(0.0, locked=v is view)
                if v.root:
                    for ob in list(v.root.users_collection[0].all_objects):
                        ob.hide_render = ob.name.startswith(
                            ("Slat_", "DoorOrigin", "Padlock", "CurtainClosed"))
            cam = R.camera((18.0, -41.0, 5.2), (18.0, 0.0, 5.0), 30, "cam_palette")
            sc = bpy.context.scene
            keep = (sc.render.resolution_x, sc.render.resolution_y)
            sc.render.resolution_y = int(keep[0] * 0.36)
            R.shoot(cam, sheet(spec, "palette"), 0.0)
            sc.render.resolution_x, sc.render.resolution_y = keep
            for v in row:
                v.tint(R.DOOR_TINTS["oxblood"])
        set_studio(scene, False)
    view.pose(0.0, False)
    return scene


def stage_export(spec):
    """FBX for Studio's 3D Importer, plus the game's generated spec module."""
    import bake
    from spec import write_luau
    bpy.ops.wm.open_mainfile(filepath=os.path.join(OUT, spec.size, "unit.blend"))
    unit = Unit.from_scene(spec)
    s = spec
    unit.pose(0.0, locked=True)
    tex = os.path.join(OUT, "textures")
    bpy.ops.object.select_all(action="DESELECT")
    for name, ob in unit.objs.items():
        ob.hide_render = False
        ob.hide_viewport = False
        ob.hide_set(False)
        ob.data.materials.clear()
        tset = TEXSET[name]
        if tset:
            ob.data.materials.append(bake.textured(tset, tex, for_export=True))
        ob.select_set(True)
    bpy.context.view_layer.objects.active = unit.objs["DoorOrigin"]
    fbx = os.path.join(OUT, f"StorageUnit_{s.size}.fbx")
    bpy.ops.export_scene.fbx(
        filepath=fbx, use_selection=True, object_types={"MESH"},
        apply_scale_options="FBX_SCALE_UNITS", axis_forward="Z", axis_up="Y",
        use_mesh_modifiers=True, mesh_smooth_type="OFF", use_tspace=False,
        add_leaf_bones=False, bake_anim=False, path_mode="COPY", embed_textures=True)
    print("FBX", fbx, os.path.getsize(fbx))

    # rest frames of the moving parts, door-local Roblox axes (+Y up, -Z hallway)
    frames, st = s.curtain.slats(0.0)
    rest = {}
    for v, i in unit.rest_index.items():
        mz, my, dz, dy = frames[i]
        rest[f"Slat_{v}"] = ((0.0, my, -mz), math.atan2(-dz, dy))
    bar = (0.0, s.bottom_closed, 0.0)
    rest["BottomBar"] = (bar, 0.0)
    rest["LatchBolt"] = (bar, 0.0)     # exported shot (locked)
    rest["Padlock"] = (bar, 0.0)
    rest["Drum"] = ((0.0, s.drum_up, s.drum_back), 0.0)
    rest["CurtainClosed"] = ((0.0, 0.0, 0.0), 0.0)  # merged in place: the door frame itself
    L = parts.latch_layout(s)
    W, D, H, F = s.width, s.depth, s.wall_height, s.facade
    dw2, dh = s.door_width / 2, s.door_height
    side = W / 2 - dw2
    colliders = {
        "Floor": ((0.0, -0.5, D / 2), (W, 1.0, D)),
        "WallLeft": ((W / 2, H / 2, (F + D) / 2), (0.2, H, D - F)),
        "WallRight": ((-W / 2, H / 2, (F + D) / 2), (0.2, H, D - F)),
        "WallBack": ((0.0, H / 2, D), (W, H, 0.2)),
        "FacadeLeft": ((dw2 + side / 2, H / 2, 0.17), (side, H, 0.5)),
        "FacadeRight": ((-(dw2 + side / 2), H / 2, 0.17), (side, H, 0.5)),
        "Header": ((0.0, (dh + H) / 2, 0.17), (2 * dw2, H - dh, 0.5)),
        "Top": ((0.0, H + 0.05, (F + D) / 2), (W, 0.1, D - F)),
    }
    extra = dict(rest=rest, latch_throw=L["throw"], colliders=colliders, plate=(1.8, 0.7),
                 tris=unit.tris)
    lua = os.path.join(ROOT, "src", "shared", "StorageUnit", "Specs", f"{s.size}.luau")
    os.makedirs(os.path.dirname(lua), exist_ok=True)
    write_luau(s, lua, extra)
    print("SPEC", lua)


ANIMS = {
    # name: (camera, target, lens, exposure, studio, hide, steps)
    "hall": ((-5.2, -7.5, 2.9), (0.9, 0.0, 5.1), 17, 0.35, False, (),
             [("Hold", 0.6), ("Peek", "peek"), ("Hold", 0.7), ("Open", "open"), ("Hold", 0.9),
              ("Slam", 0.0), ("Hold", 0.8)]),
    "mechanism": ((10.5, 20.0, 9.5), (-0.5, 2.0, 4.6), 30, 0.0, True, ("WallBack", "WallRight"),
                  [("Hold", 0.4), ("Open", "open"), ("Hold", 0.6), ("Close", 0.0), ("Hold", 0.4)]),
}


def stage_anim(spec, only=None, quick=False):
    """Door motion sheets: frames rendered from the same curves the game plays."""
    import subprocess
    import motion
    import render as R
    scene = stage_renders(spec, quick=True, only=["__none__"])
    view, neighbours, fig, rig = scene
    R.setup(24 if quick else 64, (960, 540))
    for name, (loc, tgt, lens, ev, studio, hide, steps) in ANIMS.items():
        if only and name not in only:
            continue
        set_studio(scene, studio)
        for n in hide:
            view.objs[n].hide_render = True
        p, rot = FIGURE["back"]
        for ob in fig:
            ob.location = p
        targets = {"peek": spec.peek, "open": spec.travel}
        seq = motion.timeline([(k, targets.get(a, a)) for k, a in steps], spec.travel)
        cam = R.camera(loc, tgt, lens, f"cam_anim_{name}")
        frames = os.path.join(OUT, spec.size, "anim", name)
        os.makedirs(frames, exist_ok=True)
        for i, rise in enumerate(seq):
            view.pose(rise, False)
            R.shoot(cam, os.path.join(frames, f"{i:04d}.png"), ev)
        for n in hide:
            view.objs[n].hide_render = False
        mp4 = os.path.join(SHEETS, f"door-{name}.mp4")
        gif = os.path.join(SHEETS, f"door-{name}.gif")
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-framerate", "24", "-i",
                        os.path.join(frames, "%04d.png"), "-c:v", "libx264", "-pix_fmt", "yuv420p",
                        "-crf", "18", mp4], check=True)
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-framerate", "24", "-i",
                        os.path.join(frames, "%04d.png"), "-vf",
                        "fps=15,scale=640:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=160[p];[b][p]paletteuse=dither=sierra2_4a",
                        gif], check=True)
        print("ANIM", mp4, len(seq), "frames")


if __name__ == "__main__":
    a = args()
    spec = Spec(a.size)
    if a.stage == "geo":
        stage_geo(spec, a.quick)
    elif a.stage == "textures":
        stage_textures(spec, a.only.split(",") if a.only else None)
    elif a.stage == "export":
        stage_export(spec)
    elif a.stage == "renders":
        stage_renders(spec, a.quick, a.only.split(",") if a.only else None)
    elif a.stage == "anim":
        stage_anim(spec, a.only.split(",") if a.only else None, a.quick)
