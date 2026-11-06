"""Mesh helpers: an accumulator with per-corner UVs, and the primitives the unit is made of.

Every primitive writes straight into a `Mesh` with the UVs its texture set wants:
    wall   U = x/4 (tiles), V = z/height       Partition, Facade
    floor  U = x/8, V = y/8                    Concrete
    strip  U = along/4 (tiles), V in a strip   TrimSheet (each strip tiles along U)
    band   U across the part 0..1, V in a band DoorKit atlas (slats, bottom bar, drum)
    atlas  left empty, smart-projected later   DoorKit atlas (small hardware)
"""

import math

import bmesh
import bpy
from mathutils import Matrix, Vector


class Mesh:
    def __init__(self, name):
        self.name = name
        self.verts = []
        self.faces = []    # tuples of vertex indices
        self.uvs = []      # per face: list of (u, v), or None for "unwrap later"
        self.smooth = []   # per face bool

    def vert(self, co):
        self.verts.append(Vector(co))
        return len(self.verts) - 1

    def face(self, idx, uv=None, smooth=False):
        self.faces.append(tuple(idx))
        self.uvs.append(uv)
        self.smooth.append(smooth)

    def tris(self):
        return sum(len(f) - 2 for f in self.faces)

    def extend(self, other, matrix=None):
        base = len(self.verts)
        for v in other.verts:
            self.verts.append(matrix @ v if matrix else v.copy())
        for f, uv, sm in zip(other.faces, other.uvs, other.smooth):
            self.faces.append(tuple(i + base for i in f))
            self.uvs.append(uv)
            self.smooth.append(sm)

    def build(self, collection=None, sharp_angle=35.0):
        me = bpy.data.meshes.new(self.name)
        me.from_pydata([tuple(v) for v in self.verts], [], self.faces)
        me.update()
        uvl = me.uv_layers.new(name="UVMap")
        li = 0
        for poly, uv in zip(me.polygons, self.uvs):
            for k, loop in enumerate(poly.loop_indices):
                uvl.data[loop].uv = uv[k] if uv else (0.0, 0.0)
        for poly, sm in zip(me.polygons, self.smooth):
            poly.use_smooth = sm
        if sharp_angle is not None:
            me.set_sharp_from_angle(angle=math.radians(sharp_angle))
        flag = me.attributes.new("unwrap", "INT", "FACE")
        flag.data.foreach_set("value", [1 if u is None else 0 for u in self.uvs])
        me.validate()
        ob = bpy.data.objects.new(self.name, me)
        (collection or bpy.context.scene.collection).objects.link(ob)
        ob["needs_unwrap"] = any(u is None for u in self.uvs)
        return ob


# --- UV mappers: (verts of a face, face normal) -> list of uv ---------------------------

def map_wall(height, tile=4.0, u_off=0.0):
    """Walls facing X use y for U; facing Y use x; flat tops land in the top band (V > 0.985)."""
    def f(vs, n):
        ax = max(range(3), key=lambda i: abs(n[i]))
        if ax == 2:
            a = 0 if _span(vs, 0) >= _span(vs, 1) else 1
            b = 1 - a
            lo = min(v[b] for v in vs)
            hi = max(v[b] for v in vs)
            w = max(hi - lo, 1e-6)
            return [((v[a] + u_off) / tile, 0.986 + 0.012 * (v[b] - lo) / w) for v in vs]
        k = 1 if ax == 0 else 0
        return [((v[k] + u_off) / tile, v.z / height) for v in vs]
    return f


def map_floor(tile=8.0):
    return lambda vs, n: [(v.x / tile, v.y / tile) for v in vs]


# TrimSheet strips (each tiles along U; 1 U = 4 studs; strip height 0.5 studs)
STRIPS = {
    "trim": 0,        # painted graphite steel, worn edges
    "diamond": 1,     # diamond plate
    "channel": 2,     # galvanized channel / angle
    "pipe": 3,        # galvanized pipe, smoother
    "raw": 4,         # dark raw steel, oily
    "wire": 5,        # galvanized wire, rougher
    "scuffed": 6,     # painted trim, heavily scuffed (jamb returns: hand trucks)
    "rubber": 7,      # black rubber
}
STRIP_H = 1.0 / 8.0
STRIP_STUDS = 0.5  # studs of "across" per strip height


