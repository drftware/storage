"""Shape builders for finds: every face tagged with what it is (an int `kind` the look reads) and
unwrapped as it's built, in studs, the way a prop artist would cut it.

A Shape is a bmesh in the find's Blender frame (X across, Y away, Z up, studs). Each builder
takes a placing matrix `M` and a `kind`; lathes and tubes take their round count from the
caller, so one function draws the detailed (high) and the game (low) version of a part.

The UVs: a lathe unrolls into strips (its sides) and discs (its flat rings, seen from above),
split where the kind changes; a tube is one strip plus its two caps; a box is projected face
by face onto its six sides. Every island starts at true size, so packing them keeps one texel
density across the find. Islands are laid far apart here; the kit packs them.
"""

import math

import bmesh
import bpy
from mathutils import Matrix, Vector

GAP = 40.0  # studs between islands before packing


class Shape:
    def __init__(self):
        self.bm = bmesh.new()
        self.kl = self.bm.faces.layers.int.new("kind")
        self.uvl = self.bm.loops.layers.uv.new("UVMap")
        self.isl = 0

    def island(self):
        self.isl += 1
        return Vector((self.isl * GAP, 0.0))

    def _v(self, co, M):
        return self.bm.verts.new(M @ Vector(co))

    def _f(self, vs, kind, uvs=None):
        f = self.bm.faces.new(vs)
        f[self.kl] = kind
        if uvs is not None:
            for loop, uv in zip(f.loops, uvs):
                loop[self.uvl].uv = uv
        return f

    # --- solids of revolution --------------------------------------------------------------
    def lathe(self, profile, kind, segs, M=Matrix(), kinds=None, split=2):
        """Spin a profile [(r, z)] about Z. List it bottom to top on the outside (then back down
        the inside for a shell) and the faces point outward. A point with r = 0 is a pole.
        `kinds` (one per profile span) overrides `kind` span by span. Steep spans unroll into
        strips cut into `split` pieces round; flat spans (and poles) project from above."""
        rings = []
        for r, z in profile:
            if r <= 1e-6:
                rings.append([self._v((0.0, 0.0, z), M)])
            else:
                rings.append([self._v((r * math.cos(2 * math.pi * j / segs),
                                       r * math.sin(2 * math.pi * j / segs), z), M)
                              for j in range(segs)])
        spans = len(profile) - 1
        kk = [kinds[i] if kinds else kind for i in range(spans)]

        def flat(i):
            (r0, z0), (r1, z1) = profile[i], profile[i + 1]
            return abs(z1 - z0) < 0.6 * abs(r1 - r0)

        # islands: runs of spans with the same kind and the same way of unrolling; a flat run
        # also breaks where it turns back on itself
        groups, cur = [], [0]
        for i in range(1, spans):
            prev = cur[-1]
            same = kk[i] == kk[prev] and flat(i) == flat(prev)
            if same and flat(i):
                d0 = profile[prev + 1][0] - profile[prev][0]
                d1 = profile[i + 1][0] - profile[i][0]
                same = d0 * d1 > 0
            if same:
                cur.append(i)
            else:
                groups.append(cur)
                cur = [i]
        groups.append(cur)
        for g in groups:
            if flat(g[0]):
                o = self.island()
                for i in g:
                    self._lathe_span(rings, profile, i, segs, kk[i], range(segs),
                                     lambda r, a, v: o + Vector((r * math.cos(a), r * math.sin(a))))
            else:
                # v is the profile's length along the run; u the arc round at that radius,
                # measured from the middle of each piece so the shear stays small
                v_at, acc = {}, 0.0
                v_at[g[0]] = 0.0
                for i in g:
                    (r0, z0), (r1, z1) = profile[i], profile[i + 1]
                    acc += math.hypot(r1 - r0, z1 - z0)
                    v_at[i + 1] = acc
                n = max(1, split)
                for piece in range(n):
                    o = self.island()
                    js = range(piece * segs // n, (piece + 1) * segs // n)
                    mid = 2 * math.pi * (piece + 0.5) / n
                    for i in g:
                        self._lathe_span(rings, profile, i, segs, kk[i], js,
                                         lambda r, a, v, mid=mid, o=o: o + Vector(((a - mid) * r, v)),
                                         v_at)
        return rings

    def _lathe_span(self, rings, profile, i, segs, k, js, uv_of, v_at=None):
        A, B = rings[i], rings[i + 1]
        if len(A) == 1 and len(B) == 1:
            return
        ra, rb = profile[i][0], profile[i + 1][0]
        va = v_at[i] if v_at else 0.0
        vb = v_at[i + 1] if v_at else 0.0
        for j in js:
            j1 = (j + 1) % segs
            a0, a1 = 2 * math.pi * j / segs, 2 * math.pi * (j + 1) / segs
            am = (a0 + a1) / 2
            if len(A) == 1:
                self._f([A[0], B[j1], B[j]], k, [uv_of(ra, am, va), uv_of(rb, a1, vb), uv_of(rb, a0, vb)])
            elif len(B) == 1:
                self._f([A[j], A[j1], B[0]], k, [uv_of(ra, a0, va), uv_of(ra, a1, va), uv_of(rb, am, vb)])
            else:
                self._f([A[j], A[j1], B[j1], B[j]], k,
                        [uv_of(ra, a0, va), uv_of(ra, a1, va), uv_of(rb, a1, vb), uv_of(rb, a0, vb)])

    # --- lofts: a shell through rings of any shape ----------------------------------------------
    def loft(self, rings, kind, M=Matrix(), kinds=None, split=2, cap_bottom=None):
        """A surface through rings [[(x, y, z)]], bottom to top, every ring the same count and
        running anticlockwise seen from above (so faces point out); a ring of one point is a
        pole. `kinds(j)` gives column j its kind (the span from point j to j + 1). Unrolls like
        a lathe's side: v up the rings, u the arc round each ring from its piece's middle, cut
        into `split` pieces round. `cap_bottom` closes the first ring with a fan of that kind,
        seen from below."""
        V = [[self._v(p, M) for p in ring] for ring in rings]
        n = max(len(r) for r in rings)
        P = [[Vector(p) for p in ring] for ring in rings]
        # v: the mean distance between rings; arc: each ring's running length round
        v_at = [0.0]
        for a, b in zip(P, P[1:]):
            if len(a) == len(b):
                d = sum((p - q).length for p, q in zip(a, b)) / len(a)
            else:
                c = a if len(a) > 1 else b
                pole = (b if len(a) > 1 else a)[0]
                d = sum((p - pole).length for p in c) / len(c)
            v_at.append(v_at[-1] + d)
        arcs = []
        for ring in P:
            acc = [0.0]
            for j in range(len(ring)):
                acc.append(acc[-1] + (ring[(j + 1) % len(ring)] - ring[j]).length)
            arcs.append(acc)
        pieces = max(1, split)
        for piece in range(pieces):
            o = self.island()
            j0, j1 = piece * n // pieces, (piece + 1) * n // pieces
            mid = (j0 + j1) // 2

            def uv(i, j):
                if len(P[i]) == 1:
                    return o + Vector((0.0, v_at[i]))
                return o + Vector((arcs[i][j] - arcs[i][mid], v_at[i]))

            for i in range(len(V) - 1):
                A, B = V[i], V[i + 1]
                for j in range(j0, j1):
                    k = kinds(j) if kinds else kind
                    jn = j + 1
                    if len(A) == 1:
                        self._f([A[0], B[jn % n], B[j]], k, [uv(i, 0), uv(i + 1, jn), uv(i + 1, j)])
                    elif len(B) == 1:
                        self._f([A[j], A[jn % n], B[0]], k, [uv(i, j), uv(i, jn), uv(i + 1, 0)])
                    else:
                        self._f([A[j], A[jn % n], B[jn % n], B[j]], k,
                                [uv(i, j), uv(i, jn), uv(i + 1, jn), uv(i + 1, j)])
        if cap_bottom is not None:
            o = self.island()
            ring = P[0]
            c = sum(ring, Vector()) / len(ring)
            cv = self._v(c, M)
            for j in range(n):
                a, b = ring[j], ring[(j + 1) % n]
                self._f([V[0][(j + 1) % n], V[0][j], cv], cap_bottom,
                        [o + b.xy - c.xy, o + a.xy - c.xy, o])
        return V

    # --- swept tubes --------------------------------------------------------------------------
    def tube(self, pts, r, kind, sides=10, M=Matrix(), caps=True, cap_kind=None, radii=None):
        """A round tube along a polyline (rotation-minimising frames), capped flat at both ends:
        one strip island along it, a disc for each cap."""
        P = [M @ Vector(p) for p in pts]
        T = []
        for i in range(len(P)):
            a = P[max(i - 1, 0)]
            b = P[min(i + 1, len(P) - 1)]
            T.append((b - a).normalized())
        up = Vector((0, 0, 1)) if abs(T[0].z) < 0.9 else Vector((1, 0, 0))
        U = [T[0].cross(up).normalized()]
        for i in range(1, len(P)):
            u = U[-1] - T[i] * U[-1].dot(T[i])
            U.append(u.normalized())
        rings, along = [], [0.0]
        for i in range(1, len(P)):
            along.append(along[-1] + (P[i] - P[i - 1]).length)
        for i, p in enumerate(P):
            rr = radii[i] if radii else r
            w = T[i].cross(U[i])
            rings.append([self.bm.verts.new(p + (U[i] * math.cos(2 * math.pi * j / sides)
                                                 + w * math.sin(2 * math.pi * j / sides)) * rr)
                          for j in range(sides)])
        o = self.island()
        circ = 2 * math.pi * r / sides
        for i, (A, B) in enumerate(zip(rings, rings[1:])):
            for j in range(sides):
                j1 = (j + 1) % sides
                u0, u1 = j * circ, (j + 1) * circ
                self._f([A[j], A[j1], B[j1], B[j]], kind,
                        [o + Vector((u0, along[i])), o + Vector((u1, along[i])),
                         o + Vector((u1, along[i + 1])), o + Vector((u0, along[i + 1]))])
        if caps:
            ck = kind if cap_kind is None else cap_kind
            for ring, rev in ((rings[0], True), (rings[-1], False)):
                o = self.island()
                rr = (ring[0].co - sum((v.co for v in ring), Vector()) / len(ring)).length
                uvs = [o + Vector((math.cos(2 * math.pi * j / sides), math.sin(2 * math.pi * j / sides))) * rr
                       for j in range(sides)]
                vs = ring[::-1] if rev else ring
                self._f(vs, ck, uvs[::-1] if rev else uvs)
        return rings

    def cylinder(self, a, b, r, kind, sides=16, caps=True, cap_kind=None, M=Matrix()):
        return self.tube([a, b], r, kind, sides, M, caps, cap_kind)

    # --- boxes --------------------------------------------------------------------------------
    def box(self, lo, hi, kind, chamfer=0.0, segs=1, M=Matrix()):
        """A box from lo to hi, its edges rounded by `chamfer` in `segs` steps."""
        tmp = bmesh.new()
        bmesh.ops.create_cube(tmp, size=1.0)
        lo, hi = Vector(lo), Vector(hi)
        S = Matrix.Diagonal((*(hi - lo), 1.0))
        bmesh.ops.transform(tmp, matrix=Matrix.Translation((lo + hi) / 2) @ S, verts=tmp.verts)
        if chamfer > 0:
            bmesh.ops.bevel(tmp, geom=list(tmp.edges), offset=chamfer, segments=segs,
                            profile=0.5, affect="EDGES", clamp_overlap=True)
        bmesh.ops.transform(tmp, matrix=M, verts=tmp.verts)
        self.merge(tmp, kind)
        tmp.free()

    def merge(self, other, kind, M=Matrix()):
        """Copy another bmesh in (all its faces one kind), projected onto its six sides: each face
        goes to the side its normal points at most, measured in the bmesh's own box."""
        vm = {}
        for v in other.verts:
            vm[v] = self.bm.verts.new(M @ v.co)
        other.normal_update()
        # the box's own axes: from the first face of each direction (create_cube is axis-aligned
        # before M, so use M's columns)
        R = M.to_3x3()
        axes = [R @ Vector(a) for a in ((1, 0, 0), (0, 1, 0), (0, 0, 1))]
        offs = {}
        for f in other.faces:
            n = f.normal
            best = max(range(3), key=lambda i: abs(n.dot(axes[i]) if M != Matrix() else n[i]))
            sign = 1 if n[best] >= 0 else -1
            key = (best, sign)
            if key not in offs:
                offs[key] = self.island()
            o = offs[key]
            a, b = [i for i in range(3) if i != best]
            uvs = [o + Vector((v.co[a], v.co[b])) for v in f.verts]
            self._f([vm[v] for v in f.verts], kind, uvs)

    # --- out ----------------------------------------------------------------------------------
    def to_object(self, name, coll, origin=(0.0, 0.0, 0.0)):
        """A mesh object whose origin is `origin` (its pivot); the mesh keeps its place."""
        bmesh.ops.remove_doubles(self.bm, verts=self.bm.verts, dist=1e-6)
        me = bpy.data.meshes.new(name)
        self.bm.to_mesh(me)
        self.bm.free()
        ob = bpy.data.objects.new(name, me)
        coll.objects.link(ob)
        me.transform(Matrix.Translation(-Vector(origin)))
        ob.location = origin
        for p in me.polygons:
            p.use_smooth = True
        me.update()
        return ob


def helix(a, b, r, turns, per_turn=16):
    """Points along a coil from a to b (a closed-coil spring's wire path), about the a-b line."""
    a, b = Vector(a), Vector(b)
    ax = (b - a)
    L = ax.length
    ax.normalize()
    u = ax.cross(Vector((0, 0, 1)) if abs(ax.z) < 0.9 else Vector((1, 0, 0))).normalized()
    w = ax.cross(u)
    n = int(turns * per_turn)
    return [a + ax * (L * i / n) + (u * math.cos(2 * math.pi * turns * i / n)
                                    + w * math.sin(2 * math.pi * turns * i / n)) * r
            for i in range(n + 1)]


def arc(c, r, a0, a1, n, plane="YZ"):
    """Points on a circular arc round c (degrees, in the given plane)."""
    out = []
    for i in range(n + 1):
        a = math.radians(a0 + (a1 - a0) * i / n)
        ca, sa = math.cos(a) * r, math.sin(a) * r
        if plane == "YZ":
            out.append((c[0], c[1] + ca, c[2] + sa))
        elif plane == "XZ":
            out.append((c[0] + ca, c[1], c[2] + sa))
        else:
            out.append((c[0] + ca, c[1] + sa, c[2]))
    return out


def fillet(r, z, rad, quarter, n):
    """Points rounding a profile corner: centre (r, z), radius rad, the quarter (start, end
    degrees) traced in n steps."""
    a0, a1 = quarter
    return [(r + rad * math.cos(math.radians(a0 + (a1 - a0) * i / n)),
             z + rad * math.sin(math.radians(a0 + (a1 - a0) * i / n))) for i in range(n + 1)]
