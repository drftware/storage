"""Build the home's kit, headless (art/home/README.md).

    blender -b --factory-startup -P art/home/build.py -- --stage textures|door|export

Stages:
    textures  the home's texture sets (looks.py LOOKS) into art/home/out/textures, with the unit's
              bake (art/unit/bake.py)
    door      HomeDoor: the DoorKit's layout kept new, baked on the M's own door parts (the unit's
              M must be built first: its atlas pack is art/unit/out/M/unit.blend)
    export    art/home/out/Home.fbx (the home front, the door's parts in HomeDoor, the
              furnishings: one MeshPart each) and src/shared/Home/Specs.luau

The ground floor (art/lobby) wears the sets, stands the home front in every gap and the
furnishings round the floor, and draws the look sheets.
"""

import argparse
import importlib.util
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
UNIT = os.path.abspath(os.path.join(HERE, "..", "unit"))
sys.path.insert(0, UNIT)
sys.path.insert(0, HERE)

import bpy  # noqa: E402

import bake  # noqa: E402
import front  # noqa: E402
import furnish  # noqa: E402
import home_spec as K  # noqa: E402
import looks  # noqa: E402
import materials as M  # noqa: E402  the unit's looks: the door's hardware keeps them
import render  # noqa: E402

TEX = os.path.join(HERE, "out", "textures")
UNIT_TEX = os.path.join(UNIT, "out", "textures")
FBX = os.path.join(HERE, "out", "Home.fbx")
SETS = set(looks.LOOKS) | set(looks.SIZES)  # the sets baked here; the rest are the unit's


def register():
    """Teach the unit's bake the home's sets: their sizes and which take the part's paint."""
    for name, (_, _, size) in looks.LOOKS.items():
        bake.SIZES[name] = size
    bake.SIZES.update(looks.SIZES)
    bake.TINTED.update(looks.TINTED)


def unit_kit():
    """The unit's own build module (its Unit and Spec), for the door's parts."""
    s = importlib.util.spec_from_file_location("unit_build", os.path.join(UNIT, "build.py"))
    mod = importlib.util.module_from_spec(s)
    s.loader.exec_module(mod)
    return mod


def door_unit(uk, coll):
    """The M at rest, shut and latched, its small parts wearing the M's atlas pack."""
    unit = uk.Unit(uk.Spec(K.DOOR_SIZE), coll)
    unit.pose(0.0, locked=True)
    dk = [unit.objs[n] for n in ("BottomBar", "LatchBolt", "Padlock", "Hardware", "Drum", "NumberPlate")]
    bake.copy_atlas(dk, os.path.join(UNIT, "out", K.DOOR_SIZE, "unit.blend"))
    return unit


def material(name, set_name, for_export):
    if set_name is None:
        return render.simple(f"plain_{name}", front.PLAIN[name], 0.4)
    return bake.textured(set_name, TEX if set_name in SETS else UNIT_TEX, for_export=for_export)


def texsets():
    """Every exported part's texture set (None: plain, the game sets its Material and Color)."""
    out = {n: front.TEXSET.get(n) for n in front.BUILDERS}
    out.update(furnish.TEXSET)
    out.update({n: "HomeDoor" for n in front.DOOR_PARTS})
    return out


def stage_textures():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    register()
    for name, (recipe, (w, h), _) in looks.LOOKS.items():
        p = bake.plane(f"bake_{name}", w, h)
        bake.bake_set(name, [(p, bake.Rig(f"bk_{name}", recipe))], TEX, samples=12)
        bpy.data.objects.remove(p)


def stage_door():
    """HomeDoor on the M's own parts: the curtain and bar kept new (looks.py), the hardware,
    drum and latch bolt the climb's (inside, over your head), the padlock and plate left blank."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    register()
    uk = unit_kit()
    unit = door_unit(uk, uk.collection("Unit"))
    o, s = unit.objs, unit.spec
    slat = bake.Rig("hd_slat", looks.door_slat)
    items = [(o["Slat_A"], slat), (o["Slat_B"], slat), (o["Slat_C"], slat),
             (o["BottomBar"], bake.Rig("hd_bar", looks.door_bar)),
             (o["LatchBolt"], bake.Rig("hd_bolt", M.latch_bolt)),
             (o["Hardware"], bake.Rig("hd_hw", lambda nb: M.hardware(nb, s))),
             (o["Drum"], bake.Rig("hd_drum", M.drum))]
    bake.bake_set("HomeDoor", items, TEX, samples=48)


def world_box(ob):
    vs = [ob.matrix_world @ v.co for v in ob.data.vertices]
    lo = [min(v[i] for v in vs) for i in range(3)]
    hi = [max(v[i] for v in vs) for i in range(3)]
    return lo, hi


def stage_export():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    register()
    uk = unit_kit()
    unit = door_unit(uk, uk.collection("Unit"))
    s = unit.spec
    for name, ob in list(unit.objs.items()):  # the M's own front and box go: the home's replace them
        if name not in front.DOOR_PARTS:
            me = ob.data
            bpy.data.objects.remove(ob)
            if me is not None:
                bpy.data.meshes.remove(me)
    coll = bpy.context.scene.collection
    objs = {n: unit.objs[n] for n in front.DOOR_PARTS}
    for name, mesh in list(front.meshes(s).items()) + list(furnish.meshes().items()):
        objs[name] = mesh.build(coll)
    sets = texsets()
    rows = {}
    bpy.ops.object.select_all(action="DESELECT")
    for name, ob in objs.items():
        assert ob.name == name, f"{name} imported as {ob.name}"
        ob.hide_render = ob.hide_viewport = False
        ob.hide_set(False)
        ob.data.materials.clear()
        ob.data.materials.append(material(name, sets[name], True))
        lo, hi = world_box(ob)
        tris = sum(len(p.vertices) - 2 for p in ob.data.polygons)
        assert tris < 20000, f"{name} has {tris} triangles (Roblox's cap)"
        rows[name] = dict(size=(hi[0] - lo[0], hi[2] - lo[2], hi[1] - lo[1]),
                          centre=tuple((lo[i] + hi[i]) / 2 for i in range(3)), tris=tris)
        ob.select_set(True)
    bpy.context.view_layer.objects.active = objs["Facade"]
    os.makedirs(os.path.dirname(FBX), exist_ok=True)
    bpy.ops.export_scene.fbx(
        filepath=FBX, use_selection=True, object_types={"MESH"},
        apply_scale_options="FBX_SCALE_UNITS", axis_forward="Z", axis_up="Y",
        use_mesh_modifiers=True, mesh_smooth_type="OFF", use_tspace=False,
        add_leaf_bones=False, bake_anim=False, path_mode="COPY", embed_textures=True)
    print("FBX", FBX, os.path.getsize(FBX), f"{sum(r['tris'] for r in rows.values())} triangles",
          {n: r["tris"] for n, r in rows.items()})
    plate, toggle = front.switch_at(s)
    lua = os.path.join(K.ROOT, "src", "shared", "Home", "Specs.luau")
    os.makedirs(os.path.dirname(lua), exist_ok=True)
    K.write_luau(lua, rows, plate, toggle, front.lamp_at(s))


STAGES = {"textures": stage_textures, "door": stage_door, "export": stage_export}

if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--stage", choices=list(STAGES), required=True)
    STAGES[ap.parse_args(argv).stage]()
    print("DONE")