def strip_rect(name):
    i = STRIPS[name]
    v1 = 1.0 - i * STRIP_H
    return v1 - STRIP_H, v1


def map_strip(name, along_axis=None, tile=4.0):
    """U = position along the part's long axis / tile; V = across, within the strip.

    Across is measured in the face's own plane, so a wide face compresses into the strip and a
    narrow one keeps its scale (most trim faces are under half a stud across).
    """
    v0, v1 = strip_rect(name)

    def f(vs, n):
        a = along_axis if along_axis is not None else max(range(3), key=lambda i: _span(vs, i))
        if abs(n[a]) > 0.7:  # end cap: tiny patch at the strip's start
            return [(0.0 + 0.02 * _frac(v[(a + 1) % 3] * 7), v0 + 0.02) for v in vs]
        # across axis: the in-plane direction perpendicular to `a`
        axis = Vector((0, 0, 0))
        axis[a] = 1.0
        across = n.cross(axis)
        if across.length < 1e-6:
            across = Vector((1, 0, 0)) if a != 0 else Vector((0, 1, 0))
        across.normalize()
        cs = [v.dot(across) for v in vs]
        lo = min(cs)
        out = []
        for v, c in zip(vs, cs):
            t = (c - lo) / STRIP_STUDS
            t = min(t, 1.0) if (max(cs) - lo) <= STRIP_STUDS else (c - lo) / (max(cs) - lo)
            out.append((v[a] / tile, v0 + 0.03 * STRIP_H + t * 0.94 * STRIP_H))
        return out
    return f


def map_band(u0, u1, v0, v1, x0, x1, s_of):
    """Atlas band: U across [x0, x1] maps to [u0, u1]; V from s_of(vertex) in [0, 1]."""
    def f(vs, n):
        return [(u0 + (v.x - x0) / (x1 - x0) * (u1 - u0), v0 + s_of(v) * (v1 - v0)) for v in vs]
    return f


def _span(vs, i):
    c = [v[i] for v in vs]
    return max(c) - min(c)


def _frac(x):
    return x - math.floor(x)


def _normal(vs):
    n = Vector((0, 0, 0))
    for i in range(len(vs)):
        a, b = vs[i], vs[(i + 1) % len(vs)]
        n.x += (a.y - b.y) * (a.z + b.z)
        n.y += (a.z - b.z) * (a.x + b.x)
        n.z += (a.x - b.x) * (a.y + b.y)
    return n.normalized() if n.length > 1e-12 else Vector((0, 0, 1))


def add_faces(mesh, verts, faces, mapper=None, smooth=False):
    """Append polygons (lists of points) to `mesh`, UVs from `mapper` (None: unwrap later)."""
    base = len(mesh.verts)
    for v in verts:
        mesh.vert(v)
    for f in faces:
        vs = [Vector(verts[i]) for i in f]
        uv = mapper(vs, _normal(vs)) if mapper else None
        mesh.face([base + i for i in f], uv, smooth)


# --- primitives --------------------------------------------------------------------------

def from_bmesh(mesh, bm, mapper=None, smooth=False, matrix=None):
    if matrix is not None:
        bmesh.ops.transform(bm, matrix=matrix, verts=bm.verts)
    bm.normal_update()
    verts = [v.co.copy() for v in bm.verts]
    idx = {v: i for i, v in enumerate(bm.verts)}
    faces = [[idx[v] for v in f.verts] for f in bm.faces]
    flags = [smooth if callable(smooth) is False else smooth(f) for f in bm.faces]
    base = len(mesh.verts)
    for v in verts:
        mesh.vert(v)
    for f, bf, sm in zip(faces, bm.faces, flags):
        vs = [verts[i] for i in f]
        uv = mapper(vs, bf.normal.copy()) if mapper else None
        mesh.face([base + i for i in f], uv, sm)
    bm.free()


