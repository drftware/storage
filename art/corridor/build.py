"""Build the corridor kit in Blender, headless (art/corridor/README.md).

    blender -b --factory-startup -P art/corridor/build.py -- --stage export|renders

Stages:
    export   one FBX per piece and one for the hall light fixture in out/ for Open Cloud, and
             src/shared/CorridorKit/Specs.luau
    renders  the look sheets, art/sheets/corridor-*.png

The pieces wear the unit's baked texture sets (art/unit/out/textures): build those first with
scripts/art.sh. The kit bakes nothing of its own. The fixture's lens and eye are plain parts the
game colours (HallLight), so they export untextured.
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
from mathutils import Matrix, Vector  # noqa: E402

import bake  # noqa: E402
import pieces  # noqa: E402
import spec as K  # noqa: E402

OUT = os.path.join(HERE, "out")
TEX = os.path.join(UNIT, "out", "textures")
SHEETS = os.path.join(K.ROOT, "art", "sheets")
TEXSET = {"Floor": "Concrete", "Ceiling": "TrimSheet", "Housing": "TrimSheet",
          "Facade": "Facade", "Trim": "TrimSheet", "Panel": "Partition"}
PIECES = {"Straight": (pieces.straight, K.STRAIGHT)}
# The hall's walls, by their width along the wall: the plain wall is one unit's slot, the dead end
# crosses the whole span.
WALLS = {"Wall": (pieces.plain_wall, K.PLAIN),
         "ShortWall": (lambda: pieces.plain_wall(K.SHORT), K.SHORT),
         "DeadEnd": (pieces.dead_end, K.SPAN)}
# The junctions: the corner, the T and the cross, each a JUNCTION square.
JUNCTIONS = {name: ((lambda n=name: pieces.junction(n)), K.JUNCTION) for name in K.JUNCTIONS}
# The fixture's parts the game colours: untextured, so Roblox's Neon and Color show on them. These
# are only the colours they import with (a dead lens, a frosted dome); HallLight sets the real ones.
PLAIN = {"Diffuser": (0.16, 0.17, 0.18), "Eye": (0.55, 0.55, 0.53)}


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def build(name, at=0.0, coll=None, for_export=True, matrix=None):
    """Builds one piece's or wall's parts as objects, `at` studs along the hall (or at `matrix`, a
    wall's frame). Returns {part: object}."""
    make, _ = PIECES.get(name) or WALLS.get(name) or JUNCTIONS[name]
    objs = {}
    for part, mesh in make().items():
        ob = mesh.build(coll)
        if matrix is not None:
            ob.matrix_world = matrix
        else:
            ob.location.x = at
        ob.data.materials.append(bake.textured(TEXSET[part], TEX, for_export=for_export))
        if part == "Facade" and not for_export:
            import render
            ob["tint"] = (*render.hexc(render.WALL_TINT), 1.0)  # the units' default paint
        objs[part] = ob
    return objs


def plain(name, colour):
    """An untextured material: Roblox's importer makes no SurfaceAppearance for it."""
    key = f"plain_{name}"
    if key in bpy.data.materials:
        return bpy.data.materials[key]
    import render
    return render.simple(key, colour, 0.5)


def build_fixture(at=0.0, coll=None, for_export=True, lens=None, eye=None):
    """The hall light fixture's parts as objects, `at` studs along the hall. `lens` and `eye` are
    render materials for a lit lens and a glowing eye; export uses the plain ones."""
    objs = {}
    for part, mesh in pieces.fixture().items():
        ob = mesh.build(coll)
        ob.location.x = at
        if part in PLAIN:
            mat = {"Diffuser": lens, "Eye": eye}[part] if not for_export else None
            ob.data.materials.append(mat or plain(part, PLAIN[part]))
        else:
            ob.data.materials.append(bake.textured(TEXSET[part], TEX, for_export=for_export))
        objs[part] = ob
    return objs


def export_fbx(objs, active, name):
    bpy.ops.object.select_all(action="DESELECT")
    for ob in objs.values():
        ob.select_set(True)
    bpy.context.view_layer.objects.active = objs[active]
    fbx = os.path.join(OUT, f"Corridor_{name}.fbx")
    bpy.ops.export_scene.fbx(
        filepath=fbx, use_selection=True, object_types={"MESH"},
        apply_scale_options="FBX_SCALE_UNITS", axis_forward="Z", axis_up="Y",
        use_mesh_modifiers=True, mesh_smooth_type="OFF", use_tspace=False,
        add_leaf_bones=False, bake_anim=False, path_mode="COPY", embed_textures=True)
    return fbx


def stage_export():
    top = K.haze_top()
    assert K.JOIST_BOTTOM > top, f"joists at {K.JOIST_BOTTOM} cut into the haze ({top})"
    os.makedirs(OUT, exist_ok=True)
    out = {}
    for name, (make, length) in PIECES.items():
        reset()
        meshes = make()
        tris = {part: m.tris() for part, m in meshes.items()}
        fbx = export_fbx(build(name), "Floor", name)
        print("FBX", fbx, os.path.getsize(fbx), tris)
        # collision boxes in the piece's Roblox frame: X along the hall, Y up, Z across
        out[name] = dict(length=length, tris=tris, colliders={
            "Floor": ((0.0, -0.5, 0.0), (length, 1.0, K.HALL)),
            "Ceiling": ((0.0, K.DECK + 0.5, 0.0), (length, 1.0, K.SPAN)),
        })
    walls = {}
    top = K.DECK + K.RIB_DEPTH + K.DECK_COVER
    for name, (make, width) in WALLS.items():
        reset()
        meshes = make()
        # CorridorKit.frame finds the hall's side this way: the Facade flat on the face's plane,
        # the Panel's middle behind it
        assert all(abs(v.y) < 1e-6 for v in meshes["Facade"].verts), f"{name}: the facade isn't flat"
        ys = [v.y for v in meshes["Panel"].verts]
        assert (min(ys) + max(ys)) / 2 > 0.05, f"{name}: the panel's middle isn't behind the face"
        tris = {part: m.tris() for part, m in meshes.items()}
        fbx = export_fbx(build(name), "Facade", name)
        print("FBX", fbx, os.path.getsize(fbx), tris)
        # one box behind the face, floor to the deck's top: X along the wall, Y up, Z behind it
        walls[name] = dict(width=width, tris=tris, colliders={
            "Wall": ((0.0, top / 2, 0.5), (width, top, 1.0)),
        })
    junctions = {}
    for name, (make, size) in JUNCTIONS.items():
        reset()
        meshes = make()
        tris = {part: m.tris() for part, m in meshes.items()}
        fbx = export_fbx(build(name), "Floor", name)
        print("FBX", fbx, os.path.getsize(fbx), tris)
        rb = K.blender_to_roblox
        walls_at, _ = K.junction_walls(name)
        arm_dirs = {"+x": (1, 0), "-x": (-1, 0), "+y": (0, 1), "-y": (0, -1)}
        junctions[name] = dict(
            size=size, tris=tris,
            arms=[rb(*arm_dirs[a], 0.0) for a in K.JUNCTIONS[name]],
            walls=[(w, rb(x, y, 0.0), rb(dx, dy, 0.0)) for w, (x, y), (dx, dy) in walls_at],
            # one box each under the whole square and over it, like a straight's
            colliders={"Floor": ((0.0, -0.5, 0.0), (size, 1.0, size)),
                       "Ceiling": ((0.0, K.DECK + 0.5, 0.0), (size, 1.0, size))})
    reset()
    fixture_tris = {part: m.tris() for part, m in pieces.fixture().items()}
    fbx = export_fbx(build_fixture(), "Diffuser", "Fixture")
    print("FBX", fbx, os.path.getsize(fbx), fixture_tris)
    lua = os.path.join(K.ROOT, "src", "shared", "CorridorKit", "Specs.luau")
    os.makedirs(os.path.dirname(lua), exist_ok=True)
    K.write_luau(lua, out, walls, junctions, fixture_tris)
    print("SPEC", lua)


# --- look sheets: two straight pieces with stand-ins for the unit rows, under one hall light ----

def stand_ins(coll, length, units_to):
    """Render dressing only: plain boxes where the unit rows stand, up to x = `units_to`, so the
    ceiling reads in place."""
    import render
    facade = render.simple("facade", (0.55, 0.53, 0.5), 0.7)
    door = render.simple("door", (0.12, 0.2, 0.21), 0.5, 0.6)
    wire = render.simple("wire", (0.3, 0.31, 0.32), 0.5, 0.8)
    L2, W2 = length / 2, K.HALL / 2
    for side in (-1, 1):
        y0, y1 = sorted((side * W2, side * (W2 + 0.25)))
        render.box_obj("facade", (-L2, y0, 0.0), (units_to, y1, 10.0), facade, coll)
        for x in range(int(-L2) + 6, int(units_to), 12):
            d0, d1 = sorted((side * (W2 - 0.02), side * W2))
            render.box_obj("door", (x - 4, d0, 0.0), (x + 4, d1, 8.0), door, coll)
        w0, w1 = sorted((side * W2, side * (W2 + K.UNIT_DEPTH)))
        render.box_obj("wiretop", (-L2, w0, 9.95), (units_to, w1, 10.0), wire, coll)


def wall_frame(x, y, hall):
    """A wall's frame at (x, y) on the floor, its face looking along `hall` (+-x or +-y)."""
    turn = {(0, 1): 180.0, (0, -1): 0.0, (1, 0): 90.0, (-1, 0): -90.0}[tuple(round(v) for v in hall)]
    return Matrix.Translation((x, y, 0.0)) @ Matrix.Rotation(math.radians(turn), 4, "Z")


def place(name, coll, matrix):
    """A piece, junction or wall's parts at `matrix` (render dressing; walls wear the units' paint)."""
    return build(name, coll=coll, for_export=False, matrix=matrix)


def junction_at(name, coll, x, y, turn):
    """A junction at (x, y) turned `turn` degrees, with the walls the spec stands round it."""
    at = Matrix.Translation((x, y, 0.0)) @ Matrix.Rotation(math.radians(turn), 4, "Z")
    place(name, coll, at)
    for wall, (wx, wy), (dx, dy) in K.junction_walls(name)[0]:
        p = at @ Vector((wx, wy, 0.0))
        d = at.to_3x3() @ Vector((dx, dy, 0.0))
        place(wall, coll, wall_frame(p.x, p.y, (d.x, d.y)))


def side_walls(coll, x, y, along_x, length):
    """Plain walls down both sides of a straight at (x, y), the hall along x or y."""
    for side in (-1, 1):
        for k in range(int(length // K.PLAIN)):
            a = -length / 2 + K.PLAIN * (k + 0.5)
            if along_x:
                place("Wall", coll, wall_frame(x + a, y + side * K.HALL / 2, (0, -side)))
            else:
                place("Wall", coll, wall_frame(x + side * K.HALL / 2, y + a, (-side, 0)))


def hall_light(coll, x, y=0.0, turn=0.0):
    """A lit fixture at (x, y), turned `turn` degrees, its eye seeing someone, with the light it
    throws (render stand-ins for HallLight's tube light and fill)."""
    import render
    lens = render.emissive("lens_lit", (0.9, 0.95, 0.93), 6.0)
    eye = render.emissive("eye_seen", (1.0, 0.07, 0.04), 6.0)
    at = Matrix.Translation((x, y, 0.0)) @ Matrix.Rotation(math.radians(turn), 4, "Z")
    for ob in build_fixture(0.0, coll, for_export=False, lens=lens, eye=eye).values():
        ob.matrix_world = at @ ob.matrix_world
    ld = bpy.data.lights.new("hall", "AREA")
    ld.shape = "RECTANGLE"
    ld.size, ld.size_y = 3.8, 0.44
    ld.energy = 720.0
    ld.spread = math.radians(105)
    ld.color = (0.86, 0.95, 0.93)
    lo = bpy.data.objects.new("hall", ld)
    lo.location = (x, y, K.LENS_Z - K.LENS_THICK / 2 - 0.01)
    lo.rotation_euler.z = math.radians(turn)
    coll.objects.link(lo)
    fill = bpy.data.lights.new("fill", "POINT")
    fill.energy = 260.0
    fill.color = (0.86, 0.95, 0.93)
    fill.shadow_soft_size = 1.0
    fill.use_shadow = False  # as the game's fill: it lights the chains above the housing too
    fo = bpy.data.objects.new("fill", fill)
    fo.location = (x, y, 5.0)
    coll.objects.link(fo)


def stage_renders():
    import render
    reset()
    coll = bpy.context.scene.collection
    for at in (-K.STRAIGHT / 2, K.STRAIGHT / 2):
        build("Straight", at, coll, for_export=False)
    # units up to the last slot each side, which is a plain wall; the hall ends in the dead end
    end = K.STRAIGHT
    stand_ins(coll, 2 * K.STRAIGHT, end - K.PLAIN)
    for side in (-1, 1):
        build("Wall", coll=coll, for_export=False,
              matrix=wall_frame(end - K.PLAIN / 2, side * K.HALL / 2, (0, -side)))
    build("DeadEnd", coll=coll, for_export=False, matrix=wall_frame(end, 0.0, (-1, 0)))
    hall_light(coll, 6.0)
    # a dark fixture by the spawn end, its eye open: the building watching the stretch you're in
    dead = render.simple("lens_dead", PLAIN["Diffuser"], 0.5)
    watching = render.emissive("eye_watching", (1.0, 0.07, 0.04), 1.6)
    build_fixture(-18.0, coll, for_export=False, lens=dead, eye=watching)
    render.setup(96, (1280, 720), exposure=0.4)
    os.makedirs(SHEETS, exist_ok=True)
    views = {
        "hall": ((-21.0, 0.6, 4.4), (12.0, 0.0, 6.2), 22, False),     # a player's eyes down the hall
        "ceiling": ((-3.0, 1.0, 4.4), (8.0, -2.0, 13.4), 18, False),  # looking up under the light
        "seam": ((0.0, 0.0, 6.0), (0.0, 0.0, 0.0), 30, False),        # straight down on a joint
        "fixture": ((-8.0, 1.6, 4.6), (-17.2, 0.0, 12.9), 42, True),  # a torch up at a dark one
        "fixture-lit": ((-3.0, -1.6, 4.6), (6.3, 0.0, 12.9), 42, False),  # walking up to the lit one
        "deadend": ((4.0, -1.2, 4.4), (24.0, 0.8, 6.4), 24, False),   # the hall that stops
        "wall": ((9.0, -3.4, 4.4), (17.0, 4.0, 8.6), 22, False),      # across at a plain wall
    }
    for name, (loc, target, lens, torch) in views.items():
        cam = render.camera(loc, target, lens, name)
        render.flashlight(cam, torch, target)
        render.shoot(cam, os.path.join(SHEETS, f"corridor-{name}.png"))
    stage_turn_renders()


def stage_turn_renders():
    """The junctions' sheets: a hall that meets a T, its arms turned along y (a turned straight and
    a turned T), and the corner beyond one arm."""
    import render
    reset()
    coll = bpy.context.scene.collection
    turned = Matrix.Rotation(math.radians(90), 4, "Z")
    build("Straight", 0.0, coll, for_export=False)
    side_walls(coll, 0.0, 0.0, True, K.STRAIGHT)
    junction_at("T", coll, K.STRAIGHT, 0.0, 90.0)   # its stub towards the hall at x = 0
    for y in (-K.STRAIGHT, K.STRAIGHT):
        place("Straight", coll, Matrix.Translation((K.STRAIGHT, y, 0.0)) @ turned)
        side_walls(coll, K.STRAIGHT, y, False, K.STRAIGHT)
    place("DeadEnd", coll, wall_frame(K.STRAIGHT, -1.5 * K.STRAIGHT, (0, 1)))
    # the corner at the arm's end, turning back towards -x
    junction_at("Corner", coll, K.STRAIGHT, 2 * K.STRAIGHT, 90.0)
    for ob in build("Straight", 0.0, coll, for_export=False).values():
        ob.location.y = 2 * K.STRAIGHT
    side_walls(coll, 0.0, 2 * K.STRAIGHT, True, K.STRAIGHT)
    place("DeadEnd", coll, wall_frame(-K.STRAIGHT / 2, 2 * K.STRAIGHT, (1, 0)))
    hall_light(coll, 0.0)
    hall_light(coll, K.STRAIGHT, K.STRAIGHT, 90.0)  # up the arm, short of the corner
    render.setup(96, (1280, 720), exposure=0.4)
    views = {
        "turn": ((-10.0, 0.7, 4.4), (30.0, -1.0, 6.4), 22, False),     # down the hall to the T
        "girder": ((5.0, -1.6, 4.4), (13.0, 1.5, 13.6), 24, False),    # up at the stub's girder
        "corner": ((26.0, 16.0, 4.4), (22.5, 46.0, 6.6), 24, False),   # up the arm to the corner
    }
    for name, (loc, target, lens, torch) in views.items():
        cam = render.camera(loc, target, lens, name)
        render.flashlight(cam, torch, target)
        render.shoot(cam, os.path.join(SHEETS, f"corridor-{name}.png"))


def args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    p = argparse.ArgumentParser()
    p.add_argument("--stage", default="export")
    return p.parse_args(argv)


if __name__ == "__main__":
    a = args()
    {"export": stage_export, "renders": stage_renders}[a.stage]()
    print("DONE", a.stage)