def box(mesh, lo, hi, mapper=None, bevel=0.0, segments=1, edges=None):
    """Axis-aligned box from lo to hi, optionally bevelled (all edges, or edges(e) -> bool)."""
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    size = Vector(hi) - Vector(lo)
    center = (Vector(hi) + Vector(lo)) * 0.5
    bmesh.ops.scale(bm, vec=size, verts=bm.verts)
    bmesh.ops.translate(bm, vec=center, verts=bm.verts)
    if bevel > 0:
        es = [e for e in bm.edges if (edges is None or edges(e, center, size))]
        bmesh.ops.bevel(bm, geom=es, offset=bevel, offset_type="OFFSET", segments=segments,
                        profile=0.5, affect="EDGES", clamp_overlap=True)
    from_bmesh(mesh, bm, mapper, smooth=lambda f: False)


def cylinder(mesh, axis, center, radius, length, segs=16, mapper=None, caps=True,
             smooth=True, bevel=0.0, radius2=None):
    """Cylinder along axis 'x' | 'y' | 'z', centred on `center`."""
    r2 = radius if radius2 is None else radius2
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=caps, cap_tris=False, segments=segs,
                          radius1=radius, radius2=r2, depth=length)
    if bevel > 0 and caps:
        rims = [e for e in bm.edges if all(abs(abs(v.co.z) - length / 2) < 1e-5 for v in e.verts)
                and e.calc_face_angle(0) > 0.5]
        bmesh.ops.bevel(bm, geom=rims, offset=bevel, offset_type="OFFSET", segments=1,
                        profile=0.5, affect="EDGES", clamp_overlap=True)
    rot = {"x": Matrix.Rotation(math.radians(90), 4, "Y"),
           "y": Matrix.Rotation(math.radians(-90), 4, "X"),
           "z": Matrix.Identity(4)}[axis]
    m = Matrix.Translation(Vector(center)) @ rot
    bmesh.ops.transform(bm, matrix=m, verts=bm.verts)
    bm.normal_update()

    def sm(f):
        if not smooth:
            return False
        ax = {"x": 0, "y": 1, "z": 2}[axis]
        return abs(f.normal[ax]) < 0.7
    from_bmesh(mesh, bm, mapper, smooth=sm)


def hexbolt(mesh, center, normal_axis, sign, across=0.09, height=0.035, mapper=None):
    """A hex bolt head sitting on a surface, pointing along +/- normal_axis."""
    c = Vector(center)
    off = Vector((0, 0, 0))
    off["xyz".index(normal_axis)] = sign * height * 0.5
    cylinder(mesh, normal_axis, c + off, across * 0.5, height, segs=6, mapper=mapper,
             smooth=False)
    # washer
    off2 = Vector((0, 0, 0))
    off2["xyz".index(normal_axis)] = sign * 0.006
    cylinder(mesh, normal_axis, c + off2, across * 0.68, 0.012, segs=10, mapper=mapper,
             smooth=False, caps=True)


def extrude_x(mesh, profile, x0, x1, closed=True, mapper=None, uv_band=None, caps=True,
              smooth=False, flip=False):
    """Extrude a 2D profile [(y, z), ...] along X from x0 to x1.

    uv_band = (u0, u1, v0, v1): U along X, V along the profile's arc length (a single strip).
    """
    n = len(profile)
    seg = n if closed else n - 1
    lens = [0.0]
    for i in range(seg):
        a, b = profile[i], profile[(i + 1) % n]
        lens.append(lens[-1] + math.hypot(b[0] - a[0], b[1] - a[1]))
    total = lens[-1] or 1.0
    base = len(mesh.verts)
    for y, z in profile:
        mesh.vert((x0, y, z))
    for y, z in profile:
        mesh.vert((x1, y, z))
    sm = smooth if isinstance(smooth, (list, tuple)) else [smooth] * seg
    for i in range(seg):
        j = (i + 1) % n
        q = [base + i, base + j, base + n + j, base + n + i]
        if flip:
            q = q[::-1]
        if uv_band:
            u0, u1, v0, v1 = uv_band
            va = v0 + lens[i] / total * (v1 - v0)
            vb = v0 + lens[i + 1] / total * (v1 - v0)
            uv = [(u0, va), (u0, vb), (u1, vb), (u1, va)]
            if flip:
                uv = uv[::-1]
        elif mapper:
            vs = [mesh.verts[k] for k in q]
            uv = mapper(vs, _normal(vs))
        else:
            uv = None
        mesh.face(q, uv, sm[i])
    if caps and closed:
        for side, xx in ((0, x0), (n, x1)):
            idx = [base + side + i for i in range(n)]
            if side == 0:
                idx = idx[::-1]
            if flip:
                idx = idx[::-1]
            vs = [mesh.verts[k] for k in idx]
            uv = mapper(vs, _normal(vs)) if mapper else None
            mesh.face(idx, uv, False)


def sweep(mesh, path, radius, segs=8, mapper=None, closed_path=False, caps=True):
    """A round tube along a 3D polyline (handles, shackles)."""
    pts = [Vector(p) for p in path]
    rings = []
    for i, p in enumerate(pts):
        if closed_path:
            t = (pts[(i + 1) % len(pts)] - pts[i - 1])
        else:
            t = (pts[min(i + 1, len(pts) - 1)] - pts[max(i - 1, 0)])
        t.normalize()
        up = Vector((0, 0, 1)) if abs(t.z) < 0.9 else Vector((1, 0, 0))
        a = t.cross(up).normalized()
        b = t.cross(a).normalized()
        ring = []
        for k in range(segs):
            ang = 2 * math.pi * k / segs
            ring.append(mesh.vert(p + radius * (math.cos(ang) * a + math.sin(ang) * b)))
        rings.append(ring)
    m = len(rings) if closed_path else len(rings) - 1
    for i in range(m):
        r0, r1 = rings[i], rings[(i + 1) % len(rings)]
        for k in range(segs):
            q = [r0[k], r0[(k + 1) % segs], r1[(k + 1) % segs], r1[k]]
            vs = [mesh.verts[j] for j in q]
            mesh.face(q, mapper(vs, _normal(vs)) if mapper else None, True)
    if caps and not closed_path:
        for ring, rev in ((rings[0], False), (rings[-1], True)):
            idx = ring[::-1] if not rev else ring
            vs = [mesh.verts[j] for j in idx]
            mesh.face(idx, mapper(vs, _normal(vs)) if mapper else None, False)


def ring_plate(mesh, center, axis, r_out, r_in, thick, segs=16, mapper=None):
    """A flat washer / eye: annulus extruded along `axis`."""
    c = Vector(center)
    ax = "xyz".index(axis)
    u, v = (ax + 1) % 3, (ax + 2) % 3  # u x v = axis, so the winding faces outward
    base = len(mesh.verts)
    for side in (-0.5, 0.5):
        for r in (r_out, r_in):
            for k in range(segs):
                ang = 2 * math.pi * k / segs
                p = c.copy()
                p[u] += r * math.cos(ang)
                p[v] += r * math.sin(ang)
                p[ax] += side * thick
                mesh.vert(p)

    def idx(side, ring, k):
        return base + side * 2 * segs + ring * segs + (k % segs)
    quads = []
    for k in range(segs):
        quads.append([idx(0, 0, k), idx(0, 0, k + 1), idx(1, 0, k + 1), idx(1, 0, k)])  # outer
        quads.append([idx(0, 1, k), idx(1, 1, k), idx(1, 1, k + 1), idx(0, 1, k + 1)])  # inner
        quads.append([idx(0, 0, k), idx(0, 1, k), idx(0, 1, k + 1), idx(0, 0, k + 1)])  # face -
        quads.append([idx(1, 0, k), idx(1, 0, k + 1), idx(1, 1, k + 1), idx(1, 1, k)])  # face +
    for q in quads:
        vs = [mesh.verts[j] for j in q]
        mesh.face(q, mapper(vs, _normal(vs)) if mapper else None, False)
